import 'dart:io';
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

abstract class InferenceIsolateHelper {
  static List<int>? preprocessImage(String imagePath, int inputSize) {
    try {
      final imageBytes = File(imagePath).readAsBytesSync();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      final resized = img.copyResize(originalImage, width: inputSize, height: inputSize);

      final buffer = List<int>.filled(inputSize * inputSize * 3, 0);
      int idx = 0;
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          buffer[idx++] = pixel.r.toInt();
          buffer[idx++] = pixel.g.toInt();
          buffer[idx++] = pixel.b.toInt();
        }
      }
      return buffer;
    } catch (e) {
      return null;
    }
  }
}
