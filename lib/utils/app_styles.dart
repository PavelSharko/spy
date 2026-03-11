import 'package:flutter/material.dart';
import 'app_images.dart';

class AppStyles {
  AppStyles._();

  /// Background image opacity (0.0 = fully transparent, 1.0 = fully visible).
  /// Adjust this value to make backgrounds lighter or darker.
  static const double backgroundOpacity = 0.4;

  /// Default background decoration for all screens.
  /// Uses the main background image with a fallback dark color.
  static BoxDecoration mainBackgroundDecoration = BoxDecoration(
    color: const Color(0xFF1A1A2E), // fallback while image loads
    image: DecorationImage(
      image: const AssetImage(AppImages.bgMain),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 1.0 - backgroundOpacity),
        BlendMode.darken,
      ),
    ),
  );

  /// Background decoration for the rules screen.
  static BoxDecoration rulesBackgroundDecoration = BoxDecoration(
    color: const Color(0xFF1A1A2E),
    image: DecorationImage(
      image: const AssetImage(AppImages.bgRules),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 1.0 - backgroundOpacity),
        BlendMode.darken,
      ),
    ),
  );
}
