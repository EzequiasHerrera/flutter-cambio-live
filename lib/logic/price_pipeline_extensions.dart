import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:howmuch/services/feedback_service.dart';

// Constantes y Reglas Regex para Validación y Limpieza
final RegExp _rxAssemble1 = RegExp(r'(\d+)\s*[.,]?\s+(\d{1,2})\b');
final RegExp _rxAssemble2 = RegExp(r'(\d+)\s+([.,])\s*(\d{1,2})');
final RegExp _rxSpaces = RegExp(r'\s+');
final RegExp _rxHasLetters = RegExp(r'[a-zA-Z]');
final RegExp _rxLettersShield = RegExp(r'[\$R.,]');
final RegExp _rxCleanMath = RegExp(r'[^\d.,]');
final RegExp _rxDecimalMatch = RegExp(r'^(0|[1-9]\d*)\.\d{1,2}$');
final RegExp _rxIntegerMatch = RegExp(r'^(0|[1-9]\d*)$');
final RegExp _rxHasNumbers = RegExp(r'[0-9]');
final RegExp _rxLettersAndNoise = RegExp(r'[^0-9.,]');
final RegExp _rxOnlyDigits = RegExp(r'[^0-9]');
final RegExp _rxPerfectFormat = RegExp(r'^(\d{1,3}([.,]\d{3})*)[.,]\d{2}$');

final Map<RegExp, String> _replacements = {
  RegExp(r'[oO]'): '0',
  RegExp(r'[iIlL]'): '1',
  RegExp(r'[zZ]'): '2',
  RegExp(r'[sS]'): '5',
  RegExp(r'[gGqQ]'): '9',
  RegExp(r'[bB]'): '8',
};

// --- ESLABÓN 1: Extracción y Filtrado por ROI ---
extension ExtractRoiElementsExtension on RecognizedText {
  List<TextElement> extractRoiElements({
    required Rect roi,
    required Size screenSize,
    required Size imageSize,
    FeedbackService? feedback,
  }) {
    double imgWidth = imageSize.width;
    double imgHeight = imageSize.height;

    if (screenSize.height > screenSize.width && imageSize.width > imageSize.height) {
      imgWidth = imageSize.height;
      imgHeight = imageSize.width;
    }

    final double scale = max(
      screenSize.width / imgWidth,
      screenSize.height / imgHeight,
    );
    final double offsetX = ((imgWidth * scale) - screenSize.width) / 2;
    final double offsetY = ((imgHeight * scale) - screenSize.height) / 2;

    final List<TextElement> validElements = [];

    for (final TextBlock block in blocks) {
      for (final TextLine line in block.lines) {
        for (final TextElement element in line.elements) {
          final Rect elementInScreen = Rect.fromLTRB(
            (element.boundingBox.left * scale) - offsetX,
            (element.boundingBox.top * scale) - offsetY,
            (element.boundingBox.right * scale) - offsetX,
            (element.boundingBox.bottom * scale) - offsetY,
          );

          if (roi.contains(elementInScreen.center)) {
            if (elementInScreen.width > roi.width) continue;
            if (elementInScreen.height < roi.height * 0.08) continue;

            validElements.add(element);
          }
        }
      }
    }

    if (validElements.isEmpty) {
      feedback?.updateFeedback("Apunta directamente al precio");
    }

    return validElements;
  }
}

// --- ESLABÓN 2: Agrupación Geométrica de Candidatos ---
extension GroupCandidatesExtension on List<TextElement> {
  List<List<TextElement>> groupCandidates({
    bool ignoreDecimals = false,
  }) {
    final numericElements = where((e) => _rxHasNumbers.hasMatch(e.text)).toList();
    if (numericElements.isEmpty) return [];

    final List<List<TextElement>> lot = [];

    for (final TextElement baseElement in numericElements) {
      final String cleanText = baseElement.text.replaceAll(_rxLettersAndNoise, '');

      // Formato perfecto directo
      if (_rxPerfectFormat.hasMatch(cleanText)) {
        lot.add([baseElement]);
        continue;
      }

      // Proximidad de céntimos
      final double h = baseElement.boundingBox.height.toDouble();
      final List<TextElement> neighbors = numericElements.where((candidate) {
        if (candidate == baseElement || ignoreDecimals) return false;

        final candDigits = candidate.text.replaceAll(_rxOnlyDigits, '');
        if (candDigits.length != 2) return false;

        final double candHeight = candidate.boundingBox.height.toDouble();
        if (candHeight < (h * 0.3) || candHeight > (h * 1.0)) return false;

        final double baseRight = baseElement.boundingBox.right.toDouble();
        final double candLeft = candidate.boundingBox.left.toDouble();
        final bool isToTheRight = candLeft >= (baseRight - (h * 0.2)) &&
            candLeft <= (baseRight + (h * 1.5));

        final double baseTop = baseElement.boundingBox.top.toDouble();
        final double candTop = candidate.boundingBox.top.toDouble();
        final bool inVerticalRange = candTop >= (baseTop - (h * 0.2)) &&
            candTop <= (baseTop + (h * 0.6));

        return isToTheRight && inVerticalRange;
      }).toList();

      if (neighbors.isNotEmpty) {
        neighbors.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        lot.add([baseElement, neighbors.first]);
      } else {
        lot.add([baseElement]);
      }
    }

    // Ordenar y jerarquizar
    lot.sort((a, b) {
      final textA = a.map((e) => e.text).join(' ').replaceAll(_rxLettersAndNoise, '');
      final textB = b.map((e) => e.text).join(' ').replaceAll(_rxLettersAndNoise, '');

      final bool isPerfectA = _rxPerfectFormat.hasMatch(textA) && a.length == 1;
      final bool isPerfectB = _rxPerfectFormat.hasMatch(textB) && b.length == 1;

      if (isPerfectA && !isPerfectB) return -1;
      if (!isPerfectA && isPerfectB) return 1;

      return b.first.boundingBox.height.compareTo(a.first.boundingBox.height);
    });

    return lot;
  }
}

// --- ESLABÓN 3: Selección del Mejor Candidato y Scoring ---
extension SelectBestCandidateExtension on List<List<TextElement>> {
  String? selectBestCandidate({
    required Rect roi,
    required Size screenSize,
    required Size imageSize,
    bool ignoreDecimals = false,
    String? currencyCode,
    FeedbackService? feedback,
  }) {
    if (isEmpty) return null;

    double imgWidth = imageSize.width;
    double imgHeight = imageSize.height;

    if (screenSize.height > screenSize.width && imageSize.width > imageSize.height) {
      imgWidth = imageSize.height;
      imgHeight = imageSize.width;
    }

    final double scale = max(
      screenSize.width / imgWidth,
      screenSize.height / imgHeight,
    );
    final double offsetX = ((imgWidth * scale) - screenSize.width) / 2;
    final double offsetY = ((imgHeight * scale) - screenSize.height) / 2;

    String? bestPrice;
    double bestScore = -1.0;

    for (final List<TextElement> row in this) {
      final String combinedText = row.map((e) => e.text).join(' ');

      // Limpieza y extracción
      final String? price = _cleanAndExtractPrice(
        combinedText,
        ignoreDecimals: ignoreDecimals,
        currencyCode: currencyCode,
      );

      if (price != null) {
        double minLeft = row.map((e) => e.boundingBox.left.toDouble()).reduce(min);
        double minTop = row.map((e) => e.boundingBox.top.toDouble()).reduce(min);
        double maxRight = row.map((e) => e.boundingBox.right.toDouble()).reduce(max);
        double maxBottom = row.map((e) => e.boundingBox.bottom.toDouble()).reduce(max);

        final Offset centerInScreen = Offset(
          (((minLeft + maxRight) / 2.0) * scale) - offsetX,
          (((minTop + maxBottom) / 2.0) * scale) - offsetY,
        );

        final double distance = (centerInScreen - roi.center).distance;
        final double height = row.first.boundingBox.height * scale;

        final double centralityScore = max(0.0, 1000.0 - distance);
        final double sizeScore = height * 2.0;

        final double totalScore = centralityScore + sizeScore;

        if (totalScore > bestScore) {
          bestScore = totalScore;
          bestPrice = price;
        }
      }
    }

    if (bestPrice == null) {
      feedback?.updateFeedback("No reconozco este formato de precio");
    }

    return bestPrice;
  }

  String? _cleanAndExtractPrice(
      String rawText, {
        bool ignoreDecimals = false,
        String? currencyCode,
      }) {
    String textToProcess = rawText;
    if (currencyCode == 'BRL' && textToProcess.toUpperCase().startsWith('RS')) {
      textToProcess = textToProcess.substring(2);
    }

    String preProcessed = textToProcess
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

      if (!finalNumber.contains('.')) {
        if (finalNumber.length >= 5) continue;
      }

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