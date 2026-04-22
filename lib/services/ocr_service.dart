import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<RecognizedText> processImage(InputImage inputImage) async {
    return await _textRecognizer.processImage(inputImage);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
