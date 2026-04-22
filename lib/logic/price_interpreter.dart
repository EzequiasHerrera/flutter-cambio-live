import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceInterpreter {
  final List<String> _history = [];
  String _stableText = "";

  // Agregamos la lógica de consenso acá
  String? getStablePrice(String newDetection) {
    _history.add(newDetection);
    if (_history.length > 5) _history.removeAt(0);

    Map<String, int> counts = {};
    for (var val in _history) counts[val] = (counts[val] ?? 0) + 1;

    String? winner;
    counts.forEach((val, count) {
      if (count >= 3) winner = val;
    });

    if (winner != null && winner != _stableText) {
      _stableText = winner!;
      return _stableText;
    }
    return null;
  }

  String? extractPriceFromRoi({
    required RecognizedText text,
    required Rect roi,
    required Size screenSize,
    required Size imageSize,
  }) {
    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;

    for (TextBlock block in text.blocks) {
      for (TextLine line in block.lines) {
        final rect = Rect.fromLTRB(
          line.boundingBox.left * scaleX,
          line.boundingBox.top * scaleY,
          line.boundingBox.right * scaleX,
          line.boundingBox.bottom * scaleY,
        );

        if (roi.overlaps(rect)) {
          final match = RegExp(r'\d+([.,]\d{1,2})?').firstMatch(line.text);
          if (match != null) return match.group(0);
        }
      }
    }
    return null;
  }
}
