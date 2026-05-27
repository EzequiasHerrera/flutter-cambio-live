import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:math';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';
import '../logic/price_interpreter.dart';
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

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _camera = CameraService();
  final OCRService _ocr = OCRService();
  final PriceInterpreter _priceInterpreter = PriceInterpreter();

  // Variables para el Debug
  List<({String text, Rect rect})> _tusDeteccionesDelFrame = [];
  double _scale = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;

  bool _isProcessing = false;
  DateTime _lastProcessTime = DateTime.now();
  double? _val, _conv;
  String _txt = "";
  bool _showDebugOverlay = true; //👁️♦️

  final double rectWidth = 300;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camera.controller == null || !_camera.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
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
    if (!mounted || _isProcessing) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds < 300) return;

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
      if (screenSize.height > screenSize.width && imgSize.width > imgSize.height) {
        imgWidth = imgSize.height;
        imgHeight = imgSize.width;
      }

      final double scale = max(screenSize.width / imgWidth, screenSize.height / imgHeight);
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
              (text: line.text, rect: line.boundingBox)
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
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(showCart: true),
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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

          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.srcOut),
            child: Stack(children: [
              Container(decoration: const BoxDecoration(color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
              Center(child: Container(width: rectWidth, height: rectHeight, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)))),
            ]),
          ),

          Center(
            child: Container(
              width: rectWidth,
              height: rectHeight,
              decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.8), width: 3), borderRadius: BorderRadius.circular(15)),
            ),
          ),

          //👁️♦️ CAPA DE DEBUG INTEGRADA
          if(_showDebugOverlay)
          Positioned.fill(
            child: CustomPaint(
              painter: DebugOverlayPainter(
                _tusDeteccionesDelFrame,
                scale: _scale,
                offsetX: _offsetX,
                offsetY: _offsetY,
              ),
            ),
          ),

          Positioned(
            bottom: _val != null ? 190 : 40,
            left: 0,
            child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 200, child: const Howie()),
          ),

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
                  Provider.of<AppProvider>(context, listen: false).addToCart(_val!, _conv!);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en el carrito'), behavior: SnackBarBehavior.floating));
                },
              ),
            ),
        ],
      ),
    );
  }
}
