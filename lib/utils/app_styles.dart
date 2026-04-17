import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static Color get textBright => HSLColor.fromColor(primaryAccent)
    .withLightness((HSLColor.fromColor(primaryAccent).lightness + 0.15).clamp(0.0, 1.0))
    .toColor();

  // Псевдонимы для совместимости и плавного перехода
  static Color get bgColor => primaryBg;
  static Color get accent => primaryAccent;

  /// Цвет для текстов внутри кнопок и менюшек на странице настроек игры
  static Color get settings_game_text_colors => primaryBg;

  /// Цвет текста на кнопках в меню "Выбор локации" (не применяется к кнопке подтверждения)
  static Color get location_menu_button_text_color => primaryAccent;

  // ── Semantic colors ──────────────────────────────────────────────────
  static const Color success = Color(0xFF388E3C); // green
  static const Color danger  = Color(0xFFC62828); // red
  static const Color warning = Color(0xFFFFA000); // amber/orange

  // ── Text Styles ──────────────────────────────────────────────────────
  static TextStyle get titleStyle => GoogleFonts.russoOne(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: darkAccent,
        letterSpacing: 3,
      );

  static TextStyle get buttonTextStyle => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      );

  // ── Card Visual Config ──────────────────────────────────────────────
  /// Непрозрачность картинки-рубашки на карточке (0.0 - 1.0).
  static const double cardBgImageOpacity = 0.99;
  
  /// Непрозрачность белого оверлея поверх картинки (0.0 - 1.0).
  static const double cardWhiteOverlayOpacity = 0.25;

  /// Непрозрачность фонового изображения рубашки карты (0.0 - 1.0).
  static const double cardBackBgImageOpacity = 0.99;
  
  /// Непрозрачность белого оверлея поверх картинки на рубашке карты (0.0 - 1.0).
  static const double cardBackWhiteOverlayOpacity = 0.55;
}

