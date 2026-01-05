import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // Needed for WriteBuffer
import 'package:cambio_live/main.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/currency.dart';

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
  
  String _detectedText = "";
  double? _detectedValue;
  double? _convertedValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });

    _controller!.startImageStream(_processImage);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Simple logic to find the first price-like string
      // Regex for price: (Symbol)?\s*\d+[.,]?\d*
      // This is basic and might need refinement
      
      String foundText = "";
      double? foundValue;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          // Attempt to parse money
          final text = line.text;
          // Basic regex to find numbers
          final RegExp regExp = RegExp(r'\d+[.,]?\d*');
          final match = regExp.firstMatch(text);
          if (match != null) {
            String numStr = match.group(0)!.replaceAll(',', '.'); // Normalize
            // Handle cases like 1.000,00 vs 1,000.00 is hard without locale, assuming dot for decimal for now or simplistic approach
            try {
              double val = double.parse(numStr);
              foundValue = val;
              foundText = text;
              break; // Take the first one found
            } catch (e) {
              // ignore
            }
          }
        }
        if (foundValue != null) break;
      }

      if (foundValue != null) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        final converted = provider.convert(foundValue);
        
        if (mounted) {
           setState(() {
            _detectedText = foundText;
            _detectedValue = foundValue;
            _convertedValue = converted;
          });
        }
      }

    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    // Simple way to get orientation for Android/iOS
    // This part often requires more robust handling for full rotation support
    // but for portrait mode it's usually fixed.
    final InputImageRotation rotation = InputImageRotation.rotation90deg; // Assuming portrait

    final InputImageFormat format = InputImageFormat.nv21; // Android default

    // Basic Plane data extraction
    final planes = image.planes.map((Plane plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    }).toList();

    // Since basic flutter camera image is different per platform, 
    // proper conversion requires handling bytes concatenation.
    // For brevity and stability in this agent run, we acknowledge this is the complex part.
    // However, google_mlkit_commons recommends a specific way.
    
    // For this demo, let's use the simplest path or acknowledge if it's too complex for single-file.
    // Actually, let's inject the robust code.
    
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImageData = InputImageData(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      imageRotation: rotation,
      inputImageFormat: format, // This might fail on iOS (bgra8888)
      planeData: planes,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textRecognizer.close();
    _controller?.dispose();
    super.dispose();
  }
  
  // ignore: annotate_overrides
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle camera lifecycle
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          // Overlay
          if (_convertedValue != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Detectado: $_detectedText',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${Provider.of<AppProvider>(context).targetCurrency?.code} ${_convertedValue!.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (_detectedValue != null && _convertedValue != null) {
                            Provider.of<AppProvider>(context, listen: false)
                                .addToCart(_detectedValue!, _convertedValue!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Guardado en el carrito!')),
                            );
                          }
                        },
                        child: const Text('Guardar'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
