import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';
import '../logic/price_interpreter.dart';
import '../widgets/action_button.dart';
import '../widgets/price_card.dart';
import '../widgets/howie.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/app_provider.dart';
import '../widgets/debug_overlay_painter.dart'; // IMPORTACIÓN DEL PAINTER

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final CameraService _camera = CameraService();
  final OCRService _ocr = OCRService();
  final PriceInterpreter _priceInterpreter = PriceInterpreter();
  bool _isInitializing = false;

  // Variables para el Debug
  List<({String text, Rect rect})> _tusDeteccionesDelFrame = [];
  double _scale = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;

  bool _isProcessing = false;
  bool _isCalculatingManually = false;
  DateTime _lastProcessTime = DateTime.now();
  double? _val, _conv;
  String _txt = "";
  bool _showDebugOverlay = true; //👁️♦️

  // Controladores para el modo manual
  final TextEditingController _manualPriceController = TextEditingController();
  final FocusNode _manualFocusNode = FocusNode();
  Timer? _debounceTimer;

  final double rectWidth = 300;
  final double rectHeight = 180;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  void _initializeCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    await _camera.initialize(_onFrame);

    if (mounted) {
      setState(() {});
    }
    _isInitializing = false;
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      await _camera.dispose(); // Esperamos a que el hardware se libere
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    _ocr.dispose();
    _manualPriceController.dispose();
    _manualFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onManualAmountChanged(String value) {
    // Si el usuario borra todo, reseteamos el estado
    if (value.isEmpty) {
      _debounceTimer?.cancel();
      setState(() {
        _txt = "";
        _val = null;
        _conv = null;
      });
      return;
    }

    // Debounce de 2 segundos antes de procesar la conversión
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      final cleanedValue = value.replaceAll(',', '.');
      final val = double.tryParse(cleanedValue);

      if (val != null && val > 0) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        setState(() {
          _txt = value;
          _val = val;
          _conv = provider.convert(val);
        });
      }
    });
  }

  void _onFrame(InputImage inputImage) async {
    if (!mounted || _isProcessing || _isCalculatingManually) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds <
        OCRService.processIntervalMs)
      return;

    _isProcessing = true;
    _lastProcessTime = now;

    try {
      if (inputImage.metadata?.size == null) return;

      final text = await _ocr.processImage(inputImage);
      if (!mounted) return;

      final screenSize = MediaQuery.of(context).size;
      final imgSize = inputImage.metadata!.size;

      // Cálculo de geometría (para que los cuadros verdes calcen)
      double imgWidth = imgSize.width;
      double imgHeight = imgSize.height;
      if (screenSize.height > screenSize.width &&
          imgSize.width > imgSize.height) {
        imgWidth = imgSize.height;
        imgHeight = imgSize.width;
      }

      final double scale = max(
        screenSize.width / imgWidth,
        screenSize.height / imgHeight,
      );
      final double offsetX = ((imgWidth * scale) - screenSize.width) / 2;
      final double offsetY = ((imgHeight * scale) - screenSize.height) / 2;

      // Actualizamos estado para debug
      setState(() {
        _scale = scale;
        _offsetX = offsetX;
        _offsetY = offsetY;
        _tusDeteccionesDelFrame = [
          for (var block in text.blocks)
            for (var line in block.lines)
              (text: line.text, rect: line.boundingBox),
        ];
      });

      final roi = Rect.fromCenter(
        center: screenSize.center(Offset.zero),
        width: rectWidth,
        height: rectHeight,
      );

      final rawPrice = _priceInterpreter.processFramePipeline(
        text: text,
        roi: roi,
        screenSize: screenSize,
        imageSize: imgSize,
      );
      if (rawPrice == null) return;

      final stable = _priceInterpreter.getStablePrice(rawPrice);
      if (stable == null) return;

      final provider = Provider.of<AppProvider>(context, listen: false);

      // TODO: FORMATEAR ESTE PRECIO PARA MOSTRARLO DE LA FORMA CORRECTA: 1000000,85 -> 1.000.000,85 o 1,000,000.85
      final val = double.tryParse(stable.replaceAll(',', '.'));

      if (val != null && val > 0) {
        setState(() {
          _txt = stable;
          _val = val;
          _conv = provider.convert(val);
        });
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

    final provider = Provider.of<AppProvider>(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: const CustomAppBar(showCart: true),
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Cámara ocupando todo el espacio con su proporción correcta
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
          if (!_isCalculatingManually)
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

          // Rectángulo guía visual (solo si no estamos calculando manualmente)
          if (!_isCalculatingManually)
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

          // Botón de Debug pequeño arriba a la derecha
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 20,
            child: ActionButton(
              width: 55, // Botón cuadrado
              icon: _showDebugOverlay ? Icons.bug_report : Icons.bug_report_outlined,
              onPressed: () {
                setState(() {
                  _showDebugOverlay = !_showDebugOverlay;
                });
              },
            ),
          ),

          //👁️♦️ CAPA DE DEBUG INTEGRADA (Agregado IgnorePointer para que el botón sea cliqueable)
          if (_showDebugOverlay)
            IgnorePointer(
              child: Positioned.fill(
                child: CustomPaint(
                  painter: DebugOverlayPainter(
                    _tusDeteccionesDelFrame,
                    scale: _scale,
                    offsetX: _offsetX,
                    offsetY: _offsetY,
                  ),
                ),
              ),
            ),

          // 🧮 Botón de Calculadora
          Positioned(
            top: MediaQuery.of(context).padding.top + 140,
            right: 20,
            child: ActionButton(
              width: 55, // Botón cuadrado
              icon: _isCalculatingManually ? Icons.calculate : Icons.calculate_outlined,
              onPressed: () {
                setState(() {
                  _isCalculatingManually = !_isCalculatingManually;
                  if (_isCalculatingManually) {
                    // Limpiamos estados previos para entrar en modo manual puro
                    _val = null;
                    _conv = null;
                    _txt = "";
                    _tusDeteccionesDelFrame = [];
                    _manualPriceController.clear();
                    _manualFocusNode.requestFocus();
                  } else {
                    _manualFocusNode.unfocus();
                  }
                });
              },
            ),
          ),

          // Campo de texto para ingreso manual (centrado en el ROI)
          if (_isCalculatingManually)
            Center(
              child: Container(
                width: rectWidth,
                height: rectHeight,
                alignment: Alignment.center,
                child: TextField(
                  controller: _manualPriceController,
                  focusNode: _manualFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: "0.00",
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  onChanged: _onManualAmountChanged,
                ),
              ),
            ),

          // Animación de Howie reaccionando al precio
          Positioned(
            bottom: (_val != null ? 190 : 40) + keyboardHeight,
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
              bottom: 40 + keyboardHeight,
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
