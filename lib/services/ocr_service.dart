import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  // Cuántos fotogramas idénticos necesitamos para "creerle" al precio
  static int requiredMatches = 4;
  // Tiempo mínimo entre procesamientos en ms
  static int processIntervalMs = 300;
  // Tolerancia para aceptar precios sin centavos
  static bool allowIntegersOnly = false;

  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<RecognizedText> processImage(InputImage inputImage) async {
    return await _textRecognizer.processImage(inputImage);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
