import 'dart:ui';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:howmuch/logic/price_complete_analizer.dart';
import 'package:howmuch/logic/price_groups_logic.dart';
import 'package:howmuch/logic/price_roi_filter.dart';

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

  // 📷 TODO EXTRACTOR DE INFORMACION
  String? processFramePipeline({
    required RecognizedText text, //Texto del OCR
    required Rect roi, //Rectángulo de interés (ROI)
    required Size screenSize,
    required Size imageSize,
  }) {
    print("\n========== NUEVO FRAME ==========");

    // 0. Configuración de geometría (Escalas y Offsets)
    double imgWidth = imageSize.width;
    double imgHeight = imageSize.height;

    // ✅🤳🏻 Evalúa si la resolución viene invertida
    if (screenSize.height > screenSize.width && imageSize.width > imageSize.height) {
      imgWidth = imageSize.height;
      imgHeight = imageSize.width;
    }

    // Obtengo el tamaño real de la foto para que coincida lo que el usuario vé de la cámara (Box.cover) con la foto tomada por la camara
    final double scale = max(
      screenSize.width / imgWidth,
      screenSize.height / imgHeight,
    );
    final double offsetX = ((imgWidth * scale) - screenSize.width) / 2;
    final double offsetY = ((imgHeight * scale) - screenSize.height) / 2;

    // 1️⃣ PASO 1: Filtrado Espacial
    List<TextLine> linesInRoi = PriceRoiFilter.filterPricesOnROI(text, roi, scale, offsetX, offsetY,);
    // 2️⃣ PASO 2: Agrupación de Vecinos
    List<List<TextLine>> groupedCandidates = PriceGroupsLogic.agruparPrecioPorLider(linesInRoi);
    // 3️⃣ PASO 3: Análisis y Extracción del Ganador
    return PriceCompleteAnalizer.analizarYExtraer(
      groupedCandidates,
      roi.center,
      scale,
      offsetX,
      offsetY,
    );
  }
}