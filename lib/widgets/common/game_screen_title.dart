import 'package:flutter/material.dart';
import '../../utils/app_styles.dart';

class GameScreenTitle extends StatelessWidget {
  final String title;

  const GameScreenTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outline layer
        Text(
          title,
          style: AppStyles.titleStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = AppStyles.darkAccent,
          ),
          textAlign: TextAlign.center,
        ),
        // Fill layer
        Text(
          title,
          style: AppStyles.titleStyle.copyWith(color: AppStyles.accent),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
