import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/colors.dart';
import 'ai_detection_screen.dart';

class AiCameraScreen extends StatefulWidget {
  const AiCameraScreen({super.key});

  @override
  State<AiCameraScreen> createState() => _AiCameraScreenState();
}

class _AiCameraScreenState extends State<AiCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  String? _error;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  late final AnimationController _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = "No camera found on this device");
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Camera unavailable: $e");
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = !_isFlashOn;
    await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    setState(() => _isFlashOn = next);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      _goToAddIngredient(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Capture failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) _goToAddIngredient(picked.path);
  }

  Future<void> _goToAddIngredient(String imagePath) async {
    if (!mounted) return;
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiDetectionScreen(imagePath: imagePath),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPreview(),
            _buildScanOverlay(),
            _buildHintText(),
            _buildTopBar(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_error != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.scanGreen),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxWidth * controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanOverlay() {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            children: [
              const Align(
                alignment: Alignment.topLeft,
                child: _CornerBracket(isTop: true, isLeft: true),
              ),
              const Align(
                alignment: Alignment.topRight,
                child: _CornerBracket(isTop: true, isLeft: false),
              ),
              const Align(
                alignment: Alignment.bottomLeft,
                child: _CornerBracket(isTop: false, isLeft: true),
              ),
              const Align(
                alignment: Alignment.bottomRight,
                child: _CornerBracket(isTop: false, isLeft: false),
              ),
              AnimatedBuilder(
                animation: _scanAnim,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, -1 + 2 * _scanAnim.value),
                    child: Container(
                      height: 2,
                      width: 216,
                      decoration: BoxDecoration(
                        color: AppColors.scanGreen,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.scanGreen.withValues(alpha: 0.6),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintText() {
    return const Positioned(
      left: 24,
      right: 24,
      bottom: 150,
      child: Text(
        "Point at ingredients in good lighting",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 16,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleButton(icon: Icons.close, onTap: () => Navigator.pop(context)),
          _aiActivePill(),
          _circleButton(
            icon: Icons.auto_awesome,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("AI detection is always on while scanning")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _aiActivePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.scanGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "AI Active",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: const Color(0xFF0D0D0D),
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _roundIconButton(
              icon: Icons.photo_library_outlined,
              onTap: _pickFromGallery,
            ),
            GestureDetector(
              onTap: _capture,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkGreen, width: 4),
                  ),
                  child: _isCapturing
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                            color: AppColors.darkGreen,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: AppColors.darkGreen,
                          size: 28,
                        ),
                ),
              ),
            ),
            _roundIconButton(
              icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
              onTap: _toggleFlash,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerBracket({this.isTop = false, this.isLeft = false});

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.scanGreen, width: 4);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? side : BorderSide.none,
          bottom: !isTop ? side : BorderSide.none,
          left: isLeft ? side : BorderSide.none,
          right: !isLeft ? side : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: (isTop && isLeft) ? const Radius.circular(16) : Radius.zero,
          topRight: (isTop && !isLeft) ? const Radius.circular(16) : Radius.zero,
          bottomLeft: (!isTop && isLeft) ? const Radius.circular(16) : Radius.zero,
          bottomRight: (!isTop && !isLeft) ? const Radius.circular(16) : Radius.zero,
        ),
      ),
    );
  }
}
