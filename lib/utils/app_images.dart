/// Centralized image asset paths.
/// All image references go through this class — no hardcoded strings in widgets.
class AppImages {
  AppImages._();

  static const String _basePath = 'assets/images';

  /// Default background for all screens.
  static const String bgMain = '$_basePath/bg_main.png';

  /// Background for the rules screen.
  static const String bgRules = '$_basePath/bg_rules.png';

  /// Background for the back side of game cards.
  static const String bgCardBack = '$_basePath/bg_card_back.png';

  /// App icon / logo shown on the main menu.
  static const String appIcon = '$_basePath/app_icon.png';
}
