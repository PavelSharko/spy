/// Centralized image asset paths.
/// All image references go through this class — no hardcoded strings in widgets.
class AppImages {
  AppImages._();

  static const String _basePath = 'assets/images';

  /// Background for the back side of game cards.
  static const String bgCardBack = '$_basePath/bg_card_back.jpeg';

  /// Background for the front side of game cards (Spy).
  static const String revealBgSpy = '$_basePath/card_reveal_bg_spy.jpeg';

  /// Background for the front side of game cards (Civilians fallback).
  static const String revealBgNotSpy = '$_basePath/card_reveal_bg_not_spy.jpeg';

  /// App icon / logo shown on the main menu.
  static const String appIcon = '$_basePath/app_icon.png';
}
