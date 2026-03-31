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

---
## 🟠 code-agent | Ожидает выполнения

### Задача: Обновление настроек и Webhook payload для уникальных карточек
1. В файле `lib/utils/app_settings.dart` добавь новые поля:
   - `uniqueCardsEnabled` (bool, default `false`)
   - `cardStyle` (String, default `"как настоящее фото"`)
   - `playerFacesEnabled` (bool, default `false`)
2. **Персистентность**: Сейчас `AppSettings` хранит только в памяти. Тебе нужно переписать сервис для сохранения на всех платформах (iOS, Android, Web). Используй `shared_preferences`. Если пакета нет, добавь его в `pubspec.yaml` и сделай асинхронный метод загрузки `init()`.
3. В файле `lib/services/ai_generation_service.dart` обнови метод `fetchLocationImage`. Тебе потребуется актуализировать сигнатуру метода (и тех мест, где он вызывается, например `prefetchAllLocations`), чтобы передавать туда еще и список ролей для конкретной локации (ее можно взять из `locationsData` или получать как аргумент). Добавь в JSON `body` новые параметры:
   - `location`: текст локации
   - `roles`: массив строк с ролями игроков, которые уже определены для этой локации
   - `type_query`: `"gen_card_for_location"`
   - `generation_style`: Если `uniqueCardsEnabled` включено, передавай `cardStyle`, если нет — дефолтно передавай `"как настоящее фото"`.
   - `need_add_faces`: Если `uniqueCardsEnabled` включено, передавай `playerFacesEnabled`, иначе `false`.
4. В ответе отчитайся о том, как ты реализовал сохранение и покажи, какой именно JSON `body` полетит на вебхук.



---
## 🟠 code-agent | Ожидает выполнения

### Задача: Исправление логики Webhook и условий отправки
1. **Условие отправки**: В `lib/services/ai_generation_service.dart` в методе `fetchLocationImage` (и `prefetchAllLocations`) добавь проверку: если `AppSettings.instance.uniqueCardsEnabled` выключен (`false`), метод должен немедленно возвращать `null` и НЕ делать никаких HTTP-запросов. Генерация должна работать **только** если опция включена.
2. **Исправление Payload**: Убедись, что параметр `need_add_faces` передается в JSON только на основе `AppSettings.instance.playerFacesEnabled`, но так как теперь сам запрос летит только при включенных уникальных карточках, это значение всегда будет актуальным.
3. **Обновление вызовов**: Проверь, что в `prefetchAllLocations` логика также не запускает параллельные запросы, если настройка выключена.



---
## 🟠 ЭТАП 1: code-agent (Логика, Хранение и Вебхуки)

### Цель: Реализовать фоновую генерацию двух типов финальных карточек (Spy Win / Spy Loss) с фото игроков.

1. **Модель игрока**: В `lib/models/player.dart` добавь поле `Uint8List? photoBytes`.
2. **Новый метод генерации**: В `AiGenerationService` добавь метод `fetchEndGameCards`.
   - Аргументы: `location`, `roles`, `List<Uint8List> playerPhotos`.
   - Метод должен делать **ДВА** асинхронных запроса на тот же URL:
     - **Запрос 1 (через 15 сек после старта раунда)**: `type_query`: `"gen_card_for_finish_round"`, `spy_is_win`: `true`, `photos`: `List<String>` (Base64).
     - **Запрос 2 (через 25 сек после старта раунда)**: Тот же тип запроса, но `spy_is_win`: `false`.
3. **Хранение в сессии**: В `lib/models/game_session.dart` добавь мапу для хранения этих "финальных" карточек: `Map<int, Map<String, Uint8List>> roundFinalCards`. Где ключ — номер раунда, значение — мапа с ключами `"win"` и `"loss"`.
4. **Запуск логики**: В `PreGameFlowScreen` (или там, где начинается раунд), как только все фото собраны, запусти этот процесс в фоне.
5. **Очистка**: Реализуй метод очистки фото при завершении всей игровой сессии.



---
## 🔵 code-agent | Статус: ✅ Выполнено — 2026-03-30

### Задача: Fetchendgamecards
*Промпт перенесён в agent_tasks/old_prompts_code_agent.md*


