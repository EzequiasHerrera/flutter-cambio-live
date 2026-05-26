import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceGroupsLogic {

  // 🔥 Las RegExp optimizadas que agregamos en el paso anterior
  static final RegExp _rxTieneNumeros = RegExp(r'[0-9]');
  static final RegExp _rxLetrasYBasura = RegExp(r'[^0-9.,]');
  static final RegExp _rxSoloDigitos = RegExp(r'[^0-9]');
  static final RegExp _rxNativoPerfecto = RegExp(r'[.,]\d{2}$');

  // ================================================|=====================
  // 🚀 METODO PRINCIPAL (Ahora es un esquema limpio y fácil de leer)
  // =====================================================================
  static List<List<TextLine>> agruparPrecioPorLider(List<TextLine> linesInRoi) {
    print("========== PASO 2: INICIANDO ANÁLISIS DE CANDIDATOS ==========");

    // 1. Descartar basura
    final digitLines = _filtrarNumeros(linesInRoi);
    if (digitLines.isEmpty) {
      print("❌ PASO 2: No hay líneas numéricas en el visor. Abortando frame.");
      return [];
    }

    // 2. Procesar lógica de unión/fractura
    final loteDeCandidatos = _procesarEstrategias(digitLines);

    // 3. Ordenar a los mejores
    return _ordenarRankingFinal(loteDeCandidatos);
  }

  // =====================================================================
  // 🛠️ METODOS PRIVADOS (Los sub-departamentos)
  // =====================================================================

  static List<TextLine> _filtrarNumeros(List<TextLine> lines) {
    return lines.where((line) => _rxTieneNumeros.hasMatch(line.text)).toList();
  }

  static List<List<TextLine>> _procesarEstrategias(List<TextLine> digitLines) {
    final List<List<TextLine>> lote = [];

    for (TextLine baseLine in digitLines) {
      final String textoOriginal = baseLine.text;
      final String textoLimpio = textoOriginal.replaceAll(_rxLetrasYBasura, '');
      final String digitosPuros = textoOriginal.replaceAll(_rxSoloDigitos, '');

      print("\n🔍 EVALUANDO LÍNEA: '$textoOriginal'");

      // Probamos el Caso A (si entra, pasa a la siguiente línea)
      if (_evaluarCasoA(textoLimpio, baseLine, lote)) continue;

      // Probamos el Caso B (si entra, pasa a la siguiente línea)
      if (_evaluarCasoB(digitosPuros, baseLine, lote)) continue;

      // Si no fue A ni B, probamos el Caso C
      _evaluarCasoC(baseLine, digitLines, lote);
    }

    return lote;
  }

  static bool _evaluarCasoA(String textoLimpio, TextLine baseLine, List<List<TextLine>> lote) {
    if (_rxNativoPerfecto.hasMatch(textoLimpio)) {
      print("   ✅ FORMATO PERFECTO: Contiene separador decimal nativo. Guardado intacto.");
      lote.add([baseLine]);
      return true;
    }
    return false;
  }

  static bool _evaluarCasoB(String digitosPuros, TextLine baseLine, List<List<TextLine>> lote) {
    if (digitosPuros.length >= 3) {
      final String parteCentavo = digitosPuros.substring(digitosPuros.length - 2);
      if (parteCentavo != "00") {
        final String parteEntera = digitosPuros.substring(0, digitosPuros.length - 2);
        print("   🛠️ FRACTURA: Separando virtualmente en Entero ['$parteEntera'] y Centavos ['$parteCentavo'].");

        lote.add([
          _clonarLineaConNuevoTexto(baseLine, parteEntera),
          _clonarLineaConNuevoTexto(baseLine, parteCentavo)
        ]);
        return true;
      }
    }
    return false;
  }

  static void _evaluarCasoC(TextLine baseLine, List<TextLine> digitLines, List<List<TextLine>> lote) {
    final List<TextLine> vecinos = digitLines.where((candidate) {
      if (candidate == baseLine) return false;

      final candDigitos = candidate.text.replaceAll(_rxSoloDigitos, '');
      if (candDigitos.length != 2) return false;

      // 🔥 SOLUCIÓN DIAGONAL: Calculamos los centros horizontales
      final double baseCenterX = (baseLine.boundingBox.left + baseLine.boundingBox.right) / 2;
      final double candCenterX = (candidate.boundingBox.left + candidate.boundingBox.right) / 2;

      // Ahora comparamos los centros en lugar de los bordes
      final bool aLaDerecha = candCenterX > baseCenterX;

      // Ampliamos el margen de tolerancia vertical al 50% para textos inclinados
      final double margen = baseLine.boundingBox.height * 0.5;
      final bool rangoVertical =
          candidate.boundingBox.top >= (baseLine.boundingBox.top - margen) &&
              candidate.boundingBox.bottom <= (baseLine.boundingBox.bottom + margen);

      return aLaDerecha && rangoVertical;
    }).toList();

    if (vecinos.isNotEmpty) {
      // Ordenamos de izquierda a derecha basándonos en sus centros
      vecinos.sort((a, b) {
        final centerA = (a.boundingBox.left + a.boundingBox.right) / 2;
        final centerB = (b.boundingBox.left + b.boundingBox.right) / 2;
        return centerA.compareTo(centerB);
      });

      print("   🔗 VECINOS: Se unió '${baseLine.text}' con el centavo '${vecinos.first.text}'.");
      lote.add([baseLine, vecinos.first]);
    } else {
      print("   ❓ SOLITARIA: Sin separador, ni absorción, ni vecinos. Se envía a la suerte.");
      lote.add([baseLine]);
    }
  }

  // Helper para acortar el código visualmente al partir líneas
  static TextLine _clonarLineaConNuevoTexto(TextLine original, String nuevoTexto) {
    return TextLine(
      text: nuevoTexto,
      boundingBox: original.boundingBox,
      elements: original.elements,
      cornerPoints: original.cornerPoints,
      recognizedLanguages: original.recognizedLanguages,
      confidence: original.confidence,
      angle: original.angle,
    );
  }

  static List<List<TextLine>> _ordenarRankingFinal(List<List<TextLine>> loteDeCandidatos) {
    loteDeCandidatos.sort((a, b) {
      final textA = a.map((e) => e.text).join(' ').replaceAll(_rxLetrasYBasura, '');
      final textB = b.map((e) => e.text).join(' ').replaceAll(_rxLetrasYBasura, '');

      final bool nativoA = _rxNativoPerfecto.hasMatch(textA) && a.length == 1;
      final bool nativoB = _rxNativoPerfecto.hasMatch(textB) && b.length == 1;

      // Prioridad 1: Formato Nativo
      if (nativoA && !nativoB) return -1;
      if (!nativoA && nativoB) return 1;

      // Prioridad 2: Tamaño de fuente (el más grande suele ser el precio real)
      return b.first.boundingBox.height.compareTo(a.first.boundingBox.height);
    });

    return loteDeCandidatos;
  }
}