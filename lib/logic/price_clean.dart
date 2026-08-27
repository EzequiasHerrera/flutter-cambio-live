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
  static final RegExp _rxDecimalMatch = RegExp(r'^(0|[1-9]\d*)\.\d{1,2}$');
  static final RegExp _rxIntegerMatch = RegExp(r'^(0|[1-9]\d*)$');
  static final RegExp _rxOnlyDigitsSearch = RegExp(r'\d+');

  /// Cleans raw OCR text and attempts to extract a valid price format (e.g., 123.45).
  static String? cleanAndExtractPrice(
    String rawText, {
    bool ignoreDecimals = false,
    String? currencyCode,
  }) {
    // CONDICIÓN ESPECIFICA DE BRL:
    // RS at start might be a misread "R$". S becomes 5.
    // If currency is BRL and starts with RS, remove it.
    String textToProcess = rawText;
    if (currencyCode == 'BRL' && textToProcess.toUpperCase().startsWith('RS')) {
      textToProcess = textToProcess.substring(2);
    }

    // Pre-process common fragmentation patterns
    String preProcessed = textToProcess
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

      // Point: Ignore numbers of more than 5 or 6 digits without a separator in the middle.
      // This helps ignore barcodes or long IDs.
      if (!finalNumber.contains('.')) {
        if (finalNumber.length >= 5) continue;
      }

      // Final validation against the expected format
      if (finalNumber.contains('.')) {
        final parts = finalNumber.split('.');
        final decimalPart = parts.last;
        final integerPart = parts.sublist(0, parts.length - 1).join('');

        if (ignoreDecimals) {
          finalNumber = decimalPart.length <= 2 ? integerPart : integerPart + decimalPart;
        } else {
          finalNumber = '$integerPart.$decimalPart';
        }
      }

      if (ignoreDecimals) {
        if (_rxIntegerMatch.hasMatch(finalNumber)) return finalNumber;
      } else {
        final match = _rxDecimalMatch.firstMatch(finalNumber);
        if (match != null) return match.group(0);
      }
    }
    return null;
  }
}
