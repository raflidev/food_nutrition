import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../app/theme/app_colors.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  static Future<File?> cropImage(File imageFile, BuildContext context) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Food Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Food Image',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
    }
    return null;
  }

  static Future<File?> pickAndCropImage(
      BuildContext context, ImageSource source) async {
    final File? pickedImage = await pickImage(source);
    if (pickedImage != null) {
      if (!context.mounted) return null;
      return await cropImage(pickedImage, context);
    }
    return null;
  }
}
