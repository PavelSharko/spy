import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для вибрации HapticFeedback
import 'dart:math' as math;
import '../utils/app_styles.dart';

class EpicPlayerCard extends StatefulWidget {
  final String topName;
  final String bottomName;
  final VoidCallback? onAnimationEnd;

  const EpicPlayerCard({
    Key? key,
    required this.topName,
    required this.bottomName,
    this.onAnimationEnd,
  }) : super(key: key);

  @override
  State<EpicPlayerCard> createState() => EpicPlayerCardState();
}

class EpicPlayerCardState extends State<EpicPlayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Храним старые и новые имена для перехода
  String _currentTop = "";
  String _currentBottom = "";
  String _nextTop = "";
  String _nextBottom = "";

  // Переменная для рандомного наклона при каждом ударе
  double _randomTiltZ = 0.0;

  @override
  void initState() {
    super.initState();
    _currentTop = widget.topName;
    _currentBottom = widget.bottomName;
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // Чуть дольше для отработки дрожания
    );
  }

  // Вызывай этот метод извне, передавая новые имена!
  void flipToNewPlayers(String newTop, String newBottom) {
    setState(() {
      _nextTop = newTop;
      _nextBottom = newBottom;
      // Генерируем случайный крен от -15 до +15 градусов
      _randomTiltZ = (math.Random().nextDouble() - 0.5) * 0.5;
    });
    
    // Легкая вибрация при "ударе" снизу
    HapticFeedback.heavyImpact();

    _controller.forward(from: 0.0).then((_) {
      _currentTop = _nextTop;
      _currentBottom = _nextBottom;
      if (widget.onAnimationEnd != null) widget.onAnimationEnd!();
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
        
        double yOffset = 0.0;
        double angleX = 0.0;
        double tiltZ = 0.0;
        double shadowSpread = 0.0;
        double glowIntensity = 0.0;

        // ФАЗА 1: Полет (от 0 до 0.7)
        if (t < 0.7) {
          final flightProgress = t / 0.7; // Нормализуем от 0 до 1
          
          // Подлет по параболе (вверх и вниз)
          yOffset = -80.0 * math.sin(flightProgress * math.pi);
          // Сальто на 180 градусов
          angleX = flightProgress * math.pi;
          // Рандомный крен максимален в верхней точке
          tiltZ = _randomTiltZ * math.sin(flightProgress * math.pi);
          // Тень и подсветка становятся больше, когда объект высоко
          shadowSpread = 15.0 * math.sin(flightProgress * math.pi);
          glowIntensity = math.sin(flightProgress * math.pi);
          
          // Вибрация при падении (когда фаза полета заканчивается)
          if (t > 0.68 && t < 0.7) HapticFeedback.mediumImpact();
        } 
        // ФАЗА 2: Приземление и дрожание (от 0.7 до 1.0)
        else {
          final wobbleProgress = (t - 0.7) / 0.3; // Нормализуем от 0 до 1
          final decay = 1.0 - wobbleProgress; // Затухание
          
          yOffset = 0.0;
          tiltZ = 0.0;
          shadowSpread = 0.0;
          glowIntensity = 0.0;
          // Затухающая синусоида (бряканье об стол)
          angleX = math.pi + (math.sin(wobbleProgress * math.pi * 3) * 0.15 * decay);
        }

        // Если угол больше 90 градусов (pi/2), мы смотрим на обратную сторону
        final isFront = angleX < (math.pi / 2);
        
        final glowColor = AppStyles.textBright;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // Глубина 3D пространства
            ..translate(0.0, yOffset, 0.0) // Подскок
            ..rotateZ(tiltZ) // Рандомный перекос
            ..rotateX(angleX), // Основное сальто
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppStyles.cardBg, // Используем цвет из темы
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: glowColor.withOpacity(0.3 + (0.7 * glowIntensity)),
                width: 1.5 + (1.5 * glowIntensity),
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.5 * glowIntensity),
                  blurRadius: 10 + shadowSpread,
                  spreadRadius: shadowSpread,
                  offset: Offset(0, 5 + shadowSpread), // Тень падает вниз
                ),
              ],
            ),
            // ОЧЕНЬ ВАЖНО: Так как карточка делает сальто по оси X (через голову),
            // контент на обратной стороне будет вверх ногами. 
            // Поэтому мы контент обратной стороны переворачиваем обратно.
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateX(isFront ? 0 : math.pi),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isFront ? _currentTop : _nextTop,
                        style: TextStyle(
                          color: AppStyles.accent, // Текст
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.arrow_downward, color: AppStyles.accent, size: 20),
                  const SizedBox(height: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isFront ? _currentBottom : _nextBottom,
                        style: TextStyle(
                          color: AppStyles.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
