import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';

class SettingsButton extends StatelessWidget {
  final String title;
  final String? value;
  final VoidCallback onPressed;
  final double size;

  const SettingsButton({
    super.key,
    required this.title,
    this.value, // Can be null, will use placeholder
    required this.onPressed,
    this.size = 150.0, // Default big size, close to square
  });

  @override
  Widget build(BuildContext context) {
    // Default placeholder style
    final String displayValue = value ?? '--не выбрано--';
    
    return Container(
      width: size,
      height: size,
      constraints: const BoxConstraints(minWidth: 150, minHeight: 150),
      // Use ElevatedButton for interaction but customize shape
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
            side: BorderSide(color: AppStyles.deriveStripeColor(AppStyles.accent), width: 3), // Pattern outline
          ),
          backgroundColor: AppStyles.accent, // Warm brown
          foregroundColor: Colors.white, // Text color
          elevation: 6,
        ),
        onPressed: () {
          SoundService.instance.playClick();
          onPressed();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20, // Slightly increased
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, // Slightly increased
                color: Colors.white.withValues(alpha: 0.8), // White, slightly transparent
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
