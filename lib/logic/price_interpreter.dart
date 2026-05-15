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
      else if (_stableText.isNotEmpty &&
          winner != _stableText &&
          maxCount >= 4) {
        _stableText = winner!;
      }
    }

    // Si el ruido es tan grande que no hay ni 2 números iguales, mantenemos el último precio estable
    return _stableText.isEmpty ? null : _stableText;
  }

  // ===========================================================================
  // METODO PRINCIPAL COORDINADOR
  // ===========================================================================
  String? extractPriceFromRoi({
    required RecognizedText text,
    required Rect roi,
    required Size screenSize,
    required Size imageSize,
  }) {
    print("\n========== NUEVO FRAME ==========");

    // 0. Configuración de geometría (Escalas y Offsets)
    double imgWidth = imageSize.width;
    double imgHeight = imageSize.height;

    if (screenSize.height > screenSize.width &&
        imageSize.width > imageSize.height) {
      imgWidth = imageSize.height;
      imgHeight = imageSize.width;
    }

    final double scale = max(
      screenSize.width / imgWidth,
      screenSize.height / imgHeight,
    );
    final double offsetX = ((imgWidth * scale) - screenSize.width) / 2;
    final double offsetY = ((imgHeight * scale) - screenSize.height) / 2;

    // PASO 1: Filtrado Espacial
    List<TextLine> validLines = _paso1FiltrarEnPantalla(
      text,
      roi,
      scale,
      offsetX,
      offsetY,
    );

    // PASO 2: Agrupación de Vecinos
    List<List<TextLine>> groupedCandidates = _paso2AgruparBloques(validLines);

    // PASO 3: Análisis y Extracción del Ganador
    return _paso3AnalizarYExtraer(
      groupedCandidates,
      roi.center,
      scale,
      offsetX,
      offsetY,
    );
  }

  // ===========================================================================
  // MÓDULOS DE PROCESAMIENTO
  // ===========================================================================

  List<TextLine> _paso1FiltrarEnPantalla(
    RecognizedText text,
    Rect roi,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    List<TextLine> validLines = [];

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
          print(
            "PASO 1: Encontré esto en pantalla (dentro del área): '${line.text}'",
          );
        }
      }
    }
    return validLines;
  }

  List<List<TextLine>> _paso2AgruparBloques(List<TextLine> validLines) {
    List<List<TextLine>> groupedCandidates = [];

    for (int i = 0; i < validLines.length; i++) {
      TextLine mainLine = validLines[i];
      List<TextLine> row = [mainLine];

      for (int j = 0; j < validLines.length; j++) {
        if (i == j) continue;
        TextLine otherLine = validLines[j];

        double diffY =
            (mainLine.boundingBox.center.dy - otherLine.boundingBox.center.dy)
                .abs();
        bool sameRow = diffY < mainLine.boundingBox.height;
        bool isToTheRight =
            otherLine.boundingBox.center.dx > mainLine.boundingBox.center.dx;
        bool isClose =
            (otherLine.boundingBox.left - mainLine.boundingBox.right).abs() <
            (mainLine.boundingBox.width * 2.5);

        if (sameRow && isToTheRight && isClose) {
          row.add(otherLine);
        }
      }

      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      groupedCandidates.add(row);

      String combinedText = row.map((e) => e.text).join(' ');
      print("PASO 2: Me quedo solo con estos bloques unidos: '$combinedText'");
    }

    return groupedCandidates;
  }

  String? _paso3AnalizarYExtraer(
    List<List<TextLine>> groupedCandidates,
    Offset roiCenter,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    String? bestPrice;
    double minDistance = double.infinity;

    for (List<TextLine> row in groupedCandidates) {
      String combinedText = row.map((e) => e.text).join(' ');

      print(
        "PASO 3: Analizo formato de precio completo en este bloque: '$combinedText'",
      );

      final price = _cleanAndExtractPrice(combinedText);

      if (price != null) {
        print("   -> ✅ ES UN PRECIO VÁLIDO: '$price'");

        double minLeft = row.map((e) => e.boundingBox.left).reduce(min);
        double minTop = row.map((e) => e.boundingBox.top).reduce(min);
        double maxRight = row.map((e) => e.boundingBox.right).reduce(max);
        double maxBottom = row.map((e) => e.boundingBox.bottom).reduce(max);

        final Offset combinedCenterInImage = Offset(
          (minLeft + maxRight) / 2,
          (minTop + maxBottom) / 2,
        );

        final Offset centerInScreen = Offset(
          (combinedCenterInImage.dx * scale) - offsetX,
          (combinedCenterInImage.dy * scale) - offsetY,
        );

        final double distance = sqrt(
          pow(centerInScreen.dx - roiCenter.dx, 2) +
              pow(centerInScreen.dy - roiCenter.dy, 2),
        );

        if (distance < minDistance) {
          minDistance = distance;
          bestPrice = price;
        }
      } else {
        print("   -> ❌ NO TIENE FORMATO. Descartado.");
      }
    }

    if (bestPrice != null) {
      print("🏆 GANADOR DEL FRAME (Más central): '$bestPrice'");
    }

    return bestPrice;
  }

  String? _cleanAndExtractPrice(String rawText) {
    // 1. EL ENSAMBLADOR: Unimos enteros y centavos huérfanos separados por espacio
    // Ej: "39 .99" o "39 99" o "39 , 99" se convierte en "39.99"
    String preProcessed = rawText.replaceAllMapped(
      RegExp(r'(\d+)\s*[.,]?\s+(\d{1,2})\b'),
      (Match m) => '${m[1]}.${m[2]}',
    );

    // 2. SEPARAMOS POR PALABRAS: Evaluamos cada bloque por separado
    // Así "500 BRL" se evalúa como "500" (válido) y "BRL" (descartado)
    List<String> words = preProcessed.split(RegExp(r'\s+'));

    for (String word in words) {
      String cleanedWord = word;

      // Aplicamos el diccionario solo a esta palabra
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[oO]'), '0');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[iIlL]'), '1');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[zZ]'), '2');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[sS]'), '5');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[gGqQ]'), '9');
      cleanedWord = cleanedWord.replaceAll(RegExp(r'[bB]'), '8');

      // 3. LA REGLA ESTRICTA (Escudo anti-ALMOFADA)
      // Quitamos temporalmente puntos, comas y símbolos de moneda comunes
      String testWord = cleanedWord.replaceAll(RegExp(r'[\$R.,]'), '');

      // ¿Le quedaron letras alfabéticas? Si es así, es una palabra mezclada (Ej: A1M0FADA)
      bool hasLetters = RegExp(r'[a-zA-Z]').hasMatch(testWord);

      if (hasLetters) {
        continue; // RECHAZADO: Tiene letras, pasamos a la siguiente palabra
      }

      // 4. VALIDACIÓN DE ESTRUCTURA MATEMÁTICA
      // Limpiamos los caracteres raros que hayan quedado
      String finalNumber = cleanedWord.replaceAll(RegExp(r'[^\d.,]'), '');

      // La Regex ahora tiene '^' y '$': Exige que TODO el string sea el número.
      // Debe EMPEZAR con un dígito de forma obligatoria.
      // Esto mata al '.99' porque empieza con un punto, devolviendo null.
      final match = RegExp(r'^\d+([.,]\d{1,2})?$').firstMatch(finalNumber);

      if (match != null) {
        return match.group(0)!.replaceAll(',', '.'); // Retornamos el ganador
      }
    }

    return null; // Si ninguna palabra cumplió los requisitos estrictos
  }
}
