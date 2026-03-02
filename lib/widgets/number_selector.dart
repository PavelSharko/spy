import 'package:flutter/material.dart';
import '../utils/sound_service.dart';

class NumberSelector extends StatefulWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const NumberSelector({
    super.key,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  State<NumberSelector> createState() => _NumberSelectorState();
}

class _NumberSelectorState extends State<NumberSelector> {
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _validateValue();
  }

  @override
  void didUpdateWidget(NumberSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the bounds or initial value have changed, we need to re-validate
    if (widget.initialValue != oldWidget.initialValue ||
        widget.minValue != oldWidget.minValue ||
        widget.maxValue != oldWidget.maxValue) {
      _currentValue = widget.initialValue;
      _validateValue();
    }
  }

  void _validateValue() {
    bool changed = false;
    if (_currentValue < widget.minValue) {
      _currentValue = widget.minValue;
      changed = true;
    } else if (_currentValue > widget.maxValue) {
      _currentValue = widget.maxValue;
      changed = true;
    }
    
    // We shouldn't call widget.onChanged here during build/init to avoid loops, 
    // the parent state already handles its bounds validation internally.
  }

  void _decrement() {
    if (_currentValue > widget.minValue) {
      SoundService.instance.playClick();
      setState(() {
        _currentValue--;
      });
      widget.onChanged(_currentValue);
    }
  }

  void _increment() {
    if (_currentValue < widget.maxValue) {
      SoundService.instance.playClick();
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
                  onPressed: _currentValue > widget.minValue ? _decrement : null,
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
                  onPressed: _currentValue < widget.maxValue ? _increment : null,
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
