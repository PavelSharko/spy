import 'dart:math';
import 'package:flutter/material.dart';

/// Animated background with diagonal moving stripes pattern.
/// Wrap any screen content with this widget to get a dynamic background.
class AnimatedPatternBackground extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final Color stripeColor;
  final double stripeWidth;
  final double gapWidth;

  const AnimatedPatternBackground({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF87CEEB),
    this.stripeColor = const Color(0x205B9BD5), // darker blue at ~12% opacity
    this.stripeWidth = 18,
    this.gapWidth = 36,
  });

  @override
  State<AnimatedPatternBackground> createState() =>
      _AnimatedPatternBackgroundState();
}

class _AnimatedPatternBackgroundState extends State<AnimatedPatternBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(); // infinite loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _StripePainter(
            progress: _controller.value,
            stripeColor: widget.stripeColor,
            stripeWidth: widget.stripeWidth,
            gapWidth: widget.gapWidth,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _StripePainter extends CustomPainter {
  final double progress;
  final Color stripeColor;
  final double stripeWidth;
  final double gapWidth;

  _StripePainter({
    required this.progress,
    required this.stripeColor,
    required this.stripeWidth,
    required this.gapWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor
      ..style = PaintingStyle.fill;

    final step = stripeWidth + gapWidth;
    // Diagonal length — enough to cover the screen at 45°
    final diagonal = size.width + size.height;
    // Shift by one full step cycle per animation loop
    final offset = progress * step;

    canvas.save();
    // Rotate canvas 45° around top-left
    canvas.rotate(pi / 4);

    // Draw stripes across the full diagonal range
    for (double x = -diagonal + offset; x < diagonal; x += step) {
      canvas.drawRect(
        Rect.fromLTWH(x, -diagonal, stripeWidth, diagonal * 2),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
