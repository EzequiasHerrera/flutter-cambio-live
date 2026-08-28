import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:howmuch/logic/price_clean.dart';

class PriceCompleteAnalyzer {
  /// Analiza y extrae el mejor candidato de precio a partir de elementos agrupados.
  /// Selecciona el precio con mejor balance entre tamaño y cercanía al centro del ROI.
  static String? analyzeAndExtract(
      List<List<TextElement>> groupedCandidates,
      Offset roiCenter,
      double scale,
      double offsetX,
      double offsetY, {
        bool ignoreDecimals = false,
        String? currencyCode,
      }) {
    String? bestPrice;
    double bestScore = -1.0; // A mayor puntaje, mejor candidato

    for (final List<TextElement> row in groupedCandidates) {
      final String combinedText = row.map((e) => e.text).join(' ');
      final String? price = PriceClean.cleanAndExtractPrice(
        combinedText,
        ignoreDecimals: ignoreDecimals,
        currencyCode: currencyCode,
      );

      if (price != null) {
        final Offset centerInScreen = _calculateCenterOnScreen(row, scale, offsetX, offsetY);
        final double distance = (centerInScreen - roiCenter).distance;

        // Priorizar elementos centrales Y de gran tamaño de fuente
        final double height = row.first.boundingBox.height * scale;

        // Normalización del puntaje por centralidad y tamaño
        final double centralityScore = max(0.0, 1000.0 - distance);
        final double sizeScore = height * 2.0; // Ponderación de altura

        final double totalScore = centralityScore + sizeScore;

        if (totalScore > bestScore) {
          bestScore = totalScore;
          bestPrice = price;
        }
      }
    }

    return bestPrice;
  }

  /// Calcula el centro visual exacto en coordenadas de pantalla para un grupo de TextElements.
  static Offset _calculateCenterOnScreen(
      List<TextElement> row,
      double scale,
      double offsetX,
      double offsetY,
      ) {
    double minLeft = row.map((e) => e.boundingBox.left.toDouble()).reduce(min);
    double minTop = row.map((e) => e.boundingBox.top.toDouble()).reduce(min);
    double maxRight = row.map((e) => e.boundingBox.right.toDouble()).reduce(max);
    double maxBottom = row.map((e) => e.boundingBox.bottom.toDouble()).reduce(max);

    final Offset combinedCenterInImage = Offset(
      (minLeft + maxRight) / 2.0,
      (minTop + maxBottom) / 2.0,
    );

    return Offset(
      (combinedCenterInImage.dx * scale) - offsetX,
      (combinedCenterInImage.dy * scale) - offsetY,
    );
  }
}