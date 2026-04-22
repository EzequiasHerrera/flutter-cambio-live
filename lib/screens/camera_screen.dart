// REEMPLAZA el archivo entero:
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

  // ✅ Guard para evitar procesar frames en paralelo
  bool _isProcessing = false;

  double? _val, _conv;
  String _txt = "";

  final double rectWidth = 300;
  final double rectHeight = 180;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camera.initialize(_onFrame).then((_) {
      if (mounted) setState(() {}); // ← le avisamos a Flutter que redibuje
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    _ocr.dispose();
    super.dispose();
  }

  void _onFrame(inputImage) async {
    // ✅ Guard restaurado
    if (_isProcessing || !mounted) return;
    _isProcessing = true;

    try {
      final text = await _ocr.processImage(inputImage);
      if (!mounted) return;

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
      _isProcessing = false;
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

    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(showCart: true),
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Cámara
          Positioned.fill(child: CameraPreview(_camera.controller!)),

          // Overlay oscuro con recorte
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

          // Rectángulo guía
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

          // Howie
          Positioned(
            bottom: _val != null ? 190 : 40,
            left: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 200,
              child: const Howie(),
            ),
          ),

          // Tarjeta de precio
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
                  Provider.of<AppProvider>(context, listen: false)
                      .addToCart(_val!, _conv!);
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