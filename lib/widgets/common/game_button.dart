import 'package:flutter/material.dart';
import '../../utils/app_styles.dart';

enum GameButtonType { primary, secondary }

class GameButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final GameButtonType type;
  final double? width;
  final double? height;

  const GameButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = GameButtonType.primary,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Fluid Adaptive sizes
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Default to 65% of screen width, max 300, min 200
    final effectiveWidth = width ?? (screenWidth * 0.65).clamp(200.0, 300.0);
    // Default to ~7% of screen height, max 60, min 48
    final effectiveHeight = height ?? (screenHeight * 0.07).clamp(48.0, 60.0);

    // Text needs to scale down if it doesn't fit
    Widget buttonText = FittedBox(fit: BoxFit.scaleDown, child: Text(text));

    if (type == GameButtonType.primary) {
      return SizedBox(
        width: effectiveWidth,
        height: effectiveHeight,
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
          child: buttonText,
        ),
      );
    } else {
      return SizedBox(
        width: effectiveWidth,
        height: effectiveHeight,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppStyles.accent.withValues(alpha: 0.08),
            foregroundColor: AppStyles.accent,
            side: BorderSide(
              color: AppStyles.accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: AppStyles.buttonTextStyle.copyWith(fontSize: 17),
          ),
          child: buttonText,
        ),
      );
    }
  }
}
