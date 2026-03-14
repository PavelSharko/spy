import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../utils/sound_service.dart';

class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final double width;

  const MenuButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.width = 250,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: isPrimary
          ? ElevatedButton(
              onPressed: () {
                SoundService.instance.playClick();
                onPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.accent,
                foregroundColor: AppStyles.cardBg,
                side: const BorderSide(color: AppStyles.darkAccent, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: Text(text),
            )
          : OutlinedButton(
              onPressed: () {
                SoundService.instance.playClick();
                onPressed();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppStyles.darkAccent,
                side: const BorderSide(color: AppStyles.accent, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: Text(text),
            ),
    );
  }
}
