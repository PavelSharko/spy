import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_images.dart';
import '../utils/app_strings.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';

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

class _GameCardState extends State<GameCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _iconBlinkController;
  late Animation<double> _iconBlinkAnimation;
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

    _iconBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _iconBlinkAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(_iconBlinkController);
  }

  @override
  void dispose() {
    _iconBlinkController.dispose();
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
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppStyles.darkAccent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppStyles.darkAccent.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: AppStyles.cardBg.withValues(alpha: 0.5), width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17), // 20 - 3 (border width)
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image with opacity
              Opacity(
                opacity: AppStyles.cardBackBgImageOpacity,
                child: Image.asset(
                  AppImages.bgCardBack,
                  fit: BoxFit.cover,
                ),
              ),
              // White overlay
              if (AppStyles.cardBackWhiteOverlayOpacity > 0)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: AppStyles.cardBackWhiteOverlayOpacity),
                  ),
                ),
              // Content
              // Content
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40.0, left: 20, right: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.tapCardToView,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppStyles.cardBg,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 10),
                      FadeTransition(
                        opacity: _iconBlinkAnimation,
                        child: Icon(Icons.touch_app, size: 60, color: AppStyles.cardBg),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    final bool isSpy = widget.isSpy;
    return AspectRatio(
      aspectRatio: 0.7,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 20),
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
              opacity: AppStyles.cardBgImageOpacity,
              child: isSpy
                  ? Image.asset(AppImages.revealBgSpy, fit: BoxFit.cover)
                  : (widget.bgImageBytes != null
                      ? Image.memory(widget.bgImageBytes!, fit: BoxFit.cover)
                      : Image.asset(AppImages.revealBgNotSpy, fit: BoxFit.cover)),
            ),
            // White overlay to soften the background image
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: AppStyles.cardWhiteOverlayOpacity),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: isSpy
                        ? Center(child: _buildSpyContent())
                        : Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildCivilianContent(),
                          ),
                  ),
                  SizedBox(height: 10),
                  // Bottom hint text with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSpy ? 'Угадайте в какой вы локации!' : 'Попробуйте отгадать шпиона!',
                          style: TextStyle(
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ВЫ НАХОДИТЕСЬ:',
            style: TextStyle(color: AppStyles.cardBg, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            widget.secretLocation,
            textAlign: TextAlign.center,
            style: GoogleFonts.russoOne(
              fontSize: 28,
              color: AppStyles.cardBg,
            ),
          ),
          if (widget.role != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white38, height: 1),
            ),
            Text(
              'ВАША РОЛЬ:',
              style: TextStyle(color: AppStyles.cardBg, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.role!,
              textAlign: TextAlign.center,
              style: GoogleFonts.russoOne(
                fontSize: 32,
                color: AppStyles.cardBg,
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
