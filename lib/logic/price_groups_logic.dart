import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceGroupsLogic {
  // Expresiones regulares para detección y limpieza
  static final RegExp _rxHasNumbers = RegExp(r'[0-9]');
  static final RegExp _rxLettersAndNoise = RegExp(r'[^0-9.,]');
  static final RegExp _rxOnlyDigits = RegExp(r'[^0-9]');
  static final RegExp rxPerfectFormat = RegExp(r'^(\d{1,3}([.,]\d{3})*)[.,]\d{2}$');

  /// Agrupa los elementos de texto individuales en candidatos de precio basados en proximidad geométrica.
  static List<List<TextElement>> groupPricesByLeader(
      List<TextElement> elementsInRoi, {
        bool ignoreDecimals = false,
      }) {
    // 1. Filtrar solo los elementos que contengan al menos un número
    final numericElements = _filterNumericElements(elementsInRoi);
    if (numericElements.isEmpty) return [];

    // 2. Aplicar estrategias de agrupación
    final candidates = _processStrategies(numericElements, ignoreDecimals: ignoreDecimals);

    // 3. Ordenar candidatos por prioridad (formato perfecto y tamaño de fuente)
    return _rankCandidates(candidates);
  }

  // --- Métodos Privados ---

  static List<TextElement> _filterNumericElements(List<TextElement> elements) {
    return elements.where((e) => _rxHasNumbers.hasMatch(e.text)).toList();
  }

  static List<List<TextElement>> _processStrategies(
      List<TextElement> numericElements, {
        bool ignoreDecimals = false,
      }) {
    final List<List<TextElement>> lot = [];

    for (final TextElement baseElement in numericElements) {
      final String originalText = baseElement.text;
      final String cleanText = originalText.replaceAll(_rxLettersAndNoise, '');

      // Caso A: El elemento ya viene con un formato perfecto de precio (ej. "12.90")
      if (_evaluatePerfectFormat(cleanText, baseElement, lot)) continue;

      // Caso B: Buscar céntimos cercanos (ej. "99" cerca de "10")
      _evaluateProximity(baseElement, numericElements, lot, ignoreDecimals: ignoreDecimals);
    }

    return lot;
  }

  static bool _evaluatePerfectFormat(
      String cleanText,
      TextElement baseElement,
      List<List<TextElement>> lot,
      ) {
    if (rxPerfectFormat.hasMatch(cleanText)) {
      lot.add([baseElement]);
      return true;
    }
    return false;
  }

  static void _evaluateProximity(
      TextElement baseElement,
      List<TextElement> numericElements,
      List<List<TextElement>> lot, {
        bool ignoreDecimals = false,
      }) {
    final double h = baseElement.boundingBox.height.toDouble();

    final List<TextElement> neighbors = numericElements.where((candidate) {
      if (candidate == baseElement) return false;
      if (ignoreDecimals) return false;

      final candDigits = candidate.text.replaceAll(_rxOnlyDigits, '');
      // El candidato a céntimo debe ser de exactamente 2 dígitos
      if (candDigits.length != 2) return false;

      // 1. Regla del tamaño relativo: Los céntimos miden entre el 30% y el 100% de la parte entera
      final double candHeight = candidate.boundingBox.height.toDouble();
      if (candHeight < (h * 0.3) || candHeight > (h * 1.0)) return false;

      // 2. Regla de posición a la Derecha (X):
      // Debe estar a la derecha pero no más lejos que 1.5 veces la altura H
      final double baseRight = baseElement.boundingBox.right.toDouble();
      final double candLeft = candidate.boundingBox.left.toDouble();

      final bool isToTheRight = candLeft >= (baseRight - (h * 0.2)) &&
          candLeft <= (baseRight + (h * 1.5));

      // 3. Regla de alineación Vertical (Y):
      // El céntimo debe alinearse con la mitad superior del número base
      final double baseTop = baseElement.boundingBox.top.toDouble();
      final double candTop = candidate.boundingBox.top.toDouble();

      final bool inVerticalRange = candTop >= (baseTop - (h * 0.2)) &&
          candTop <= (baseTop + (h * 0.6));

      return isToTheRight && inVerticalRange;
    }).toList();

    if (neighbors.isNotEmpty) {
      // Ordenamos los vecinos de izquierda a derecha por si hay varios
      neighbors.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      lot.add([baseElement, neighbors.first]);
    } else {
      lot.add([baseElement]);
    }
  }

  static List<List<TextElement>> _rankCandidates(List<List<TextElement>> candidates) {
    candidates.sort((a, b) {
      final textA = a.map((e) => e.text).join(' ').replaceAll(_rxLettersAndNoise, '');
      final textB = b.map((e) => e.text).join(' ').replaceAll(_rxLettersAndNoise, '');

      final bool isPerfectA = rxPerfectFormat.hasMatch(textA) && a.length == 1;
      final bool isPerfectB = rxPerfectFormat.hasMatch(textB) && b.length == 1;

      // Prioridad 1: Formato perfecto completo en un solo elemento
      if (isPerfectA && !isPerfectB) return -1;
      if (!isPerfectA && isPerfectB) return 1;

      // Prioridad 2: Mayor altura de fuente en el elemento principal
      return b.first.boundingBox.height.compareTo(a.first.boundingBox.height);
    });

    return candidates;
  }
}