import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  /// Minimum number of identical frames required to validate a price.
  static const int requiredMatches = 2;

  /// Minimum time between frame processing in milliseconds.
  static const int processIntervalMs = 50;

  /// Whether to allow prices without decimal parts.
  static const bool allowIntegersOnly = false;

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Processes an [InputImage] and returns the recognized text.
  Future<RecognizedText> processImage(InputImage inputImage) async {
    return await _textRecognizer.processImage(inputImage);
  }

  /// Closes the recognizer and releases resources.
  void dispose() {
    _textRecognizer.close();
  }
}
