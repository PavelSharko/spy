import 'package:flutter/material.dart';

class AppStyles {
  static const BoxDecoration mainGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // blue.shade50, blue.shade100
    ),
  );
}
