class PriceClean {
  // 🔥 OPTIMIZACIÓN: Compilamos las reglas estáticas una sola vez en memoria
  static final RegExp _rxAssemble1 = RegExp(r'(\d+)\s*[.,]?\s+(\d{1,2})\b');
  static final RegExp _rxAssemble2 = RegExp(r'(\d+)\s+([.,])\s*(\d{1,2})');
  static final RegExp _rxSpaces = RegExp(r'\s+');
  static final RegExp _rxO = RegExp(r'[oO]');
  static final RegExp _rxI = RegExp(r'[iIlL]');
  static final RegExp _rxZ = RegExp(r'[zZ]');
  static final RegExp _rxS = RegExp(r'[sS]');
  static final RegExp _rxG = RegExp(r'[gGqQ]');
  static final RegExp _rxB = RegExp(r'[bB]');
  static final RegExp _rxLettersShield = RegExp(r'[\$R.,]');
  static final RegExp _rxHasLetters = RegExp(r'[a-zA-Z]');
  static final RegExp _rxCleanMath = RegExp(r'[^\d.,]');
  static final RegExp _rxFinalMatch = RegExp(r'^[1-9]\d*\.\d{1,2}$');

  static String? cleanAndExtractPrice(String rawText) {
    // 1. EL ENSAMBLADOR AGRESIVO: Sanea espacios de separadores decimales
    String preProcessed = rawText.replaceAllMapped(
      _rxAssemble1,
          (Match m) => '${m[1]}.${m[2]}',
    );

    preProcessed = preProcessed.replaceAllMapped(
      _rxAssemble2,
          (Match m) => '${m[1]}.${m[3]}',
    );

    // 2. SEPARAMOS POR PALABRAS
    List<String> words = preProcessed.split(_rxSpaces);

    for (String word in words) {
      String cleanedWord = word;

      // Diccionario de sustitución visual (usando memoria estática)
      cleanedWord = cleanedWord.replaceAll(_rxO, '0');
      cleanedWord = cleanedWord.replaceAll(_rxI, '1');
      cleanedWord = cleanedWord.replaceAll(_rxZ, '2');
      cleanedWord = cleanedWord.replaceAll(_rxS, '5');
      cleanedWord = cleanedWord.replaceAll(_rxG, '9');
      cleanedWord = cleanedWord.replaceAll(_rxB, '8');

      // 3. LA REGLA ESTRICTA (Escudo anti-letras)
      String testWord = cleanedWord.replaceAll(_rxLettersShield, '');
      bool hasLetters = _rxHasLetters.hasMatch(testWord);

      if (hasLetters) {
        continue; // RECHAZADO: Contiene caracteres alfabéticos mezclados
      }

      // 4. VALIDACIÓN DE ESTRUCTURA MATEMÁTICA IMPLACABLE
      String finalNumber = cleanedWord.replaceAll(_rxCleanMath, '');
      finalNumber = finalNumber.replaceAll(',', '.');

      // 🔥 AJUSTE QUIRÚRGICO (con RegExp estática)
      final match = _rxFinalMatch.firstMatch(finalNumber);

      if (match != null) {
        return match.group(0)!; // Retorna estrictamente la estructura "X.XX"
      }
    }

    return null; // Bloquea cualquier lectura huérfana o incompleta
  }
}