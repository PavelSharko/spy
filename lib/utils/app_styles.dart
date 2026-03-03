import 'package:flutter/material.dart';
import 'app_images.dart';

class AppStyles {
  AppStyles._();

  /// Default background decoration for all screens.
  /// Uses the main background image with a fallback dark color.
  static BoxDecoration mainBackgroundDecoration = BoxDecoration(
    color: const Color(0xFF1A1A2E), // fallback while image loads
    image: const DecorationImage(
      image: AssetImage(AppImages.bgMain),
      fit: BoxFit.cover,
    ),
  );

  /// Background decoration for the rules screen.
  static BoxDecoration rulesBackgroundDecoration = BoxDecoration(
    color: const Color(0xFF1A1A2E),
    image: const DecorationImage(
      image: AssetImage(AppImages.bgRules),
      fit: BoxFit.cover,
    ),
  );
}
