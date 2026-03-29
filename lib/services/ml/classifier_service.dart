import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../features/analysis/domain/models/prediction_result.dart';
import 'firebase_model_service.dart';
import 'inference_isolate.dart';

class ClassifierService {
  List<String>? _labels;
  File? _modelFile;
  bool _isInit = false;

  final String _labelsPath = 'assets/labels/label.csv';
  final String _localModelPath = 'assets/models/food_classifier.tflite';

  Future<void> initialize() async {
    if (_isInit) return;
    try {
      await _loadLabels();
      try {
        _modelFile = await FirebaseModelService.downloadModel().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint("Firebase download timeout/error: $e. Fallback to local model.");
        _modelFile = null;
      }
      _isInit = true;
      debugPrint("ClassifierService initialized.");
    } catch (e) {
      debugPrint("Error initializing ClassifierService: $e");
    }
  }

  Future<void> _loadLabels() async {
    try {
      final String labelStr = await rootBundle.loadString(_labelsPath);
      final lines = labelStr.split('\n').where((s) => s.trim().isNotEmpty).toList();

      _labels = [];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (i == 0 && line.toLowerCase().contains('id') && line.toLowerCase().contains('name')) {
          continue;
        }

        final parts = line.split(',');
        if (parts.length >= 2) {
          String name = parts.sublist(1).join(',').trim();
          name = name.replaceAll('"', '');
          _labels!.add(name);
        } else {
          _labels!.add(line.trim().replaceAll('"', ''));
        }
      }
    } catch (e) {
      debugPrint("Warning: Could not load $_labelsPath ($e).");
      _labels = ['Pizza', 'Burger', 'Salad', 'Sushi', 'Poke Bowl'];
    }
  }

  Future<PredictionResult?> classifyImage(File imageFile) async {
    if (!_isInit) await initialize();

    final modelPath = _modelFile?.path ?? _localModelPath;

    final Uint8List modelBytes;
    try {
      if (modelPath.startsWith('assets/')) {
        final byteData = await rootBundle.load(modelPath);
        modelBytes = byteData.buffer.asUint8List();
      } else {
        modelBytes = await File(modelPath).readAsBytes();
      }
    } catch (e) {
      debugPrint("Failed to load model bytes: $e");
      return null;
    }

    final output = await compute(
      runInferenceInBackground,
      InferencePayload(imagePath: imageFile.path, modelBytes: modelBytes),
    );

    if (output == null) return null;

    final scores = output.scores;
    int maxScore = 0;
    int maxIdx = -1;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIdx = i;
      }
    }

    debugPrint("Top prediction: idx=$maxIdx, score=$maxScore");

    if (maxIdx < 0) return null;

    final labelName = (_labels != null && maxIdx < _labels!.length)
        ? _labels![maxIdx]
        : "Unknown";

    return PredictionResult(label: labelName, confidence: maxScore / 255.0);
  }
}
