import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../features/analysis/domain/models/prediction_result.dart';
import '../../../../services/ml/classifier_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInit = false;
  FlashMode _flashMode = FlashMode.auto;

  final ClassifierService _classifier = ClassifierService();
  Timer? _scanTimer;
  PredictionResult? _livePrediction;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _classifier.initialize();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setupCameraController(_cameras[0]);
      } else {
        debugPrint("No cameras found");
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    final newController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = newController;

    try {
      await newController.initialize();
      if (mounted) {
        setState(() => _isInit = true);
        _startLiveScan();
      }
    } catch (e) {
      debugPrint("Camera initialize error: $e");
    }
  }

  void _startLiveScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (_) => _performLiveScan());
  }

  Future<void> _performLiveScan() async {
    if (_isScanning) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    _isScanning = true;
    try {
      final XFile file = await _controller!.takePicture();
      final result = await _classifier.classifyImage(File(file.path));
      try {
        File(file.path).deleteSync();
      } catch (_) {}
      if (mounted) setState(() => _livePrediction = result);
    } catch (e) {
      debugPrint("Live scan error: $e");
    } finally {
      _isScanning = false;
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _scanTimer?.cancel();
      if (mounted) setState(() => _isInit = false);
      await _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      if (!_isInit && _cameras.isNotEmpty) {
        await _setupCameraController(_cameras[0]);
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture || _isScanning) return;

    _scanTimer?.cancel();

    try {
      final XFile image = await _controller!.takePicture();
      _processImage(File(image.path));
    } catch (e) {
      debugPrint("Error taking picture: $e");
      _startLiveScan();
    }
  }

  void _processImage(File imageFile) async {
    final File? cropped = await ImageUtils.cropImage(imageFile, context);
    if (cropped != null) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Material(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 20),
                  Text(
                    "Analyzing AI...",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final prediction = await _classifier.classifyImage(cropped);
        debugPrint("=== PREDICTION RESULT: $prediction, label=${prediction?.label}, conf=${prediction?.confidence}");

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        if (prediction != null) {
          context.push('/analysis', extra: {
            'image': cropped,
            'prediction': prediction,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to analyze the image.')),
          );
          _startLiveScan();
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error AI Processing: $e')),
        );
        _startLiveScan();
      }
    } else {
      _startLiveScan();
    }
  }

  Future<void> _pickFromGallery() async {
    final File? image = await ImageUtils.pickImage(ImageSource.gallery);
    if (image != null) {
      _processImage(image);
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      default:
        nextMode = FlashMode.auto;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (e) {
      debugPrint("Error toggling flash: $e");
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _controller == null) {
      if (_cameras.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isInit) _initCamera();
        });
      }
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
      );
    }

    final size = MediaQuery.of(context).size;
    final scale = size.aspectRatio * _controller!.value.aspectRatio;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: scale < 1 ? 1 / scale : scale,
            child: Center(child: CameraPreview(_controller!)),
          ),

          const _ViewfinderOverlay(),

          if (_livePrediction != null) _buildLivePredictionBadge(),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(Icons.close, () => context.go('/dashboard')),
                Row(
                  children: [
                    _buildCircularButton(_getFlashIcon(), _toggleFlash),
                    const SizedBox(width: 16),
                    _buildCircularButton(Icons.settings, () {}),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildGalleryButton(),
                  _buildShutterButton(),
                  const SizedBox(width: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePredictionBadge() {
    final confidence = _livePrediction!.confidence;
    final confidencePct = (confidence * 100).toStringAsFixed(0);
    final isHighConfidence = confidence >= 0.5;
    final badgeColor = isHighConfidence ? AppColors.primaryContainer : Colors.white70;

    return Positioned(
      bottom: 160,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(160),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: badgeColor.withAlpha(120),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _livePrediction!.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$confidencePct%',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: _pickFromGallery,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(80), width: 2),
        ),
        child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                Colors.transparent,
                Colors.black.withAlpha(150),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0, left: 0,
                      child: _buildCorner(AppColors.primaryContainer, 0),
                    ),
                    Positioned(
                      top: 0, right: 0,
                      child: _buildCorner(AppColors.primaryContainer, 1),
                    ),
                    Positioned(
                      bottom: 0, left: 0,
                      child: _buildCorner(AppColors.primaryContainer, 3),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: _buildCorner(AppColors.primaryContainer, 2),
                    ),
                    Center(
                      child: Container(
                        height: 2,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withAlpha(150),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.primaryContainer,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(Color color, int rotationIndex) {
    return RotatedBox(
      quarterTurns: rotationIndex,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: 4),
            left: BorderSide(color: color, width: 4),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
          ),
        ),
      ),
    );
  }
}
