import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';
import '../logic/price_interpreter.dart';
import '../widgets/price_card.dart';
import '../widgets/howie.dart';
import 'package:provider/provider.dart';
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
  double? _val, _conv;
  String _txt = "";

  @override
  void initState() {
    super.initState();
    _camera.initialize(_onFrame);
  }

  @override
  void dispose() {
    _camera.dispose();
    _ocr.dispose();
    super.dispose();
  }

  void _onFrame(inputImage) async {
    final text = await _ocr.processImage(inputImage);
    final screenSize = MediaQuery.of(context).size;
    final roi = Rect.fromCenter(
      center: screenSize.center(Offset.zero),
      width: 300,
      height: 180,
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
        setState(() {
          _txt = stable;
          _val = double.tryParse(stable.replaceAll(',', '.'));
          _conv = Provider.of<AppProvider>(
            context,
            listen: false,
          ).convert(_val!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_camera.isInitialized)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_camera.controller!),
          Center(
            child: Container(
              width: 300,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyan, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ), // Un pequeño método simple o widget
          Positioned(bottom: 40, left: 20, child: const Howie()),
          if (_val != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: PriceCard(
                text: _txt,
                convertedValue: _conv!,
                currencyCode:
                    Provider.of<AppProvider>(context).targetCurrency?.code ??
                    '',
                onSave: () => Provider.of<AppProvider>(
                  context,
                  listen: false,
                ).addToCart(_val!, _conv!),
              ),
            ),
        ],
      ),
    );
  }
}
