class PriceClean {
  // Regex patterns for assembling fragmented prices
  static final RegExp _rxAssemble1 = RegExp(r'(\d+)\s*[.,]?\s+(\d{1,2})\b');
  static final RegExp _rxAssemble2 = RegExp(r'(\d+)\s+([.,])\s*(\d{1,2})');
  static final RegExp _rxSpaces = RegExp(r'\s+');

  // OCR correction mapping
  static final Map<RegExp, String> _replacements = {
    RegExp(r'[oO]'): '0',
    RegExp(r'[iIlL]'): '1',
    RegExp(r'[zZ]'): '2',
    RegExp(r'[sS]'): '5',
    RegExp(r'[gGqQ]'): '9',
    RegExp(r'[bB]'): '8',
  };

  static final RegExp _rxLettersShield = RegExp(r'[\$R.,]');
  static final RegExp _rxHasLetters = RegExp(r'[a-zA-Z]');
  static final RegExp _rxCleanMath = RegExp(r'[^\d.,]');
  static final RegExp _rxFinalMatch = RegExp(r'^(0|[1-9]\d*)\.\d{1,2}$');

  /// Cleans raw OCR text and attempts to extract a valid price format (e.g., 123.45).
  static String? cleanAndExtractPrice(String rawText) {
    // Pre-process common fragmentation patterns
    String preProcessed = rawText
        .replaceAllMapped(_rxAssemble1, (m) => '${m[1]}.${m[2]}')
        .replaceAllMapped(_rxAssemble2, (m) => '${m[1]}.${m[3]}');

    for (String word in preProcessed.split(_rxSpaces)) {
      String cleaned = word.replaceAll(' ', '');
      if (cleaned.isEmpty) continue;

      // Apply character corrections (OCR fixes)
      _replacements.forEach((reg, replacement) {
        cleaned = cleaned.replaceAll(reg, replacement);
      });

      // Shield: Reject if it still contains letters (except currency symbols handled by shield)
      if (_rxHasLetters.hasMatch(cleaned.replaceAll(_rxLettersShield, ''))) {
        continue;
      }

      // Final sanitization to a numeric string with a dot as decimal separator
      String finalNumber = cleaned.replaceAll(_rxCleanMath, '').replaceAll(',', '.');

      if (finalNumber.contains('.')) {
        final parts = finalNumber.split('.');
        final decimalPart = parts.last;
        final integerPart = parts.sublist(0, parts.length - 1).join('');
        finalNumber = '$integerPart.$decimalPart';
      }

      // Final validation against the expected format
      final match = _rxFinalMatch.firstMatch(finalNumber);
      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }
}
