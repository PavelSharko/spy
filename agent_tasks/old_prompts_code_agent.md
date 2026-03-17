# 📦 Архив выполненных задач — code-agent

> Сюда переносятся промпты из `agent_tasks/current_tasks.md` после выполнения.
> Порядок: новые сверху.

---

## ✅ Перенести Developer Features в DevConfig | 2026-03-17

Прочитай перед началом:
- `memory_bank/agent_instructions.md`
- `lib/utils/app_settings.dart`
- `lib/screens/settings_screen.dart` (строки с developer features toggle ~113-160)
- `lib/screens/game_round_screen.dart` (поиск `developerFeaturesEnabled`)

**Шаг 1: Создай `lib/utils/dev_config.dart`**

```dart
/// Developer / debug configuration.
/// Hardcoded flags — change here and restart the app.
class DevConfig {
  DevConfig._();

  /// Set to true to show developer tools in the Settings screen.
  static const bool developerFeaturesEnabled = false;
}
```

**Шаг 2: Обнови `lib/utils/app_settings.dart`**

Удали строки:
```dart
/// Whether secret developer features are enabled.
bool developerFeaturesEnabled = false;
```

**Шаг 3: Обнови `lib/screens/settings_screen.dart`**

- Добавь `import '../utils/dev_config.dart';`
- Оберни весь блок "Developer features toggle card" (строки ~113-165) в:
  ```dart
  if (DevConfig.developerFeaturesEnabled) ...[
    // существующий блок
  ],
  ```
  Если флаг false — блок не рендерится вообще.

**Шаг 4: Обнови `lib/screens/game_round_screen.dart`**

- Добавь `import '../utils/dev_config.dart';`
- Замени `AppSettings.instance.developerFeaturesEnabled` на `DevConfig.developerFeaturesEnabled`

**Шаг 5: После выполнения**
- Отметь этот раздел как ✅ Выполнено в этом файле.
- Перенеси полный текст промпта в `agent_tasks/old_prompts_code_agent.md`.


## ✅ Фикс отображения картинок с webhook (Dart:io → Uint8List) | 2026-03-17

Удалён `image_fetch_service.dart`. Создан `ai_generation_service.dart` — хранит байты картинки в `Uint8List` в ОЗУ (без `dart:io`), пробует основной URL → fallback URL методом `fetchLocationImage`. `GameSession.locationImages` изменён на `Map<String, Uint8List>`. `GameCard.bgImagePath` переименован в `bgImageBytes`, рендер через `Image.memory()`.

## ✅ Параллельный предзагруз картинок для всех локаций | 2026-03-17

Добавлен `_fetchWithRetry` (3 попытки на URL). `prefetchAllLocations` запускает все запросы параллельно через `Future.wait`. В `PreGameFlowScreen` добавлен `_isFirstImageLoading` и серый спиннер (28px, opacity 0.5) в верхнем левом углу во время `nameSelection`. Шпион всегда получает `bgImageBytes: null`.
