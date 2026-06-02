# Future Animation Ideas & References

## 1. Cinematic Neon Portal (Effect 5 from Sandbox Experiment)

**Описание:** 
Эффект засасывания карточки в портал и выплевывания новой. Идеально подойдет для крутых уведомлений, конца раунда или выдачи бонусных карточек.

**Логика:**
- **Фаза 1 (Suck):** Текущий элемент быстро вращается по оси Z (спин) и уменьшается до 0 (Scale -> 0).
- **Фаза 2 (Portal):** На заднем фоне появляются 3 контейнера в форме круга (`BoxShape.circle`) с круговым градиентом (`SweepGradient`) на границах. Они вращаются в противоположные стороны и пульсируют в размерах.
- **Фаза 3 (Spit):** Цвет портала меняется (например, с фиолетового на золотой). Новый элемент "выстреливает" из центра с упругим отскоком (`Curves.elasticOut`).

**Готовый код реализации (Flutter):**

```dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class Effect5NeonPortal extends StatefulWidget {
  final String topName;
  final String bottomName;

  const Effect5NeonPortal({Key? key, required this.topName, required this.bottomName}) : super(key: key);

  @override
  Effect5NeonPortalState createState() => Effect5NeonPortalState();
}

class Effect5NeonPortalState extends State<Effect5NeonPortal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _currentTop = "";
  String _currentBottom = "";
  String _nextTop = "";
  String _nextBottom = "";

  @override
  void initState() {
    super.initState();
    _currentTop = widget.topName;
    _currentBottom = widget.bottomName;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  }

  void triggerFlip(String newTop, String newBottom) {
    setState(() {
      _nextTop = newTop;
      _nextBottom = newBottom;
    });
    _controller.forward(from: 0.0).then((_) {
      _currentTop = _nextTop;
      _currentBottom = _nextBottom;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        
        double card1Scale = 1.0;
        double card1Spin = 0.0;
        double portalScale = 0.0;
        double card2Scale = 0.0;
        bool isSpitPhase = t > 0.5;

        if (t < 0.4) {
          // Suck phase
          final p = Curves.easeInBack.transform(t / 0.4);
          card1Scale = 1.0 - p;
          card1Spin = p * math.pi * 6; // Spin fast
          portalScale = p;
        } else if (t >= 0.4 && t < 0.6) {
          // Portal phase, cards hidden
          card1Scale = 0.0;
          card2Scale = 0.0;
          portalScale = 1.0 + math.sin((t - 0.4) / 0.2 * math.pi) * 0.2; // pulse
        } else {
          // Spit phase
          final p = (t - 0.6) / 0.4;
          final elasticCurve = Curves.elasticOut.transform(p);
          card1Scale = 0.0;
          card2Scale = elasticCurve;
          portalScale = 1.0 - p;
        }

        final portalColor = isSpitPhase ? Colors.amberAccent : Colors.purpleAccent;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Portal Rings
            if (portalScale > 0)
              for (int i = 0; i < 3; i++)
                Transform.scale(
                  scale: portalScale * (1.0 - i * 0.2),
                  child: Transform.rotate(
                    angle: t * math.pi * 10 * (i % 2 == 0 ? 1 : -1),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 8.0 - i * 2,
                          color: portalColor.withOpacity(0.5 - i * 0.1),
                        ),
                        gradient: SweepGradient(
                          colors: [portalColor.withOpacity(0.0), portalColor],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

            // Old Card (Suck in)
            if (card1Scale > 0)
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..scale(card1Scale, card1Scale)
                  ..rotateZ(card1Spin),
                child: _buildCard(_currentTop, _currentBottom, Colors.purpleAccent),
              ),

            // New Card (Spit out)
            if (card2Scale > 0)
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..scale(card2Scale, card2Scale),
                child: _buildCard(_nextTop, _nextBottom, Colors.amberAccent),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCard(String top, String bottom, Color color) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(top, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Icon(Icons.compare_arrows, color: color),
          const SizedBox(height: 16),
          Text(bottom, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```
