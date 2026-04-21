import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get screenWidth => MediaQuery.sizeOf(this).width;

  // Использовать для стандартизированных вертикальных отступов сверху
  double get topPadding5 => screenHeight * 0.05;

  // Другие часто используемые отступы
  double get padding1 => screenHeight * 0.01;
  double get padding2 => screenHeight * 0.02;
  double get padding3 => screenHeight * 0.03;
  double get padding4 => screenHeight * 0.04;
  double get padding5 => screenHeight * 0.05;

  // Использовать для горизонтальных отступов по краям экрана
  double get horizontalMargin => screenWidth * 0.05;
}
