import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../services/ml/classifier_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInit = false;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setupCameraController(_cameras[_selectedCameraIndex]);
      } else {
        debugPrint("No cameras found");
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    // Dispose dulu sebelum buat yang baru agar tidak 2 kamera terbuka sekaligus
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
        setState(() {
          _isInit = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialize error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // Hanya dispose saat paused (app benar-benar ke background)
    // inactive terlalu sering terpicu (navigasi, dialog, dll) dan tidak perlu dispose
    if (state == AppLifecycleState.paused) {
      if (mounted) setState(() => _isInit = false);
      await _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      if (!_isInit && _cameras.isNotEmpty) {
        await _setupCameraController(_cameras[_selectedCameraIndex]);
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile image = await _controller!.takePicture();
      _processImage(File(image.path));
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  void _processImage(File imageFile) async {
    // Coba crop gambar
    final File? cropped = await ImageUtils.cropImage(imageFile, context);
    if (cropped != null) {
      if (!mounted) return;
      
      // Munculkan Loading pop up agar user tahu proses sedang berjalan
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
        final classifier = ClassifierService();
        // Step 1: Initialize (akan mendownload model jika belum ada)
        await classifier.initialize();
        // Step 2: Classify
        final prediction = await classifier.classifyImage(cropped);
        debugPrint("=== PREDICTION RESULT: $prediction, label=${prediction?.label}, conf=${prediction?.confidence}");

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // Tutup layar Loading

        if (prediction != null) {
          context.push('/analysis', extra: {
            'image': cropped,
            'prediction': prediction,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to analyze the image.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // Tutup layar Loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error AI Processing: $e')),
        );
      }
    }
  }

  void _switchCamera() async {
    if (_cameras.length > 1) {
      setState(() {
        _isInit = false;
        _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      });
      await _setupCameraController(_cameras[_selectedCameraIndex]);
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
      setState(() {
        _flashMode = nextMode;
      });
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
      // Re-init otomatis jika kamera belum siap (misal kembali dari halaman lain)
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
          // Live Camera Stream
          Transform.scale(
            scale: scale < 1 ? 1 / scale : scale,
            child: Center(
              child: CameraPreview(_controller!),
            ),
          ),
          
          // Viewfinder UI Overlay
          const _ViewfinderOverlay(),

          // Top Bar (Close, Flash, Settings)
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

          // Bottom Controls (Gallery, Shutter, Switch)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Camera Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildShutterButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        // Semi-transparent background mask (simulated here with gradient edges)
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
              // Target Frame
              SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  children: [
                    // Top Left
                    Positioned(
                      top: 0, left: 0,
                      child: _buildCorner(AppColors.primaryContainer, 0),
                    ),
                    // Top Right
                    Positioned(
                      top: 0, right: 0,
                      child: _buildCorner(AppColors.primaryContainer, 1),
                    ),
                    // Bottom Left
                    Positioned(
                      bottom: 0, left: 0,
                      child: _buildCorner(AppColors.primaryContainer, 3),
                    ),
                    // Bottom Right
                    Positioned(
                      bottom: 0, right: 0,
                      child: _buildCorner(AppColors.primaryContainer, 2),
                    ),
                    // Scan line
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
    // 0: TL, 1: TR, 2: BR, 3: BL
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
