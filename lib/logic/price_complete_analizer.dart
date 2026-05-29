import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:howmuch/logic/price_clean.dart';

class PriceCompleteAnalizer {
  static String? analizarYExtraer(
      List<List<TextLine>> groupedCandidates,
      Offset roiCenter,
      double scale,
      double offsetX,
      double offsetY,
      ) {
    String? bestPrice;
    double minDistance = double.infinity; // ES PARA QUE SIEMPRE EL PRIMER PRECIO SEA EL GANADOR

    for (List<TextLine> row in groupedCandidates) { // Tomo por ejemplo "1.000,85"
      String combinedText = row.map((e) => e.text).join(' '); // Queda como "1.000,85"

      print(
        "PASO 3: Analizo formato de precio completo en este bloque: '$combinedText'",
      );

      final price = PriceClean.cleanAndExtractPrice(combinedText);

      if (price != null) {
        print("   -> ✅ ES UN PRECIO VÁLIDO: '$price'");

        // 🔥 EXTRAÍDO: La matemática sucia ahora vive en su propio método abajo
        final Offset centerInScreen = _calcularCentroEnPantalla(row, scale, offsetX, offsetY);

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

  // 📐 Metodo PRIVADO: Se encarga de la geometría de la caja
  static Offset _calcularCentroEnPantalla(
      List<TextLine> row,
      double scale,
      double offsetX,
      double offsetY
      ) {
    double minLeft = row.map((e) => e.boundingBox.left).reduce(min);
    double minTop = row.map((e) => e.boundingBox.top).reduce(min);
    double maxRight = row.map((e) => e.boundingBox.right).reduce(max);
    double maxBottom = row.map((e) => e.boundingBox.bottom).reduce(max);

    final Offset combinedCenterInImage = Offset(
      (minLeft + maxRight) / 2,
      (minTop + maxBottom) / 2,
    );

    return Offset(
      (combinedCenterInImage.dx * scale) - offsetX,
      (combinedCenterInImage.dy * scale) - offsetY,
    );
  }
}