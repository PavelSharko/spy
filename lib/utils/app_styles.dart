import 'package:flutter/material.dart';

/// Centralized design system for the app.
/// All screens MUST use these colors for consistency.
class AppStyles {
  AppStyles._();

  // ── Color palette ───────────────────────────────────────────────────
  static const Color bgColor       = Color(0xFFF5E6CC); // sandy cream
  static const Color accent        = Color(0xFF6D4C41); // warm brown
  static const Color darkAccent    = Color(0xFF3E2723); // deep espresso
  static const Color textSecondary = Color(0xFF8D6E63); // lighter brown
  static const Color cardBg        = Color(0xFFFFF8F0); // warm white for cards
  static const Color scanLineColor = Color(0x22C4A87A); // pattern stripes

  // ── Semantic colors (kept as-is for game context) ──────────────────
  static const Color success = Color(0xFF388E3C); // green
  static const Color danger  = Color(0xFFC62828); // red
  static const Color warning = Color(0xFFFFA000); // amber/orange

  // ── Helpers ─────────────────────────────────────────────────────────
  /// Derive a slightly darker stripe color from any background color.
  /// Used for AnimatedPatternBackground on semantic-colored screens.
  static Color deriveStripeColor(Color bg) {
    final hsl = HSLColor.fromColor(bg);
    return hsl
        .withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.18);
  }
}
