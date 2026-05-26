class PriceClean {
  static String? cleanAndExtractPrice(String rawText) {
    // 1. EL ENSAMBLADOR AGRESIVO: Sanea espacios de separadores decimales
    String preProcessed = rawText.replaceAllMapped(
      RegExp(r'(\d+)\s*[.,]?\s+(\d{1,2})\b'),
          (Match m) => '${m[1]}.${m[2]}',
    );

    preProcessed = preProcessed.replaceAllMapped(
      RegExp(r'(\d+)\s+([.,])\s*(\d{1,2})'),
          (Match m) => '${m[1]}.${m[3]}',
    );

    // 2. SEPARAMOS POR PALABRAS
    List<String> words = preProcessed.split(RegExp(r'\s+'));

    for (String word in words) {
      String cleanedWord = word;

      // Diccionario de sustitución visual
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[oO]'), '0');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[iIlL]'), '1');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[zZ]'), '2');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[sS]'), '5');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[gGqQ]'), '9');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[bB]'), '8');

      // 3. LA REGLA ESTRICTA (Escudo anti-letras)
      String testWord = cleanedWord.replaceAll(RegExp(r'[\$R.,]'), '');
      bool hasLetters = RegExp(r'[a-zA-Z]').hasMatch(testWord);

      if (hasLetters) {
        continue; // RECHAZADO: Contiene caracteres alfabéticos mezclados
      }

      // 4. VALIDACIÓN DE ESTRUCTURA MATEMÁTICA IMPLACABLE
      String finalNumber = cleanedWord.replaceAll(RegExp(r'[^\d.,]'), '');
      finalNumber = finalNumber.replaceAll(',', '.');

      // 🔥 AJUSTE QUIRÚRGICO: Modificamos la Regex para exigir OBLIGATORIAMENTE centavos (\.\d{1,2})
      // Eliminamos el signo '?' del grupo decimal. Si no hay punto y centavos, se descarta el frame.
      // Además, exigimos que el número entero no empiece con ceros basura innecesarios.
      final match = RegExp(r'^[1-9]\d*\.\d{1,2}$').firstMatch(finalNumber);

      if (match != null) {
        return match.group(0)!; // Retorna estrictamente la estructura "X.XX"
      }
    }

    return null; // Bloquea cualquier lectura huérfana o incompleta
  }
}