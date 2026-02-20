import 'package:flutter/material.dart';

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
              onPressed: onPressed,
              child: Text(text),
            )
          : OutlinedButton(
              onPressed: onPressed,
              // Maintain consistent outlined button style if not defined in theme globally
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              child: Text(text),
            ),
    );
  }
}
