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
      // Advanced: Coba download model dari Firebase ML (dengan timeout 3 detik!)
      // Jika internet lambat, kita jadikan fallback ke model lokal agar user tidak menunggu selamanya.
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
        // Skip baris pertama jika itu adalah header (id,name)
        if (i == 0 && line.toLowerCase().contains('id') && line.toLowerCase().contains('name')) {
          continue;
        }
        
        // Split berdasarkan comma
        final parts = line.split(',');
        if (parts.length >= 2) {
          // Ambil bagian 'name' dan bersihkan spasi/petik jika ada
          String name = parts.sublist(1).join(',').trim(); // Antisipasi kalau nama punya koma
          name = name.replaceAll('"', ''); // Hapus tanda petik ganda
          _labels!.add(name);
        } else {
          // Jika tidak ada koma, anggap saja 1 baris adalah nama (fallback)
          _labels!.add(line.trim().replaceAll('"', ''));
        }
      }
    } catch (e) {
      debugPrint("Warning: Could not load $_labelsPath ($e).");
      // Fallback mock labels for testing if not provided by user
      _labels = ['Pizza', 'Burger', 'Salad', 'Sushi', 'Poke Bowl'];
    }
  }

  /// Memproses klasifikasi gambar menggunakan Isolate (Thread Terpisah)
  Future<PredictionResult?> classifyImage(File imageFile) async {
    if (!_isInit) await initialize();

    final modelPath = _modelFile?.path ?? _localModelPath;

    // Load model bytes di main isolate
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

    // Jalankan inference di main isolate (loading dialog sudah tampil, jank tidak masalah)
    // Isolate.run() tidak bisa akses FFI bindings tflite yang diinisialisasi di Flutter engine
    return _runInference(imageFile.path, modelBytes);
  }

  PredictionResult? _runInference(String imagePath, Uint8List modelBytes) {
    Interpreter? interpreter;
    try {
      interpreter = Interpreter.fromBuffer(modelBytes);

      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);
      final inputShape = inputTensor.shape; // [1, 192, 192, 3]
      final inputSize = inputShape[1];      // 192
      final numClasses = outputTensor.shape.last; // 2024

      // Preprocess: uint8 flat list, lalu reshape ke [1, inputSize, inputSize, 3]
      final flatInput = InferenceIsolateHelper.preprocessImage(imagePath, inputSize);
      if (flatInput == null) {
        debugPrint("Preprocessing failed.");
        return null;
      }
      final input = flatInput.reshape(inputShape);

      // Output uint8: [1, numClasses]
      final outputBuffer = [List<int>.filled(numClasses, 0)];

      interpreter.run(input, outputBuffer);
      interpreter.close();

      final scores = outputBuffer[0];
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
    } catch (e) {
      interpreter?.close();
      debugPrint("Inference error: $e");
      return null;
    }
  }
}
