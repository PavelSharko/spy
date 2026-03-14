import 'package:flutter/material.dart';

/// Animated background with horizontal scan-lines moving upward,
/// like interference on an old CRT television.
///
/// Works with ANY background color — pass [backgroundColor] and [lineColor]
/// or let defaulting derive a slightly darker shade automatically.
class AnimatedPatternBackground extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final Color lineColor;
  final double lineHeight;
  final double gapHeight;

  const AnimatedPatternBackground({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFF5E6CC),
    this.lineColor = const Color(0x22C4A87A),
    this.lineHeight = 3,
    this.gapHeight = 12,
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
      duration: const Duration(seconds: 6),
    )..repeat();
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
          painter: _ScanLinePainter(
            progress: _controller.value,
            lineColor: widget.lineColor,
            lineHeight: widget.lineHeight,
            gapHeight: widget.gapHeight,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  final double lineHeight;
  final double gapHeight;

  _ScanLinePainter({
    required this.progress,
    required this.lineColor,
    required this.lineHeight,
    required this.gapHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final step = lineHeight + gapHeight;
    final offset = (1.0 - progress) * step;

    for (double y = -step + offset; y < size.height; y += step) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, lineHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
