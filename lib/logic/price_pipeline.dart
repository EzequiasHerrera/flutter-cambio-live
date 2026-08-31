import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:howmuch/services/feedback_service.dart';
import 'package:howmuch/services/ocr_service.dart';
import 'price_pipeline_extensions.dart';

class PricePipeline {
  static final List<String> _history = [];
  static String _stableText = "";

  static String? process({
    required RecognizedText recognizedText,
    required Rect roi,
    required Size screenSize,
    required Size imageSize,
    FeedbackService? feedback,
    bool ignoreDecimals = false,
    String? currencyCode,
  }) {
    // Pipeline funcional de transformación encadenada
    final String? candidatePrice = recognizedText
        .extractRoiElements(roi: roi, screenSize: screenSize, imageSize: imageSize, feedback: feedback)
        .groupCandidates(ignoreDecimals: ignoreDecimals)
        .selectBestCandidate(roi: roi, screenSize: screenSize,imageSize: imageSize,ignoreDecimals: ignoreDecimals, currencyCode: currencyCode, feedback: feedback);

    if (candidatePrice == null) return null;

    return _getStablePrice(candidatePrice, feedback);
  }

  static String? _getStablePrice(String newDetection, FeedbackService? feedback) {
    _history.add(newDetection);
    if (_history.length > 5) _history.removeAt(0);

    final Map<String, int> counts = {};
    for (final val in _history) {
      counts[val] = (counts[val] ?? 0) + 1;
    }

    String? winner;
    int maxCount = 0;
    counts.forEach((val, count) {
      if (count > maxCount) {
        maxCount = count;
        winner = val;
      }
    });

    if (winner != null) {
      if (_stableText.isEmpty && maxCount >= 2) {
        _stableText = winner!;
      } else if (_stableText.isNotEmpty &&
          winner != _stableText &&
          maxCount >= OCRService.requiredMatches) {
        _stableText = winner!;
      } else if (winner != _stableText) {
        feedback?.updateFeedback("Casi lo tengo... mantén la cámara fija");
      }
    }

    return _stableText.isEmpty ? null : _stableText;
  }

  static void reset() {
    _history.clear();
    _stableText = "";
  }
}