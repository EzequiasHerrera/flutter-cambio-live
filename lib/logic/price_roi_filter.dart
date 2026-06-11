import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceRoiFilter {
  /// Filters text lines that overlap with the Region of Interest (ROI).
  /// Converts image coordinates to screen coordinates before checking overlap.
  static List<TextLine> filterPricesOnROI(
    RecognizedText text,
    Rect roi,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final List<TextLine> validLines = [];

    for (final TextBlock block in text.blocks) {
      for (final TextLine line in block.lines) {
        // Map bounding box from image coordinates to screen coordinates
        final Rect textLineInScreen = Rect.fromLTRB(
          (line.boundingBox.left * scale) - offsetX,
          (line.boundingBox.top * scale) - offsetY,
          (line.boundingBox.right * scale) - offsetX,
          (line.boundingBox.bottom * scale) - offsetY,
        );

        if (roi.overlaps(textLineInScreen)) {
          validLines.add(line);
        }
      }
    }
    return validLines;
  }
}
