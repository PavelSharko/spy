import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для вибрации HapticFeedback
import 'dart:math' as math;
import '../utils/app_styles.dart';
import '../utils/app_strings.dart';

class EpicVoterCard extends StatefulWidget {
  final String voterName;
  final VoidCallback? onAnimationEnd;

  const EpicVoterCard({
    Key? key,
    required this.voterName,
    this.onAnimationEnd,
  }) : super(key: key);

  @override
  State<EpicVoterCard> createState() => EpicVoterCardState();
}

class EpicVoterCardState extends State<EpicVoterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Храним старые и новые имена для перехода
  String _currentName = "";
  String _nextName = "";

  // Переменная для рандомного наклона при каждом ударе
  double _randomTiltZ = 0.0;

  @override
  void initState() {
    super.initState();
    _currentName = widget.voterName;
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // Чуть дольше для отработки дрожания
    );
  }

  // Вызывай этот метод извне, передавая новые имена!
  void flipToNewVoter(String newName) {
    setState(() {
      _nextName = newName;
      // Генерируем случайный крен от -15 до +15 градусов
      _randomTiltZ = (math.Random().nextDouble() - 0.5) * 0.5;
    });
    
    // Легкая вибрация при "ударе" снизу
    HapticFeedback.heavyImpact();

    _controller.forward(from: 0.0).then((_) {
      _currentName = _nextName;
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
        
        final glowColor = AppStyles.darkAccent;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // Глубина 3D пространства
            ..translate(0.0, yOffset, 0.0) // Подскок
            ..rotateZ(tiltZ) // Рандомный перекос
            ..rotateX(angleX), // Основное сальто
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: AppStyles.cardBg, // Используем цвет из темы
              borderRadius: BorderRadius.circular(15),
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
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateX(isFront ? 0 : math.pi),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.votingPlayerPrefix.trim(),
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.textBright,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isFront ? _currentName : _nextName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.textBright,
                      ),
                      textAlign: TextAlign.center,
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
