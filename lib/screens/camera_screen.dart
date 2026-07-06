import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:howmuch/logic/price_interpreter.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/services/camera_service.dart';
import 'package:howmuch/services/feedback_service.dart';
import 'package:howmuch/services/ocr_service.dart';
import 'package:howmuch/widgets/action_button.dart';
import 'package:howmuch/widgets/bubble_dialog.dart';
import 'package:howmuch/widgets/custom_app_bar.dart';
import 'package:howmuch/widgets/debug_overlay_painter.dart';
import 'package:howmuch/widgets/howie.dart';
import 'package:howmuch/widgets/price_card.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  // Services & Logic
  final CameraService _camera = CameraService();
  final OCRService _ocr = OCRService();
  final PriceInterpreter _priceInterpreter = PriceInterpreter();
  final FeedbackService _feedbackService = FeedbackService();

  // UI Controllers
  final TextEditingController _manualPriceController = TextEditingController();
  final FocusNode _manualFocusNode = FocusNode();

  // State: Camera & Processing
  bool _isInitializing = false;
  bool _isProcessing = false;
  DateTime _lastProcessTime = DateTime.now();

  // State: Detection Results
  double? _originalValue;
  double? _convertedValue;
  String _detectedText = "";

  // State: Manual Mode
  bool _isCalculatingManually = false;
  Timer? _debounceTimer;

  // State: No Decimals Mode
  bool _isIgnoringDecimals = false;

  // State: Debug Overlay
  bool _showDebugOverlay = false;
  List<({String text, Rect rect})> _frameDetections = [];
  double _scale = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;

  // Constants
  static const double _roiWidth = 300;
  static const double _roiHeight = 180;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
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

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      await _camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // --- Initialization ---

  Future<void> _initializeCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    await _camera.initialize(_onFrame);

    if (mounted) {
      setState(() {});
    }
    _isInitializing = false;
  }

  // --- Pipeline Processing ---

  void _onFrame(InputImage inputImage) async {
    if (!mounted || _isProcessing || _isCalculatingManually) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds < OCRService.processIntervalMs) return;

    _isProcessing = true;
    _lastProcessTime = now;

    try {
      if (inputImage.metadata?.size == null) return;

      final text = await _ocr.processImage(inputImage);
      if (!mounted) return;

      final screenSize = MediaQuery.of(context).size;
      final imgSize = inputImage.metadata!.size;

      // Update Geometry for Debug Overlay
      _calculateGeometry(screenSize, imgSize);

      if (_showDebugOverlay) {
        setState(() {
          _frameDetections = [
            for (var block in text.blocks)
              for (var line in block.lines) (text: line.text, rect: line.boundingBox),
          ];
        });
      }

      final roi = Rect.fromCenter(
        center: screenSize.center(Offset.zero),
        width: _roiWidth,
        height: _roiHeight,
      );

      final rawPrice = _priceInterpreter.processFramePipeline(
        text: text,
        roi: roi,
        screenSize: screenSize,
        imageSize: imgSize,
        feedback: _feedbackService,
        ignoreDecimals: _isIgnoringDecimals,
      );

      if (rawPrice == null) return;

      final stable = _priceInterpreter.getStablePrice(rawPrice, _feedbackService);
      if (stable == null) return;

      final provider = Provider.of<AppProvider>(context, listen: false);
      final value = double.tryParse(stable.replaceAll(',', '.'));

      if (value != null && value > 0) {
        setState(() {
          _detectedText = stable;
          _originalValue = value;
          _convertedValue = provider.convert(value);
        });
        _feedbackService.clear();
      }
    } catch (e) {
      debugPrint("Error in _onFrame: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _calculateGeometry(Size screenSize, Size imgSize) {
    double imgWidth = imgSize.width;
    double imgHeight = imgSize.height;

    if (screenSize.height > screenSize.width && imgSize.width > imgSize.height) {
      imgWidth = imgSize.height;
      imgHeight = imgSize.width;
    }

    _scale = max(screenSize.width / imgWidth, screenSize.height / imgHeight);
    _offsetX = ((imgWidth * _scale) - screenSize.width) / 2;
    _offsetY = ((imgHeight * _scale) - screenSize.height) / 2;
  }

  // --- Manual Input ---

  void _onManualAmountChanged(String value) {
    if (value.isEmpty) {
      _debounceTimer?.cancel();
      setState(() {
        _detectedText = "";
        _originalValue = null;
        _convertedValue = null;
      });
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;

      final cleanedValue = value.replaceAll(',', '.');
      final val = double.tryParse(cleanedValue);

      if (val != null && val > 0) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        setState(() {
          _detectedText = value;
          _originalValue = val;
          _convertedValue = provider.convert(val);
        });
      }
    });
  }

  void _toggleManualMode() {
    setState(() {
      _isCalculatingManually = !_isCalculatingManually;
      if (_isCalculatingManually) {
        _originalValue = null;
        _convertedValue = null;
        _detectedText = "";
        _frameDetections = [];
        _manualPriceController.clear();
        _manualFocusNode.requestFocus();
        _feedbackService.clear();
      } else {
        _manualFocusNode.unfocus();
      }
    });
  }

  // --- No Decimals Mode ---
  void _toggleIgnoreDecimalsMode() {
    setState(() {
      _isIgnoringDecimals = !_isIgnoringDecimals;
      _priceInterpreter.reset();
      _originalValue = null;
      _convertedValue = null;
      _detectedText = "";
      _feedbackService.clear();
    });
  }

  // --- UI Builders ---

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
          _buildCameraPreview(),
          _isCalculatingManually
              ? Container(color: Colors.black.withOpacity(0.6))
              : _buildRoiOverlay(),
          _buildActionButtons(),
          if (_showDebugOverlay) _buildDebugOverlay(),
          if (_isCalculatingManually) _buildManualInputField(),
          _buildFeedbackAndHowie(keyboardHeight),
          if (_originalValue != null) _buildPriceResult(provider, keyboardHeight),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _camera.controller!.value.previewSize?.height ?? 1080,
          height: _camera.controller!.value.previewSize?.width ?? 1920,
          child: CameraPreview(_camera.controller!),
        ),
      ),
    );
  }

  Widget _buildRoiOverlay() {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
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
                  width: _roiWidth,
                  height: _roiHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: _roiWidth,
            height: _roiHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blueAccent.withOpacity(0.8),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 70,
      right: 20,
      child: Column(
        children: [
          ActionButton(
            width: 55,
            icon: _showDebugOverlay ? Icons.bug_report : Icons.bug_report_outlined,
            onPressed: () => setState(() => _showDebugOverlay = !_showDebugOverlay),
          ),
          const SizedBox(height: 15),
          ActionButton(
            width: 55,
            icon: _isCalculatingManually ? Icons.calculate : Icons.calculate_outlined,
            onPressed: _toggleManualMode,
          ),
          const SizedBox(height: 15),
          ActionButton(
            width: 55,
            icon: _isIgnoringDecimals ? Icons.onetwothree : Icons.onetwothree_outlined,
            onPressed: _toggleIgnoreDecimalsMode,
          )
        ],
      ),
    );
  }

  Widget _buildDebugOverlay() {
    return IgnorePointer(
      child: Positioned.fill(
        child: CustomPaint(
          painter: DebugOverlayPainter(
            _frameDetections,
            scale: _scale,
            offsetX: _offsetX,
            offsetY: _offsetY,
          ),
        ),
      ),
    );
  }

  Widget _buildManualInputField() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 120,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _manualPriceController,
        builder: (context, value, child) {
          final bool isEmpty = value.text.isEmpty;
          final color = isEmpty ? Colors.white24 : Colors.white;
          final textStyle = TextStyle(
            color: color,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          );

          // Medimos el ancho total incluyendo el símbolo $ para que el bloque esté centrado
          final displayValue = isEmpty ? "0.00" : value.text;
          final fullText = "\$ $displayValue";
          final textPainter = TextPainter(
            text: TextSpan(text: fullText, style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();

          return Center(
            child: SizedBox(
              width: textPainter.width + 16, // Espacio para el cursor
              child: TextField(
                controller: _manualPriceController,
                focusNode: _manualFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.left,
                style: textStyle,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  prefixText: "\$ ",
                  prefixStyle: textStyle,
                  hintText: "0.00",
                  hintStyle: textStyle.copyWith(color: Colors.white24),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                onChanged: _onManualAmountChanged,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackAndHowie(double keyboardHeight) {
    return Positioned(
      bottom: (_originalValue != null ? 190 : 40) + keyboardHeight,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Transform.translate(
            offset: const Offset(0, 35),
            child: ListenableBuilder(
              listenable: _feedbackService,
              builder: (context, child) {
                return BubbleDialog(
                  message: _feedbackService.message ??
                      (_isCalculatingManually
                          ? "Escribe el precio que ves"
                          : "¡Hola! Apunta a un precio para empezar"),
                  direction: BubbleDirection.bottom,
                );
              },
            ),
          ),
          const SizedBox(height: 0),
          const SizedBox(height: 200, child: Howie()),
        ],
      ),
    );
  }

  Widget _buildPriceResult(AppProvider provider, double keyboardHeight) {
    return Positioned(
      bottom: 40 + keyboardHeight,
      left: 20,
      right: 20,
      child: PriceCard(
        text: _detectedText,
        convertedValue: _convertedValue!,
        currencyCode: provider.targetCurrency?.code ?? '',
        onSave: () {
          provider.addToCart(_originalValue!, _convertedValue!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guardado en el carrito'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

