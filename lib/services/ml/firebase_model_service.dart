import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/foundation.dart';

class FirebaseModelService {
  static const String modelName = 'food_classifier'; // Nama model di Firebase Console

  /// Mengunduh model dari Firebase ML secara dinamis
  static Future<File?> downloadModel() async {
    try {
      // Pastikan Firebase sudah diinisialisasi
      if (Firebase.apps.isEmpty) {
        debugPrint("Firebase not initialized. Cannot download model.");
        return null;
      }

      // Mendownload model (menggunakan model lokal jika tersedia dan up-to-date)
      final FirebaseCustomModel customModel = await FirebaseModelDownloader.instance.getModel(
          modelName,
          FirebaseModelDownloadType.localModelUpdateInBackground,
          FirebaseModelDownloadConditions(
            iosAllowsCellularAccess: true,
            iosAllowsBackgroundDownloading: false,
            androidChargingRequired: false,
            androidWifiRequired: false,
            androidDeviceIdleRequired: false,
          ));

      final File modelFile = customModel.file;
      debugPrint("Model downloaded to: ${modelFile.path}");
      return modelFile;
    } catch (e) {
      debugPrint("Error downloading Firebase ML model: $e");
      return null;
    }
  }
}
