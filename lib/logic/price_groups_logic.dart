import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PriceGroupsLogic {
  static List<List<TextLine>> agruparBloques(List<TextLine> linesInRoi) {
    return linesInRoi.map((baseLine) {
      // 1. Recibe la linea
      final List<TextLine> row = linesInRoi.where((comparisonLine) {
        if (baseLine == comparisonLine) return false; //Son la misma linea, descartamos

        //TODO: Acá hay una posible falla, porque mide la distancia de los centros del numero y los centavos. Quizás necesite ajuste
        final double diffY = (
            baseLine.boundingBox.center.dy //Centro vertical de la palabra base
                -
                comparisonLine.boundingBox.center.dy //Centro vertical de la palabra comparada
        ).abs(); //Lo transformo en absoluto para no tener negativos

        // ESTABLEZCO Evaluaciones geométricas puras
        final bool sameRow = diffY < baseLine.boundingBox.height;
        final bool isToTheRight = comparisonLine.boundingBox.center.dx > baseLine.boundingBox.center.dx;
        final bool isClose = (comparisonLine.boundingBox.left - baseLine.boundingBox.right).abs() < (baseLine.boundingBox.width * 2.5);

        // ACÁ EVALÚO Y RETORNO SI CUMPLEN LAS CONDICIONES
        return sameRow && isToTheRight && isClose;
      }).toList();

      // 2. Insertamos la línea principal al inicio y ordenamos horizontalmente de izquierda a derecha
      final List<TextLine> fullRow = [baseLine, ...row]
        ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

      // Telemetría limpia
      final String combinedText = fullRow.map((e) => e.text).join(' ');
      print("PASO 2: Bloque unido detectado: '$combinedText'");

      return fullRow;
    }).toList();
  }

  static List<List<TextLine>> agruparPrecioPorLider (List<TextLine> linesInRoi) {
    print("========== PASO 2: INICIANDO ANÁLISIS DE CANDIDATOS ==========");

    // 1. Limpieza inicial: Descartamos textos puros sin números ("TOMATE FRESCO", "Colores")
    final RegExp tieneNumeros = RegExp(r'[0-9]');
    final List<TextLine> digitLines = linesInRoi
        .where((line) => tieneNumeros.hasMatch(line.text))
        .toList();

    if (digitLines.isEmpty) {
      print("❌ PASO 2: No hay líneas numéricas en el visor. Abortando frame.");
      return [];
    }

    final List<List<TextLine>> loteDeCandidatos = [];

    // 2. Procesamos TODAS las líneas numéricas de forma independiente
    for (TextLine baseLine in digitLines) {
      final String textoOriginal = baseLine.text;
      final String textoLimpio = textoOriginal.replaceAll(RegExp(r'[^0-9.,]'), '');
      final String digitosPuros = textoOriginal.replaceAll(RegExp(r'[^0-9]'), '');

      print("\n🔍 EVALUANDO LÍNEA: '$textoOriginal'");

      // === CASO A: Nativo Perfecto ===
      // Si la lectura ya viene con una coma o punto y dos decimales (ej: "45,99")
      if (RegExp(r'[.,]\d{2}$').hasMatch(textoLimpio)) {
        print("   ✅ FORMATO PERFECTO: Contiene separador decimal nativo. Guardado intacto.");
        loteDeCandidatos.add([baseLine]);
        continue; // Lista esta línea, pasamos a la siguiente
      }

      // === CASO B: Absorción de Centavos ===
      // ML Kit pegó todo sin coma (ej: "4599" o el erróneo "459")
      if (digitosPuros.length >= 3) {
        final String parteCentavo = digitosPuros.substring(digitosPuros.length - 2);

        // Si termina en 00, es probable que sea un precio entero real ("500")
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
              confidence: baseLine.confidence, // Parche de dependencia
              angle: baseLine.angle,           // Parche de dependencia
            ),
            TextLine(
              text: parteCentavo,
              boundingBox: baseLine.boundingBox,
              elements: baseLine.elements,
              cornerPoints: baseLine.cornerPoints,
              recognizedLanguages: baseLine.recognizedLanguages,
              confidence: baseLine.confidence, // Parche de dependencia
              angle: baseLine.angle,           // Parche de dependencia
            )
          ]);
          continue;
        }
      }

      // === CASO C: Línea Corta o Enteros Puros ===
      // (Buscamos si tiene centavos flotando a su derecha)
      final List<TextLine> vecinos = digitLines.where((candidate) {
        if (candidate == baseLine) return false;

        final candDigitos = candidate.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (candDigitos.length != 2) return false; // Exigimos que el vecino sea un centavo de 2 dígitos

        final bool aLaDerecha = candidate.boundingBox.left >= baseLine.boundingBox.right - 5;
        final double margen = baseLine.boundingBox.height * 0.3; // 30% de flexibilidad vertical
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

    // 🏆 3. EL FILTRO DE ORO (Ordenamiento de Prioridad)
    // Acá evitamos que un número gigante roto ("R$45") le gane a un número real ("45,99")
    loteDeCandidatos.sort((a, b) {
      final textA = a.map((e) => e.text).join(' ').replaceAll(RegExp(r'[^0-9.,]'), '');
      final textB = b.map((e) => e.text).join(' ').replaceAll(RegExp(r'[^0-9.,]'), '');

      // Verificamos quiénes tienen coma/punto de fábrica
      final bool nativoA = RegExp(r'[.,]\d{2}$').hasMatch(textA) && a.length == 1;
      final bool nativoB = RegExp(r'[.,]\d{2}$').hasMatch(textB) && b.length == 1;

      // Regla 1: Las líneas con comas nativas van a la cima de la lista siempre
      if (nativoA && !nativoB) return -1; // 'A' gana
      if (!nativoA && nativoB) return 1;  // 'B' gana

      // Regla 2: Si hay empate (ambas tienen coma, o ambas no tienen), gana la caja más alta
      return b.first.boundingBox.height.compareTo(a.first.boundingBox.height);
    });

    // Mostramos el ranking final en consola para que veas qué entra primero al Paso 3
    print("\n========== RANKING FINAL DEL LOTE ==========");
    for (int i = 0; i < loteDeCandidatos.length; i++) {
      final strings = loteDeCandidatos[i].map((e) => e.text).join(' | ');
      print("  ${i + 1}º -> [ $strings ] (Alto: ${loteDeCandidatos[i].first.boundingBox.height}px)");
    }
    print("========================================================\n");

    return loteDeCandidatos;
  }

}