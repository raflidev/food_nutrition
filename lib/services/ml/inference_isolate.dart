import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class InferenceData {
  final String imagePath;
  final String modelPath;

  InferenceData({required this.imagePath, required this.modelPath});
}

class InferenceResult {
  final List<double> outputProbabilities;
  final Duration inferenceTime;

  InferenceResult({required this.outputProbabilities, required this.inferenceTime});
}

// NOTE: We put the actual isolate execution logic in the classifier_service
// since tflite_flutter Interpreter needs to be instantiated inside the isolate
// or sent correctly. We provide helper methods here.

abstract class InferenceIsolateHelper {
  static Uint8List? preprocessImage(String imagePath, int inputSize) {
    try {
      final imageFile = File(imagePath);
      final imageBytes = imageFile.readAsBytesSync();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) return null;

      // Resize
      img.Image resizedImage = img.copyResize(originalImage, width: inputSize, height: inputSize);

      // Convert to float32 (for models requiring -1 to 1 or 0 to 1 normalization)
      // Note: Google AIY Vision classifier v1 is quantized (Uint8) 224x224x3
      // We assume it returns probabilities directly or needs quantized input.
      // Let's return raw RGB bytes because it is typically uint8.
      
      final Float32List floatBuffer = Float32List(inputSize * inputSize * 3);
      int pixelIndex = 0;
      for (int y = 0; y < resizedImage.height; y++) {
        for (int x = 0; x < resizedImage.width; x++) {
          final pixel = resizedImage.getPixel(x, y);
          // Normalization (0 - 1.0) generally works for unquantized.
          // Adjust this if quantized model (e.g., using Uint8List instead).
          // We will use standard Float32 normalization just in case.
          floatBuffer[pixelIndex++] = (pixel.r) / 255.0;
          floatBuffer[pixelIndex++] = (pixel.g) / 255.0;
          floatBuffer[pixelIndex++] = (pixel.b) / 255.0;
        }
      }
      return floatBuffer.buffer.asUint8List();
    } catch (e) {
      // Ignored
    }
    return null;
  }
}
