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
  // Esta regla se mantiene, pero la usaremos con cuidado en la lógica
  static final RegExp _rxThousandsSeparator = RegExp(r'[.,](?=\d{3})');
  static final RegExp _rxFinalMatch = RegExp(r'^(0|[1-9]\d*)\.\d{1,2}$');

  static String? cleanAndExtractPrice(String rawText) {
    String preProcessed = rawText
        .replaceAllMapped(_rxAssemble1, (m) => '${m[1]}.${m[2]}')
        .replaceAllMapped(_rxAssemble2, (m) => '${m[1]}.${m[3]}');

    for (String word in preProcessed.split(_rxSpaces)) {
      // 1. Limpiamos espacios internos para unir fragmentos de precio
      String cleaned = word.replaceAll(' ', '');

      // Si después de quitar espacios está vacío, lo saltamos
      if (cleaned.isEmpty) continue;

      // 2. Aplicar diccionario de caracteres
      _replacements.forEach((reg, replacement) {
        cleaned = cleaned.replaceAll(reg, replacement);
      });

      // 3. Validar escudo anti-letras
      if (_rxHasLetters.hasMatch(cleaned.replaceAll(_rxLettersShield, ''))) {
        // Opcional: print("RECHAZADO por letras: $cleaned");
        continue;
      }

      // 4. Limpieza matemática
      String finalNumber = cleaned.replaceAll(_rxCleanMath, '').replaceAll(',', '.');

      if (finalNumber.contains('.')) {
        List<String> parts = finalNumber.split('.');
        String decimalPart = parts.last;
        String integerPart = parts.sublist(0, parts.length - 1).join('');
        finalNumber = '$integerPart.$decimalPart';
      }

      // 5. Validación final y RECHAZO explícito
      final match = _rxFinalMatch.firstMatch(finalNumber);

      if (match != null) {
        return match.group(0);
      } else {
        // Aquí es donde "rechazas" el formato que no encaja
        // print("RECHAZADO por formato final: $finalNumber");
        continue;
      }
    }

    return null;
  }
}