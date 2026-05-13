import 'dart:ui';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceInterpreter {
  final List<String> _history = [];
  String _stableText = "";

  String? getStablePrice(String newDetection) {
    _history.add(newDetection);

    // Volvemos a un historial de 5 para tener la amortiguación perfecta
    if (_history.length > 5) _history.removeAt(0);

    Map<String, int> counts = {};
    for (var val in _history) counts[val] = (counts[val] ?? 0) + 1;

    String? winner;
    int maxCount = 0;
    counts.forEach((val, count) {
      if (count > maxCount) {
        maxCount = count;
        winner = val;
      }
    });

    if (winner != null) {
      // 1. CAPTURA RÁPIDA: Si no hay precio en pantalla, mostramos el ganador con solo 2 lecturas
      if (_stableText.isEmpty && maxCount >= 2) {
        _stableText = winner!;
      }
      // 2. INERCIA (HISTÉRESIS): Si ya hay un precio fijo, somos tercos.
      // Exigimos 4 lecturas idénticas para permitir que otro número lo reemplace.
      else if (_stableText.isNotEmpty && winner != _stableText && maxCount >= 4) {
        _stableText = winner!;
      }
    }

    // Si el ruido es tan grande que no hay ni 2 números iguales, mantenemos el último precio estable
    return _stableText.isEmpty ? null : _stableText;
  }

  String? extractPriceFromRoi({
    required RecognizedText text,
    required Rect roi,
    required Size screenSize,
    required Size imageSize,
  }) {
    double imgWidth = imageSize.width;
    double imgHeight = imageSize.height;

    if (screenSize.height > screenSize.width && imageSize.width > imageSize.height) {
      imgWidth = imageSize.height;
      imgHeight = imageSize.width;
    }

    final double scale = max(screenSize.width / imgWidth, screenSize.height / imgHeight);
    final double offsetX = ((imgWidth * scale) - screenSize.width) / 2;
    final double offsetY = ((imgHeight * scale) - screenSize.height) / 2;

    final Offset roiCenter = roi.center;
    String? bestPrice;
    double minDistance = double.infinity;

    List<TextLine> validLines = [];

    print("\n========== NUEVO FRAME ==========");

    // 1. Filtrado espacial optimizado
    for (TextBlock block in text.blocks) {
      for (TextLine line in block.lines) {
        final Rect rectInScreen = Rect.fromLTRB(
          (line.boundingBox.left * scale) - offsetX,
          (line.boundingBox.top * scale) - offsetY,
          (line.boundingBox.right * scale) - offsetX,
          (line.boundingBox.bottom * scale) - offsetY,
        );

        if (roi.overlaps(rectInScreen)) {
          validLines.add(line);
          print("👁️ ML KIT LEYÓ: '${line.text}' | Centro Y: ${line.boundingBox.center.dy.toInt()} | Alto: ${line.boundingBox.height.toInt()}");
        }
      }
    }

    // 2. Agrupación y extracción
    for (int i = 0; i < validLines.length; i++) {
      TextLine mainLine = validLines[i];
      List<TextLine> row = [mainLine];

      for (int j = 0; j < validLines.length; j++) {
        if (i == j) continue;
        TextLine otherLine = validLines[j];

        double diffY = (mainLine.boundingBox.center.dy - otherLine.boundingBox.center.dy).abs();
        bool sameRow = diffY < mainLine.boundingBox.height;
        bool isToTheRight = otherLine.boundingBox.center.dx > mainLine.boundingBox.center.dx;
        bool isClose = (otherLine.boundingBox.left - mainLine.boundingBox.right).abs() < (mainLine.boundingBox.width * 2.5);

        if (sameRow && isToTheRight && isClose) {
          row.add(otherLine);
        } else if (isToTheRight && isClose) {
          print("⚠️ ALERTA DE SEPARACIÓN: '${mainLine.text}' y '${otherLine.text}' cerca pero falló sameRow. (DiffY: ${diffY.toInt()})");
        }
      }

      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      String combinedText = row.map((e) => e.text).join(' ');

      print("🔗 TEXTO AGRUPADO A EVALUAR: '$combinedText'");

      final price = _cleanAndExtractPrice(combinedText);

      if (price != null) {
        print("✅ PRECIO EXTRAÍDO CON ÉXITO: '$price'");

        double minLeft = row.map((e) => e.boundingBox.left).reduce(min);
        double minTop = row.map((e) => e.boundingBox.top).reduce(min);
        double maxRight = row.map((e) => e.boundingBox.right).reduce(max);
        double maxBottom = row.map((e) => e.boundingBox.bottom).reduce(max);

        final Offset combinedCenterInImage = Offset((minLeft + maxRight) / 2, (minTop + maxBottom) / 2);

        final Offset centerInScreen = Offset(
          (combinedCenterInImage.dx * scale) - offsetX,
          (combinedCenterInImage.dy * scale) - offsetY,
        );

        final double distance = sqrt(
            pow(centerInScreen.dx - roiCenter.dx, 2) +
                pow(centerInScreen.dy - roiCenter.dy, 2)
        );

        if (distance < minDistance) {
          minDistance = distance;
          bestPrice = price;
        }
      } else {
        print("❌ RECHAZADO POR REGEX: '$combinedText' no es un precio válido");
      }
    }

    return bestPrice;
  }

  String? _cleanAndExtractPrice(String rawText) {
    String cleaned = rawText;

    // Diccionario Tipográfico (OCR Fix) para escritura a mano
    cleaned = cleaned.replaceAll(RegExp(r'[oO]'), '0');
    cleaned = cleaned.replaceAll(RegExp(r'[iIlL]'), '1');
    cleaned = cleaned.replaceAll(RegExp(r'[zZ]'), '2');
    cleaned = cleaned.replaceAll(RegExp(r'[sS]'), '5');
    // Sumamos la "q" que suele confundirse con el 9 escrito a mano
    cleaned = cleaned.replaceAll(RegExp(r'[gGqQ]'), '9');
    cleaned = cleaned.replaceAll(RegExp(r'[bB]'), '8');

    cleaned = cleaned.replaceAllMapped(
      RegExp(r"(\d+)[-'_](\d{1,2})\b"),
          (Match m) => '${m[1]}.${m[2]}',
    );

    cleaned = cleaned.replaceAll(RegExp(r'[^\d.,\s]'), '');

    // Esta expresión es la que cumple su orden: "Que busque SI O SI 1 o 2 digitos separados y los una con punto"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d+)\s+(\d{1,2})\b'),
          (Match m) => '${m[1]}.${m[2]}',
    );

    cleaned = cleaned.replaceAll(' ', '');
    cleaned = cleaned.replaceAll(RegExp(r',(?=\d{3})'), '');

    final match = RegExp(r'\d+([.,]\d{1,2})?').firstMatch(cleaned);

    if (match != null) {
      return match.group(0)!.replaceAll(',', '.');
    }

    return null;
  }
}