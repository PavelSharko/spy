import 'package:flutter/material.dart';
import '../../utils/app_styles.dart';

enum GameButtonType { primary, secondary }

class GameButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final GameButtonType type;
  final double width;
  final double height;

  const GameButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = GameButtonType.primary,
    this.width = 220,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (type == GameButtonType.primary) {
      return SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.accent,
            foregroundColor: AppStyles.primaryBg,
            side: BorderSide(color: AppStyles.darkAccent, width: 2.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: AppStyles.buttonTextStyle,
            elevation: 6,
          ),
          child: Text(text),
        ),
      );
    } else {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppStyles.accent.withValues(alpha: 0.08),
            foregroundColor: AppStyles.accent,
            side: BorderSide(color: AppStyles.accent.withValues(alpha: 0.5), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: AppStyles.buttonTextStyle.copyWith(fontSize: 17),
          ),
          child: Text(text),
        ),
      );
    }
  }
}
