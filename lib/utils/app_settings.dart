import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_environment.dart';

enum SubscriptionLevel { none, plus, ultra }

/// Global application settings (persistent across app restarts).
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  late SharedPreferences _prefs;

  /// Whether sound effects are enabled globally.
  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool value) {
    _soundEnabled = value;
    _prefs.setBool('soundEnabled', value);
  }

  /// Whether to generate unique cards based on location roles.
  bool _uniqueCardsEnabled = false;
  bool get uniqueCardsEnabled => _uniqueCardsEnabled;
  set uniqueCardsEnabled(bool value) {
    _uniqueCardsEnabled = value;
    _prefs.setBool('uniqueCardsEnabled', value);
  }

  /// Style of the generated cards.
  String _cardStyle = "не выбрано";
  String get cardStyle => _cardStyle;
  set cardStyle(String value) {
    _cardStyle = value;
    _prefs.setString('cardStyle', value);
  }

  /// Whether to include player faces on unique cards.
  bool _playerFacesEnabled = false;
  bool get playerFacesEnabled => _playerFacesEnabled;
  set playerFacesEnabled(bool value) {
    _playerFacesEnabled = value;
    _prefs.setBool('playerFacesEnabled', value);
  }

  /// Subscription levels for gating premium features.
  SubscriptionLevel _subscriptionLevel = SubscriptionLevel.none;
  SubscriptionLevel get subscriptionLevel => _subscriptionLevel;
  set subscriptionLevel(SubscriptionLevel value) {
    _subscriptionLevel = value;
    _prefs.setInt('subscriptionLevel', value.index);
  }

  /// Whether the user has at least PLUS subscription.
  bool get hasPlus =>
      AppEnvironment.bypassSubscriptionCheck ||
      _subscriptionLevel == SubscriptionLevel.plus ||
      _subscriptionLevel == SubscriptionLevel.ultra;

  /// Whether the user has ULTRA subscription.
  bool get hasUltra =>
      AppEnvironment.bypassSubscriptionCheck ||
      _subscriptionLevel == SubscriptionLevel.ultra;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _soundEnabled = _prefs.getBool('soundEnabled') ?? true;
    _uniqueCardsEnabled = _prefs.getBool('uniqueCardsEnabled') ?? false;
    _cardStyle = _prefs.getString('cardStyle') ?? "не выбрано";
    _playerFacesEnabled = _prefs.getBool('playerFacesEnabled') ?? false;
    _subscriptionLevel = SubscriptionLevel.values[
        _prefs.getInt('subscriptionLevel') ?? SubscriptionLevel.none.index];
  }
}
