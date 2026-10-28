import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Create a Riverpod provider so your UI can easily access this service
final ocrProvider = Provider<OcrService>((ref) {
  return OcrService();
});

class OcrService {
  final ImagePicker _picker = ImagePicker();

  // Initializes the ML Kit text recognizer for standard Latin characters
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Opens the camera or gallery, scans the image, and returns the extracted text.
  Future<String?> scanReceipt(ImageSource source) async {
    try {
      // 1. Pick the image (from camera or gallery)
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null; // The user closed the camera/gallery without taking a photo

      // 2. Prepare the image for ML Kit
      final inputImage = InputImage.fromFilePath(image.path);

      // 3. Extract the text
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (_) {
      return null;
    }
  }

  /// Always clean up the recognizer when done to prevent memory leaks
  void dispose() {
    _textRecognizer.close();
  }
}