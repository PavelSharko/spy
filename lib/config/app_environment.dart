/// Конфигурация окружений игры (Environment).
///
/// Позволяет разделять продакшен и тестовые настройки.
/// Режим теста включается либо вручную изменением [isTestMode],
/// либо через аргумент компиляции/запуска: --dart-define=TEST_MODE=true
class AppEnvironment {
  AppEnvironment._();

  // Флаг тестового режима
  static const bool isTestMode = bool.fromEnvironment(
    'TEST_MODE',
    defaultValue: false,
  );

  /// Если TRUE, то проверка подписок полностью отключается (все функции доступны бесплатно)
  static const bool bypassSubscriptionCheck = false;

  // ==========================================
  // ТЕСТОВЫЕ НАСТРОЙКИ (Test Mode = true)
  // ==========================================
  static const Map<String, dynamic> _testConfig = {
    'showDeveloperFeatures': true,
  };

  // ==========================================
  // ПРОДАКШЕН НАСТРОЙКИ (Test Mode = false)
  // ==========================================
  static const Map<String, dynamic> _prodConfig = {
    'showDeveloperFeatures': false,
  };

  // ==========================================
  // АКТУАЛЬНЫЙ КОНФИГ
  // ==========================================
  static Map<String, dynamic> get _currentConfig =>
      isTestMode ? _testConfig : _prodConfig;

  // ==========================================
  // ГЕТТЕРЫ КОНКРЕТНЫХ ПАРАМЕТРОВ
  // ==========================================

  /// Показывать ли "Секретные функции" на экране настроек
  static bool get showDeveloperFeatures =>
      _currentConfig['showDeveloperFeatures'] as bool;
}
