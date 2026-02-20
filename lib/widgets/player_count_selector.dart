import 'package:flutter/material.dart';

class PlayerCountSelector extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  const PlayerCountSelector({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<PlayerCountSelector> createState() => _PlayerCountSelectorState();
}

class _PlayerCountSelectorState extends State<PlayerCountSelector> {
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    // Validate initial value to be within 3-6 range, default to 3 if null/out of range
    _currentValue = (widget.initialValue < 3 || widget.initialValue > 6) ? 3 : widget.initialValue;
  }

  void _decrement() {
    if (_currentValue > 3) {
      setState(() {
        _currentValue--;
      });
      widget.onChanged(_currentValue);
    }
  }

  void _increment() {
    if (_currentValue < 6) {
      setState(() {
        _currentValue++;
      });
      widget.onChanged(_currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Consume tap to prevent closing the menu
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _currentValue > 3 ? _decrement : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 32),
                  color: Colors.blue.shade900,
                ),
                Text(
                  '$_currentValue',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                IconButton(
                  onPressed: _currentValue < 6 ? _increment : null,
                  icon: const Icon(Icons.add_circle_outline, size: 32),
                  color: Colors.blue.shade900,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
