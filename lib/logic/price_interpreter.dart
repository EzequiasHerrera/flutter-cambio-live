import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:howmuch/logic/price_clean.dart';
import 'package:howmuch/logic/price_complete_analyzer.dart';
import 'package:howmuch/logic/price_groups_logic.dart';
import 'package:howmuch/logic/price_roi_filter.dart';
import 'package:howmuch/services/feedback_service.dart';
import 'package:howmuch/services/ocr_service.dart';

class PriceInterpreter {
  final List<String> _history = [];
  String _stableText = "";

  /// Processes a single frame from the camera to extract a price.
  /// Handles geometry scaling, spatial filtering, grouping, and extraction.
  String? processFramePipeline({
    required RecognizedText text,
    required Rect roi,
    required Size screenSize,
    required Size imageSize,
    FeedbackService? feedback,
    bool ignoreDecimals = false,
  }) {
    // 1. Geometry Setup
    double imgWidth = imageSize.width;
    double imgHeight = imageSize.height;

    // Handle orientation mismatch
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

    // 2. Spatial Filtering (ROI)
    final List<TextLine> linesInRoi = PriceRoiFilter.filterPricesOnROI(
      text,
      roi,
      scale,
      offsetX,
      offsetY,
    );

    if (linesInRoi.isEmpty) {
      feedback?.updateFeedback("Apunta directamente al precio");
      return null;
    }

    // 3. Grouping Logic
    final List<List<TextLine>> groupedCandidates =
        PriceGroupsLogic.groupPricesByLeader(linesInRoi);

    // 4. Analysis and Extraction
    final result = PriceCompleteAnalyzer.analyzeAndExtract(
      groupedCandidates,
      roi.center,
      scale,
      offsetX,
      offsetY,
      ignoreDecimals: ignoreDecimals,
    );

    if (result == null) {
      feedback?.updateFeedback("No reconozco este formato de precio");
    }

    return result;
  }

  /// Determines a stable price from a stream of detections using a voting system.
  String? getStablePrice(String newDetection, FeedbackService? feedback) {
    _history.add(newDetection);
    if (_history.length > 5) _history.removeAt(0);

    final Map<String, int> counts = {};
    for (final val in _history) {
      counts[val] = (counts[val] ?? 0) + 1;
    }

    String? winner;
    int maxCount = 0;
    counts.forEach((val, count) {
      if (count > maxCount) {
        maxCount = count;
        winner = val;
      }
    });

    if (winner != null) {
      // Logic for updating the stable price
      if (_stableText.isEmpty && maxCount >= 2) {
        _stableText = winner!;
      } else if (_stableText.isNotEmpty &&
          winner != _stableText &&
          maxCount >= OCRService.requiredMatches) {
        _stableText = winner!;
      } else if (winner != _stableText) {
        feedback?.updateFeedback("Casi lo tengo... mantén la cámara fija");
      }
    }

    return _stableText.isEmpty ? null : _stableText;
  }

  /// Clears the detection history and stable text.
  void reset() {
    _history.clear();
    _stableText = "";
  }
}

