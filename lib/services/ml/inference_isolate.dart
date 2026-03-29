import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class InferencePayload {
  final String imagePath;
  final Uint8List modelBytes;

  const InferencePayload({required this.imagePath, required this.modelBytes});
}

class InferenceOutput {
  final List<int> scores;

  const InferenceOutput({required this.scores});
}

Future<InferenceOutput?> runInferenceInBackground(InferencePayload payload) async {
  Interpreter? interpreter;
  try {
    interpreter = Interpreter.fromBuffer(payload.modelBytes);

    final inputShape = interpreter.getInputTensor(0).shape;
    final inputSize = inputShape[1];
    final numClasses = interpreter.getOutputTensor(0).shape.last;

    final flatInput = _preprocessImage(payload.imagePath, inputSize);
    if (flatInput == null) {
      interpreter.close();
      return null;
    }

    final input = flatInput.reshape(inputShape);
    final outputBuffer = [List<int>.filled(numClasses, 0)];

    interpreter.run(input, outputBuffer);
    interpreter.close();

    return InferenceOutput(scores: outputBuffer[0]);
  } catch (e) {
    interpreter?.close();
    return null;
  }
}

List<int>? _preprocessImage(String imagePath, int inputSize) {
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
