import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_strings.dart';

class GameCard extends StatefulWidget {
  final bool isSpy;
  final String secretLocation;
  final String? role; // null for spy
  final VoidCallback onCardTapped;

  const GameCard({
    super.key,
    required this.isSpy,
    required this.secretLocation,
    this.role,
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
    return Container(
      width: double.infinity,
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 80, color: Colors.blue.shade200),
              const SizedBox(height: 20),
              const Text(
                AppStrings.tapCardToView,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      width: double.infinity,
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: widget.isSpy ? Colors.red.shade800 : Colors.green.shade800,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isSpy) ...[
                const Text(
                  AppStrings.youAreSpy,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 30),
                const Icon(Icons.search, size: 60, color: Colors.white),
                const SizedBox(height: 30),
                const Text(
                  AppStrings.guessLocation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const Text(
                  AppStrings.locationLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  widget.secretLocation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.language, size: 50, color: Colors.white),
                const SizedBox(height: 20),
                if (widget.role != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white38, width: 1),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          AppStrings.roleLabel,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.role!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  AppStrings.guessSpy,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
