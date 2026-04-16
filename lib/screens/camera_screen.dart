import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/action_button.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/howie.dart';
import '../widgets/currency_icon.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessing = false;

  // Variables de estabilidad
  String _stableText = "";
  double? _stableValue;
  double? _convertedValue;

  // Buffer para votación (almacena las últimas detecciones)
  final List<String> _detectionHistory = [];
  final int _historyLimit = 5; // Guardamos los últimos 5 frames
  final int _consensusThreshold = 3; // Requerimos que se repita 3 veces

  final double rectWidth = 300;
  final double rectHeight = 180;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      try { await _controller!.setFocusMode(FocusMode.auto); } catch (_) {}
      setState(() { _isCameraInitialized = true; });
      _controller!.startImageStream(_processImage);
    } catch (e) {
      debugPrint("Error cámara: $e");
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      if (!mounted) return;
      final screenSize = MediaQuery.of(context).size;

      final double imageWidth = image.height.toDouble();
      final double imageHeight = image.width.toDouble();
      final double scaleX = imageWidth / screenSize.width;
      final double scaleY = imageHeight / screenSize.height;

      final Rect roiRect = Rect.fromLTWH(
        ((screenSize.width - rectWidth) / 2) * scaleX,
        ((screenSize.height - rectHeight) / 2) * scaleY,
        rectWidth * scaleX,
        rectHeight * scaleY,
      );

      String? frameDetection;

      // Buscamos el mejor candidato a precio dentro del área
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          if (roiRect.contains(line.boundingBox.center)) {
            // Regex para buscar números (soporta 15,90 15.90 o 1500)
            final RegExp regExp = RegExp(r'\d+([.,]\d{1,2})?');
            final match = regExp.firstMatch(line.text);
            if (match != null) {
              frameDetection = match.group(0);
              break;
            }
          }
        }
        if (frameDetection != null) break;
      }

      if (frameDetection != null) {
        _updateStableDetection(frameDetection);
      }

    } catch (e) {
      debugPrint("Error OCR: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // Lógica de Consenso para evitar saltos bruscos
  void _updateStableDetection(String text) {
    _detectionHistory.add(text);
    if (_detectionHistory.length > _historyLimit) {
      _detectionHistory.removeAt(0);
    }

    // Contamos ocurrencias en el historial
    Map<String, int> counts = {};
    for (var val in _detectionHistory) {
      counts[val] = (counts[val] ?? 0) + 1;
    }

    // Buscamos si algún valor llegó al umbral de consenso
    String? winner;
    counts.forEach((val, count) {
      if (count >= _consensusThreshold) {
        winner = val;
      }
    });

    if (winner != null && winner != _stableText && mounted) {
      final double? val = double.tryParse(winner!.replaceAll(',', '.'));
      if (val != null && val > 0) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        setState(() {
          _stableText = winner!;
          _stableValue = val;
          _convertedValue = provider.convert(val);
        });
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;
    try {
      final camera = _controller!.description;
      final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation)
          ?? InputImageRotation.rotation90deg;

      final plane = image.planes[0];
      final bytes = plane.bytes;
      final width = image.width;
      final height = image.height;
      final bytesPerRow = plane.bytesPerRow;

      final Uint8List cleanYPlane = Uint8List(width * height);
      for (int y = 0; y < height; y++) {
        cleanYPlane.setRange(y * width, (y + 1) * width, bytes.getRange(y * bytesPerRow, y * bytesPerRow + width));
      }

      final Uint8List nv21Bytes = Uint8List(width * height * 3 ~/ 2);
      nv21Bytes.setRange(0, width * height, cleanYPlane);
      nv21Bytes.fillRange(width * height, nv21Bytes.length, 128);

      return InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );
    } catch (e) { return null; }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textRecognizer.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(showCart: true),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          // Rectángulo guía
          Center(
            child: Container(
              width: rectWidth,
              height: rectHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.8), width: 3),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),

          // Fondo oscurecido
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(decoration: const BoxDecoration(color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
                Center(
                  child: Container(
                    width: rectWidth,
                    height: rectHeight,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ],
            ),
          ),

          // HOWIE
          Positioned(
            bottom: _stableValue != null ? 190 : 40,
            left: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 200,
              child: const Howie(),
            ),
          ),

          // Tarjeta de Conversión con Texto Oscuro
          if (_stableValue != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Card(
                color: colorScheme.tertiaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Parte Izquierda: Banderas y códigos (BRL -> ARS)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CurrencyIcon(
                                    currencyCode: provider.baseCurrency?.code ?? '',
                                    width: 24,
                                    height: 16,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.black45),
                                  ),
                                  CurrencyIcon(
                                    currencyCode: provider.targetCurrency?.code ?? '',
                                    width: 24,
                                    height: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${provider.baseCurrency?.code} → ${provider.targetCurrency?.code}',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Parte Derecha: Precio Original
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Precio Original',
                                style: TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                              Text(
                                '${provider.baseCurrency?.code} $_stableText',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black12, height: 25),
                      // Resultado Conversión (Verde oscuro)
                      Text(
                        '${provider.targetCurrency?.code} ${_convertedValue?.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF8C4404), // Green 900
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ActionButton(
                        icon: Icons.add_shopping_cart,
                        label: "Guardar Precio",
                        onPressed: () {
                          Provider.of<AppProvider>(context, listen: false)
                              .addToCart(_stableValue!, _convertedValue!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Guardado en el carrito'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
    );
  }
}
