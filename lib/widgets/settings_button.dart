import 'package:flutter/material.dart';

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
            side: const BorderSide(color: Colors.white24, width: 1), // Subtle border
          ),
          backgroundColor: Colors.white.withOpacity(0.9), // Slightly transparent white or adjust based on theme
          foregroundColor: Colors.blue.shade900, // Text color
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5), // More opaque/grey for placeholder
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
