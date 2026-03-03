/// Global application settings (in-memory, reset on app restart).
/// Extend this class with SharedPreferences persistence if needed.
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  /// Whether sound effects are enabled globally.
  bool soundEnabled = true;

  /// Whether secret developer features are enabled.
  bool developerFeaturesEnabled = false;
}
