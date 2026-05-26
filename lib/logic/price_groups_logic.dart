import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceGroupsLogic {

  // 🔥 OPTIMIZACIÓN: Compilamos las RegExp que antes estaban dentro del for
  static final RegExp _rxTieneNumeros = RegExp(r'[0-9]');
  static final RegExp _rxLetrasYBasura = RegExp(r'[^0-9.,]');
  static final RegExp _rxSoloDigitos = RegExp(r'[^0-9]');
  static final RegExp _rxNativoPerfecto = RegExp(r'[.,]\d{2}$');

  static List<List<TextLine>> agruparPrecioPorLider (List<TextLine> linesInRoi) {
    print("========== PASO 2: INICIANDO ANÁLISIS DE CANDIDATOS ==========");

    // 1. Limpieza inicial
    final List<TextLine> digitLines = linesInRoi
        .where((line) => _rxTieneNumeros.hasMatch(line.text))
        .toList();

    if (digitLines.isEmpty) {
      print("❌ PASO 2: No hay líneas numéricas en el visor. Abortando frame.");
      return [];
    }

    final List<List<TextLine>> loteDeCandidatos = [];

    // 2. Procesamos TODAS las líneas numéricas de forma independiente
    for (TextLine baseLine in digitLines) {
      final String textoOriginal = baseLine.text;
      final String textoLimpio = textoOriginal.replaceAll(_rxLetrasYBasura, '');
      final String digitosPuros = textoOriginal.replaceAll(_rxSoloDigitos, '');

      print("\n🔍 EVALUANDO LÍNEA: '$textoOriginal'");

      // === CASO A: Nativo Perfecto ===
      if (_rxNativoPerfecto.hasMatch(textoLimpio)) {
        print("   ✅ FORMATO PERFECTO: Contiene separador decimal nativo. Guardado intacto.");
        loteDeCandidatos.add([baseLine]);
        continue;
      }

      // === CASO B: Absorción de Centavos ===
      if (digitosPuros.length >= 3) {
        final String parteCentavo = digitosPuros.substring(digitosPuros.length - 2);

        if (parteCentavo != "00") {
          final String parteEntera = digitosPuros.substring(0, digitosPuros.length - 2);
          print("   🛠️ FRACTURA: Separando virtualmente en Entero ['$parteEntera'] y Centavos ['$parteCentavo'].");

          loteDeCandidatos.add([
            TextLine(
              text: parteEntera,
              boundingBox: baseLine.boundingBox,
              elements: baseLine.elements,
              cornerPoints: baseLine.cornerPoints,
              recognizedLanguages: baseLine.recognizedLanguages,
              confidence: baseLine.confidence,
              angle: baseLine.angle,
            ),
            TextLine(
              text: parteCentavo,
              boundingBox: baseLine.boundingBox,
              elements: baseLine.elements,
              cornerPoints: baseLine.cornerPoints,
              recognizedLanguages: baseLine.recognizedLanguages,
              confidence: baseLine.confidence,
              angle: baseLine.angle,
            )
          ]);
          continue;
        }
      }

      // === CASO C: Línea Corta o Enteros Puros ===
      final List<TextLine> vecinos = digitLines.where((candidate) {
        if (candidate == baseLine) return false;

        final candDigitos = candidate.text.replaceAll(_rxSoloDigitos, '');
        if (candDigitos.length != 2) return false;

        final bool aLaDerecha = candidate.boundingBox.left >= baseLine.boundingBox.right - 5;
        final double margen = baseLine.boundingBox.height * 0.3;
        final bool rangoVertical =
            candidate.boundingBox.top >= (baseLine.boundingBox.top - margen) &&
                candidate.boundingBox.bottom <= (baseLine.boundingBox.bottom + margen);

        return aLaDerecha && rangoVertical;
      }).toList();

      if (vecinos.isNotEmpty) {
        vecinos.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        print("   🔗 VECINOS: Se unió '$textoOriginal' con el centavo flotante '${vecinos.first.text}'.");
        loteDeCandidatos.add([baseLine, vecinos.first]);
      } else {
        print("   ❓ SOLITARIA: Sin separador, sin absorción lógica y sin vecinos. Se envía a la suerte.");
        loteDeCandidatos.add([baseLine]);
      }
    }

    // 🏆 3. EL FILTRO DE ORO
    loteDeCandidatos.sort((a, b) {
      final textA = a.map((e) => e.text).join(' ').replaceAll(_rxLetrasYBasura, '');
      final textB = b.map((e) => e.text).join(' ').replaceAll(_rxLetrasYBasura, '');

      final bool nativoA = _rxNativoPerfecto.hasMatch(textA) && a.length == 1;
      final bool nativoB = _rxNativoPerfecto.hasMatch(textB) && b.length == 1;

      if (nativoA && !nativoB) return -1;
      if (!nativoA && nativoB) return 1;

      return b.first.boundingBox.height.compareTo(a.first.boundingBox.height);
    });

    return loteDeCandidatos;
  }
}