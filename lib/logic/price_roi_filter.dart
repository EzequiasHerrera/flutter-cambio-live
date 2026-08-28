import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceRoiFilter {
  /// Filtra los elementos de texto (números/palabras) cuyo centro está dentro del ROI.
  static List<TextElement> filterPricesOnROI(
      RecognizedText text,
      Rect roi,
      double scale,
      double offsetX,
      double offsetY,
      ) {
    final List<TextElement> validElements = [];

    for (final TextBlock block in text.blocks) {
      for (final TextLine line in block.lines) {
        // 1. Bajamos a nivel de TextElement para evitar textos pegados gigantes
        for (final TextElement element in line.elements) {

          // Mapeamos el BoundingBox del elemento a la pantalla
          final Rect elementInScreen = Rect.fromLTRB(
            (element.boundingBox.left * scale) - offsetX,
            (element.boundingBox.top * scale) - offsetY,
            (element.boundingBox.right * scale) - offsetX,
            (element.boundingBox.bottom * scale) - offsetY,
          );

          // 2. Evaluamos si el CENTRO del elemento está dentro del ROI
          if (roi.contains(elementInScreen.center)) {

            // Regla 1: Descartar si el elemento individual es más ancho que el ROI
            if (elementInScreen.width > roi.width) continue;

            // Regla 2: Filtro de altura mínima más realista (5% a 8% del alto del ROI)
            // Esto permite capturar céntimos o tipografías chicas sin comerse basuras de 2px
            if (elementInScreen.height < roi.height * 0.08) continue;

            validElements.add(element);
          }
        }
      }
    }
    return validElements;
  }
}