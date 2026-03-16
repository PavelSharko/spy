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
    
    return SizedBox(
      width: double.infinity,
      height: 80, // Horizontal fixed smaller height
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Flexible(
              child: Text(
                displayValue,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
