import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_images.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';
import '../utils/visual_config.dart';

class GameCard extends StatefulWidget {
  final bool isSpy;
  final String secretLocation;
  final String? role; // null for spy
  final Uint8List? bgImageBytes;
  final VoidCallback onCardTapped;

  const GameCard({
    super.key,
    required this.isSpy,
    required this.secretLocation,
    this.role,
    this.bgImageBytes,
    required this.onCardTapped,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Using Tween to go from 0 to pi (180 degrees)
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (!_isFront) {
      SoundService.instance.playCardFlip();
      _controller.forward();
      setState(() {
        _isFront = true;
      });
    } else {
      // If it's already front, tapping it triggers the parent callback (e.g., next player)
      widget.onCardTapped();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // Need to transform based on the animation value
            final angle = _animation.value;
            // Matrix4.identity() with setEntry creates perspective
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle);

            // If angle > pi/2 (90 degrees), we are showing the front, but it's mirrored
            // so we need another rotation to fix the mirror effect.
            bool isShowingFront = angle >= pi / 2;

            Widget cardFace = isShowingFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi), // Un-mirror the front
                    child: _buildFrontSide(),
                  )
                : _buildBackSide();

            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: cardFace,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    return AspectRatio(
      aspectRatio: 0.7,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppStyles.darkAccent,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage(AppImages.bgCardBack),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.darkAccent.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppStyles.cardBg.withValues(alpha: 0.5), width: 3),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 80, color: AppStyles.cardBg.withValues(alpha: 0.8)),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Text(
                    AppStrings.tapCardToView,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4
                        ..color = AppStyles.darkAccent,
                    ),
                  ),
                  const Text(
                    AppStrings.tapCardToView,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppStyles.cardBg,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildFrontSide() {
    final bool isSpy = widget.isSpy;
    return AspectRatio(
      aspectRatio: 0.7,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppStyles.darkAccent, // neutral dark base under the image
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppStyles.darkAccent.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppStyles.cardBg, width: 4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Opacity(
              opacity: VisualConfig.cardBgImageOpacity,
              child: widget.bgImageBytes != null
                  ? Image.memory(
                      widget.bgImageBytes!,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/рубашка_показа_роли.jpeg',
                      fit: BoxFit.cover,
                    ),
            ),
            // White overlay to soften the background image
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: VisualConfig.cardWhiteOverlayOpacity),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: isSpy ? _buildSpyContent() : _buildCivilianContent(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bottom hint text with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSpy ? 'Угадайте в какой вы локации!' : 'Попробуйте отгадать шпиона!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildSpyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search, size: 60, color: Colors.white),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'ТЫ ШПИОН!',
              textAlign: TextAlign.center,
              style: GoogleFonts.russoOne(
                fontSize: 42,
                letterSpacing: 2,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = Colors.black,
              ),
            ),
            Text(
              'ТЫ ШПИОН!',
              textAlign: TextAlign.center,
              style: GoogleFonts.russoOne(
                fontSize: 42,
                letterSpacing: 2,
                color: Colors.redAccent.shade400, // Bloody red
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCivilianContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ВЫ НАХОДИТЕСЬ:',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.secretLocation,
            textAlign: TextAlign.center,
            style: GoogleFonts.russoOne(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          if (widget.role != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white38, height: 1),
            ),
            const Text(
              'ВАША РОЛЬ:',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.role!,
              textAlign: TextAlign.center,
              style: GoogleFonts.russoOne(
                fontSize: 24,
                color: AppStyles.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DotsPatternPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double radius;

  DotsPatternPainter({
    required this.dotColor,
    this.spacing = 15.0,
    this.radius = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        double xOffset = (j / spacing % 2 == 1) ? spacing / 2 : 0;
        if (i + xOffset < size.width) {
          canvas.drawCircle(Offset(i + xOffset, j), radius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotsPatternPainter old) => old.dotColor != dotColor;
}
