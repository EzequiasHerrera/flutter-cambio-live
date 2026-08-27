import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:howmuch/logic/price_clean.dart';

class PriceCompleteAnalyzer {
  /// Analyzes and extracts the best price candidate from grouped text lines.
  /// Selects the price closest to the center of the ROI.
  static String? analyzeAndExtract(
    List<List<TextLine>> groupedCandidates,
    Offset roiCenter,
    double scale,
    double offsetX,
    double offsetY, {
    bool ignoreDecimals = false,
    String? currencyCode,
  }) {
    String? bestPrice;
    double bestScore = -1.0; // Higher is better

    for (final List<TextLine> row in groupedCandidates) {
      final String combinedText = row.map((e) => e.text).join(' ');
      final String? price = PriceClean.cleanAndExtractPrice(
        combinedText,
        ignoreDecimals: ignoreDecimals,
        currencyCode: currencyCode,
      );

      if (price != null) {
        final Offset centerInScreen = _calculateCenterOnScreen(row, scale, offsetX, offsetY);
        final double distance = (centerInScreen - roiCenter).distance;

        // Point 1: Prioritize central AND large
        // We calculate a score based on height (size) and distance (centrality)
        final double height = row.first.boundingBox.height * scale;
        
        // Normalize distance: 0 at center, decreasing as it moves away.
        // We use a simple inversion or subtraction from a large enough constant.
        final double centralityScore = max(0, 1000 - distance);
        final double sizeScore = height * 2; // Weight size slightly more
        
        final double totalScore = centralityScore + sizeScore;

        if (totalScore > bestScore) {
          bestScore = totalScore;
          bestPrice = price;
        }
      }
    }

    return bestPrice;
  }

  /// Calculates the visual center of a group of TextLines in screen coordinates.
  static Offset _calculateCenterOnScreen(
    List<TextLine> row,
    double scale,
    double offsetX,
    double offsetY,
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
