import 'package:flutter/material.dart';

/// Centralized design system for the app.
/// All screens MUST use these colors for consistency.
class AppStyles {
  AppStyles._();

  // ── Color palette ───────────────────────────────────────────────────
  /// Основной фон экрана (тёмно-синий)
  static const Color primaryBg = Color(0xFF2C3E50);
  /// Главный акцентный цвет и основной цвет текста (теплый золотисто-желтый)
  static const Color primaryAccent = Color(0xFFEBC462);

  // ── Зависимые цвета (высчитаны с помощью Color.lerp) ──
  /// Фон для карточек и контейнеров (осветленный primaryBg)
  static Color get cardBg => Color.lerp(primaryBg, Colors.white, 0.08)!;
  /// Темный акцент для теней и нижних границ (затемненный primaryBg)
  static Color get darkAccent => Color.lerp(primaryBg, Colors.black, 0.35)!;
  /// Вторичный текст (полупрозрачный primaryAccent для приглушения)
  static Color get textSecondary => primaryAccent.withValues(alpha: 0.7);

  // Псевдонимы для совместимости и плавного перехода
  static Color get bgColor => primaryBg;
  static Color get accent => primaryAccent;

  // ── Semantic colors ──────────────────────────────────────────────────
  static const Color success = Color(0xFF388E3C); // green
  static const Color danger  = Color(0xFFC62828); // red
  static const Color warning = Color(0xFFFFA000); // amber/orange
}
