import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceGroupsLogic {
  // Regular Expressions for price detection and cleaning
  static final RegExp _rxHasNumbers = RegExp(r'[0-9]');
  static final RegExp _rxLettersAndNoise = RegExp(r'[^0-9.,]');
  static final RegExp _rxOnlyDigits = RegExp(r'[^0-9]');
  static final RegExp _rxPerfectFormat = RegExp(r'^(\d{1,3}([.,]\d{3})*)[.,]\d{2}$');

  /// Groups detected text lines into potential price candidates based on spatial proximity
  /// and common price fragmentation patterns.
  static List<List<TextLine>> groupPricesByLeader(List<TextLine> linesInRoi) {
    // 1. Filter out lines that don't contain numbers
    final numericLines = _filterNumericLines(linesInRoi);
    if (numericLines.isEmpty) return [];

    // 2. Apply grouping strategies
    final candidates = _processStrategies(numericLines);

    // 3. Rank candidates (native format and font size)
    return _rankCandidates(candidates);
  }

  // --- Private Strategies ---

  static List<List<TextLine>> _processStrategies(List<TextLine> numericLines) {
    final List<List<TextLine>> lot = [];

    for (final TextLine baseLine in numericLines) {
      final String originalText = baseLine.text;
      final String cleanText = originalText.replaceAll(_rxLettersAndNoise, '');
      final String pureDigits = originalText.replaceAll(_rxOnlyDigits, '');

      // Case A: Already in a perfect price format (e.g., "12.90")
      if (_evaluatePerfectFormat(cleanText, baseLine, lot)) continue;

      // Case B: Pure digits that look like they need splitting (e.g., "100099" -> "1000.99")
      if (_evaluateFracture(pureDigits, baseLine, lot)) continue;

      // Case C: Look for nearby cent decimals (Case "99" near "10")
      _evaluateProximity(baseLine, numericLines, lot);
    }

    return lot;
  }

  static List<TextLine> _filterNumericLines(List<TextLine> lines) {
    return lines.where((line) => _rxHasNumbers.hasMatch(line.text)).toList();
  }

  static bool _evaluatePerfectFormat(String cleanText, TextLine baseLine, List<List<TextLine>> lot) {
    if (_rxPerfectFormat.hasMatch(cleanText)) {
      lot.add([baseLine]);
      return true;
    }
    return false;
  }

  static bool _evaluateFracture(String pureDigits, TextLine baseLine, List<List<TextLine>> lot) {
    if (pureDigits.length >= 3) {
      final String cents = pureDigits.substring(pureDigits.length - 2);
      if (cents != "00") {
        final String integerPart = pureDigits.substring(0, pureDigits.length - 2);
        lot.add([
          _cloneLineWithText(baseLine, integerPart),
          _cloneLineWithText(baseLine, cents),
        ]);
        return true;
      }
    }
    return false;
  }

  static void _evaluateProximity(TextLine baseLine, List<TextLine> numericLines, List<List<TextLine>> lot) {
    final List<TextLine> neighbors = numericLines.where((candidate) {
      if (candidate == baseLine) return false;

      final candDigits = candidate.text.replaceAll(_rxOnlyDigits, '');
      if (candDigits.length != 2) return false;

      // Calculate horizontal centers
      final double baseCenterX = (baseLine.boundingBox.left + baseLine.boundingBox.right) / 2;
      final double candCenterX = (candidate.boundingBox.left + candidate.boundingBox.right) / 2;

      final bool isToTheRight = candCenterX > baseCenterX;

      // Vertical tolerance (50% of height) for tilted text
      final double margin = baseLine.boundingBox.height * 0.5;
      final bool inVerticalRange =
          candidate.boundingBox.top >= (baseLine.boundingBox.top - margin) &&
              candidate.boundingBox.bottom <= (baseLine.boundingBox.bottom + margin);

      return isToTheRight && inVerticalRange;
    }).toList();

    if (neighbors.isNotEmpty) {
      neighbors.sort((a, b) {
        final centerA = (a.boundingBox.left + a.boundingBox.right) / 2;
        final centerB = (b.boundingBox.left + b.boundingBox.right) / 2;
        return centerA.compareTo(centerB);
      });

      lot.add([baseLine, neighbors.first]);
    } else {
      lot.add([baseLine]);
    }
  }

  static TextLine _cloneLineWithText(TextLine original, String newText) {
    return TextLine(
      text: newText,
      boundingBox: original.boundingBox,
      elements: original.elements,
      cornerPoints: original.cornerPoints,
      recognizedLanguages: original.recognizedLanguages,
      confidence: original.confidence,
      angle: original.angle,
    );
  }

  static List<List<TextLine>> _rankCandidates(List<List<TextLine>> candidates) {
    candidates.sort((a, b) {
      final textA = a.map((e) => e.text).join(' ').replaceAll(_rxLettersAndNoise, '');
      final textB = b.map((e) => e.text).join(' ').replaceAll(_rxLettersAndNoise, '');

      final bool isPerfectA = _rxPerfectFormat.hasMatch(textA) && a.length == 1;
      final bool isPerfectB = _rxPerfectFormat.hasMatch(textB) && b.length == 1;

      // Priority 1: Perfect format
      if (isPerfectA && !isPerfectB) return -1;
      if (!isPerfectA && isPerfectB) return 1;

      // Priority 2: Largest font size
      return b.first.boundingBox.height.compareTo(a.first.boundingBox.height);
    });

    return candidates;
  }
}
