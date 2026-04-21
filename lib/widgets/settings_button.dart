import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';

class SettingsButton extends StatelessWidget {
  final String title;
  final String? value;
  final VoidCallback onPressed;
  final double? height;

  const SettingsButton({
    super.key,
    required this.title,
    this.value, // Can be null, will use placeholder
    required this.onPressed,
    this.height, // Default fluid height handled by caller or fallback
  });

  @override
  Widget build(BuildContext context) {
    // Default placeholder style
    final String displayValue = value ?? '--не выбрано--';

    return SizedBox(
      width: double.infinity,
      height: height ?? 80, // Fallback if no height provided
      // Use ElevatedButton for interaction but customize shape
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
            side: const BorderSide(
              color: Colors.transparent,
              width: 3,
            ), // Pattern outline
          ),
          backgroundColor: AppStyles.accent, // Warm brown
          foregroundColor: AppStyles.settings_game_text_colors, // Text color
          elevation: 6,
        ),
        onPressed: () {
          SoundService.instance.playClick();
          onPressed();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    displayValue,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppStyles.settings_game_text_colors.withValues(
                        alpha: 0.8,
                      ),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
