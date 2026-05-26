import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceRoiFilter {
  // 🧮 TODO PROCESAMIENTO
  static List<TextLine> filterPricesOnROI(
      RecognizedText text,
      Rect roi,
      double scale,
      double offsetX,
      double offsetY,
      ) {
    List<TextLine> validLines = [];

    //EVALÚA TOODO EL TEXTO LEIDO
    for (TextBlock block in text.blocks) {
      for (TextLine line in block.lines) {
        //🔳 CREA UN RECTANGULO IMAGINARIO ALREDEDOR DEL TEXTO PARA SABER SI ESTÁ DENTRO DEL ESPACIO ACEPTADO
        final Rect textLineInScreen = Rect.fromLTRB(
          (line.boundingBox.left * scale) - offsetX,
          (line.boundingBox.top * scale) - offsetY,
          (line.boundingBox.right * scale) - offsetX,
          (line.boundingBox.bottom * scale) - offsetY,
        );

        if (roi.overlaps(textLineInScreen)) {
          validLines.add(line);
          print(
            "PASO 1: Encontré esto en pantalla (dentro del área): '${line.text}'",
          );
        }
      }
    }
    return validLines;
  }
}