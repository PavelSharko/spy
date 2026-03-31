import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';

/// A full-screen overlay that shows a camera preview area with an oval face frame.
/// Uses [ImagePicker] for cross-platform (Web/Mobile) camera access.
class CameraOverlay extends StatefulWidget {
  /// Called with the captured JPEG bytes when a photo is taken.
  final ValueChanged<Uint8List> onPhotoCaptured;

  /// Player name to show as a label.
  final String playerName;

  const CameraOverlay({
    super.key,
    required this.onPhotoCaptured,
    required this.playerName,
  });

  @override
  State<CameraOverlay> createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;
  Uint8List? _previewBytes;

  Future<void> _takePhoto() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    SoundService.instance.playClick();

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (mounted) {
          setState(() {
            _previewBytes = bytes;
            _isCapturing = false;
          });
        }
      } else {
        if (mounted) setState(() => _isCapturing = false);
      }
    } catch (e) {
      debugPrint('[CameraOverlay] camera error: $e');
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _confirmPhoto() {
    if (_previewBytes != null) {
      SoundService.instance.playClick();
      widget.onPhotoCaptured(_previewBytes!);
    }
  }

  void _retakePhoto() {
    SoundService.instance.playClick();
    setState(() => _previewBytes = null);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      key: const ValueKey('cameraOverlay'),
      children: [
        const SizedBox(height: 20),

        // Title
        Text(
          widget.playerName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppStyles.darkAccent,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Сделай фото мордахи 📸',
          style: TextStyle(
            fontSize: 16,
            color: AppStyles.textSecondary,
          ),
        ),

        const SizedBox(height: 20),

        // Camera frame area with oval
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: size.width * 0.10,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background / preview
                      if (_previewBytes != null)
                        Image.memory(_previewBytes!, fit: BoxFit.cover)
                      else
                        Container(
                          color: AppStyles.darkAccent.withValues(alpha: 0.08),
                          child: const Center(
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 80,
                              color: AppStyles.textSecondary,
                            ),
                          ),
                        ),

                      // Oval overlay frame
                      CustomPaint(
                        painter: _OvalFramePainter(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: _previewBytes != null
              ? Row(
                  children: [
                    // Retake
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _retakePhoto,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Ещё раз'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.cardBg,
                          foregroundColor: AppStyles.darkAccent,
                          side: const BorderSide(color: AppStyles.accent, width: 2),
                          minimumSize: const Size(0, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Confirm
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmPhoto,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Ок!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.accent,
                          foregroundColor: AppStyles.cardBg,
                          side: const BorderSide(color: AppStyles.darkAccent, width: 2),
                          minimumSize: const Size(0, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ],
                )
              : // Capture button only (no skip)
                ElevatedButton.icon(
                  onPressed: _isCapturing ? null : _takePhoto,
                  icon: _isCapturing
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.camera_alt_rounded),
                  label: Text(_isCapturing ? 'Открываем камеру...' : 'Сфоткать мордаху'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.accent,
                    foregroundColor: AppStyles.cardBg,
                    side: const BorderSide(color: AppStyles.darkAccent, width: 2),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

/// Draws a semi-transparent overlay with an oval cutout in the center,
/// simulating a face-frame guide.
class _OvalFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.35);

    // Full rectangle
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Oval cutout — 15% top/bottom inset, 10% left/right inset
    final ovalRect = Rect.fromLTRB(
      size.width * 0.10,
      size.height * 0.15,
      size.width * 0.90,
      size.height * 0.85,
    );

    // Draw full overlay, then subtract the oval
    final path = Path()
      ..addRect(fullRect)
      ..addOval(ovalRect);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw oval border
    final borderPaint = Paint()
      ..color = AppStyles.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

