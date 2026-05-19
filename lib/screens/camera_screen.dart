import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';
import '../logic/price_interpreter.dart';
import '../widgets/price_card.dart';
import '../widgets/howie.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/app_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final CameraService _camera = CameraService();
  final OCRService _ocr = OCRService();
  final PriceInterpreter _brain = PriceInterpreter();

  bool _isProcessing = false; // Guard para evitar procesar frames en paralelo
  DateTime _lastProcessTime =
      DateTime.now(); // Cronómetro optimizado para dar fluidez (300ms en lugar de 1500ms)
  double? _val, _conv;
  String _txt = "";

  final double rectWidth = 300; //Tamaño del ROI (Region of Interest)
  final double rectHeight = 180;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  void _initializeCamera() {
    _camera.initialize(_onFrame).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ✅ SOLUCIÓN AL CICLO DE VIDA DE LA CÁMARA
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camera.controller == null || !_camera.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    _ocr.dispose();
    super.dispose();
  }

  void _onFrame(InputImage inputImage) async {
    if (!mounted) return;

    // 1. EL GUARD DE PARALELISMO DEBE IR PRIMERO
    if (_isProcessing) return;

    // 2. EL FRENO DE MANO OPTIMIZADO (300ms para que se sienta fluido en tiempo real)
    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds < 300) {
      return;
    }

    _isProcessing = true;
    _lastProcessTime = now;

    try {
      // Validamos que la metadata de la imagen exista para evitar crashes
      if (inputImage.metadata?.size == null) return;

      final text = await _ocr.processImage(inputImage);
      if (!mounted) return;
      //-------------------- MUESTRO EL TEXTO DETALLADO -------------------
      print("=================================================");
      print("TEXTO CRUDO GENERAL:");
      print(text.text); // Esto imprime todo el string unificado
      print("-------------------------------------------------");
      print("DESGLOSE POR BLOQUES Y LÍNEAS:");

      for (TextBlock block in text.blocks) {
        print("📦 [BLOQUE NUEVO] -> Texto: ${block.text}");
        print("   Posición en pantalla (BoundingBox): ${block.boundingBox}");

        for (TextLine line in block.lines) {
          print("   -- 📝 [LÍNEA] -> ${line.text}");
          // Si querés ver las palabras sueltas de esa línea:
          // for (TextElement element in line.elements) {
          //   print("      -- 📍 [PALABRA]: ${element.text}");
          // }
        }
      }
      print("=================================================");
      //-------------------------------------------------------------------

      final screenSize = MediaQuery.of(context).size;
      final roi = Rect.fromCenter(
        center: screenSize.center(Offset.zero),
        width: rectWidth,
        height: rectHeight,
      );

      final rawPrice = _brain.extractPriceFromRoi(
        text: text,
        roi: roi,
        screenSize: screenSize,
        imageSize: inputImage.metadata!.size,
      );

      if (rawPrice != null) {
        final stable = _brain.getStablePrice(rawPrice);
        if (stable != null && mounted) {
          final provider = Provider.of<AppProvider>(context, listen: false);
          final val = double.tryParse(stable.replaceAll(',', '.'));

          if (val != null && val > 0) {
            setState(() {
              _txt = stable;
              _val = val;
              _conv = provider.convert(val);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error en _onFrame: $e");
    } finally {
      _isProcessing = false; // ✅ Se libera de forma segura siempre
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_camera.isInitialized || _camera.controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(showCart: true),
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Cámara ocupando to-do el espacio con su proporción correcta
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _camera.controller!.value.previewSize?.height ?? 1080,
                height: _camera.controller!.value.previewSize?.width ?? 1920,
                child: CameraPreview(_camera.controller!),
              ),
            ),
          ),

          // Overlay oscuro con recorte de la zona de lectura (ROI)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: rectWidth,
                    height: rectHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rectángulo guía visual
          Center(
            child: Container(
              width: rectWidth,
              height: rectHeight,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.8),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),

          // Animación de Howie reaccionando al precio
          Positioned(
            bottom: _val != null ? 190 : 40,
            left: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 200,
              child: const Howie(),
            ),
          ),

          // Tarjeta inferior con el precio convertido
          if (_val != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: PriceCard(
                text: _txt,
                convertedValue: _conv!,
                currencyCode: provider.targetCurrency?.code ?? '',
                onSave: () {
                  Provider.of<AppProvider>(
                    context,
                    listen: false,
                  ).addToCart(_val!, _conv!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Guardado en el carrito'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
