class PriceClean {
  static final RegExp _rxAssemble1 = RegExp(r'(\d+)\s*[.,]?\s+(\d{1,2})\b');
  static final RegExp _rxAssemble2 = RegExp(r'(\d+)\s+([.,])\s*(\d{1,2})');
  static final RegExp _rxSpaces = RegExp(r'\s+');

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

  static String? cleanAndExtractPrice(String rawText, {bool ignoreDecimals = false}) {
    String preProcessed = rawText
        .replaceAllMapped(_rxAssemble1, (m) => '${m[1]}.${m[2]}')
        .replaceAllMapped(_rxAssemble2, (m) => '${m[1]}.${m[3]}');

    for (String word in preProcessed.split(_rxSpaces)) {
      String cleaned = word.replaceAll(' ', '');
      if (cleaned.isEmpty) continue;

      _replacements.forEach((reg, replacement) {
        cleaned = cleaned.replaceAll(reg, replacement);
      });

      if (_rxHasLetters.hasMatch(cleaned.replaceAll(_rxLettersShield, ''))) {
        continue;
      }

      String finalNumber = cleaned.replaceAll(_rxCleanMath, '').replaceAll(',', '.');

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
