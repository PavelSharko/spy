import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';

// Top-level function for isolate
Uint8List _processImage(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final widthPct = args['widthPct'] as double; // 0.8
  final heightPct = args['heightPct'] as double; // 0.7

  img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes; // fallback

  // The image comes from the camera. Ensure correct orientation.
  decoded = img.bakeOrientation(decoded);

  // We want to crop to the center 3:4 aspect ratio first to match the UI preview
  // UI aspect ratio is 3/4 = width/height
  final double targetRatio = 3.0 / 4.0;
  final double currentRatio = decoded.width / decoded.height;

  int cropX = 0;
  int cropY = 0;
  int cropW = decoded.width;
  int cropH = decoded.height;

  if (currentRatio > targetRatio) {
    // Current is wider, crop width
    cropW = (decoded.height * targetRatio).round();
    cropX = (decoded.width - cropW) ~/ 2;
  } else if (currentRatio < targetRatio) {
    // Current is taller, crop height
    cropH = (decoded.width / targetRatio).round();
    cropY = (decoded.height - cropH) ~/ 2;
  }

  img.Image centerCropped = img.copyCrop(decoded, x: cropX, y: cropY, width: cropW, height: cropH);

  // We must ensure the image has an alpha channel to support transparency
  if (!centerCropped.hasAlpha) {
    centerCropped = centerCropped.convert(numChannels: 4);
  }

  // Draw transparent outside the oval.
  // The oval is centered.
  // Ellipse equation: (x - cx)^2 / rx^2 + (y - cy)^2 / ry^2 <= 1
  final double cx = centerCropped.width / 2;
  final double cy = centerCropped.height / 2;
  final double rx = (centerCropped.width * widthPct) / 2;
  final double ry = (centerCropped.height * heightPct) / 2;

  final transparentColor = img.ColorRgba8(0, 0, 0, 0);

  for (int y = 0; y < centerCropped.height; y++) {
    for (int x = 0; x < centerCropped.width; x++) {
      final double dx = x - cx;
      final double dy = y - cy;
      if ((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) > 1.0) {
        centerCropped.setPixel(x, y, transparentColor);
      }
    }
  }

  return img.encodePng(centerCropped);
}

/// A full-screen overlay that shows a native camera preview area with an oval face frame.
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
  CameraController? _controller;
  bool _isCapturing = false;
  bool _isProcessing = false;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[CameraOverlay] init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_isCapturing || _isProcessing || _controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isCapturing = true);
    SoundService.instance.playClick();

    try {
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();
      
      setState(() {
        _isCapturing = false;
        _isProcessing = true;
      });

      // Process in isolate to avoid freezing UI
      final processedBytes = await compute(_processImage, {
        'bytes': bytes,
        'widthPct': 0.8,
        'heightPct': 0.7,
      });

      if (mounted) {
        setState(() {
          _previewBytes = processedBytes;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('[CameraOverlay] camera error: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isProcessing = false;
        });
      }
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
        SizedBox(height: 20),

        // Title
        Text(
          widget.playerName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppStyles.accent,
            letterSpacing: 1.5,
          ),
        ),

        SizedBox(height: 8),

        Text(
          'Сделай фото мордахи 📸',
          style: TextStyle(fontSize: 16, color: AppStyles.textSecondary),
        ),

        SizedBox(height: 20),

        // Camera frame area with oval
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background / preview
                      if (_previewBytes != null)
                        Image.memory(_previewBytes!, fit: BoxFit.contain)
                      else if (_controller != null && _controller!.value.isInitialized)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: 100,
                            height: 100 * _controller!.value.aspectRatio,
                            child: CameraPreview(_controller!),
                          ),
                        )
                      else
                        Container(
                          color: AppStyles.darkAccent.withValues(alpha: 0.08),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      // Oval overlay frame
                      if (_previewBytes == null)
                        CustomPaint(painter: _OvalFramePainter()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 20),

        // Action buttons
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: _previewBytes != null
              ? Row(
                  children: [
                    // Retake
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _retakePhoto,
                        icon: Icon(Icons.replay_rounded),
                        label: Text('Ещё раз'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.cardBg,
                          foregroundColor: Colors.white,
                          side: BorderSide(color: AppStyles.accent, width: 2),
                          minimumSize: const Size(0, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    // Confirm
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmPhoto,
                        icon: Icon(Icons.check_rounded),
                        label: Text('Ок!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.accent,
                          foregroundColor: AppStyles.cardBg,
                          side: BorderSide(
                            color: AppStyles.darkAccent,
                            width: 2,
                          ),
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
              : ElevatedButton.icon(
                  onPressed: (_isCapturing || _isProcessing) ? null : _takePhoto,
                  icon: (_isCapturing || _isProcessing)
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.camera_alt_rounded),
                  label: Text(
                    _isProcessing ? 'Обработка...' : (_isCapturing ? 'Снимаем...' : 'Сфоткать мордаху'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.accent,
                    foregroundColor: AppStyles.cardBg,
                    side: BorderSide(color: AppStyles.darkAccent, width: 2),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                ),
        ),

        SizedBox(height: 20),
      ],
    );
  }
}

/// Draws a semi-transparent overlay with an oval cutout in the center,
/// simulating a face-frame guide.
class _OvalFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.45);

    // Full rectangle
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Oval cutout — 15% top/bottom inset, 10% left/right inset
    // This defines 80% width and 70% height
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
