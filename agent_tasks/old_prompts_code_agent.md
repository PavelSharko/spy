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



---
## 🟠 code-agent | Статус: ⏳ Ожидает выполнения

### Задача: Централизация цветовой системы в AppStyles
1. **Обновление AppStyles**: В файле `lib/utils/app_styles.dart` очисти старые хардкод-константы. Сделай два главных корня для дизайна:
   - `static const Color primaryBg = Color(0xFF2C3E50);` (основной фон)
   - `static const Color primaryAccent = Color(0xFFEBC462);` (основной текст и акценты)
   Остальные цвета (например, `cardBg`, `darkAccent`, `textSecondary`) должны высчитываться как `getter`-ы на основе этих двух цветов (чуть светлее или темнее с помощью `HSLColor` или примешивания белого/черного). Если Flutter не позволит использовать геттеры с HSLColor там, где ожидается `const`, то вручную переведи жесткие цвета `(0xFF...)` в нужные HEX-оттенки `#2c3e50 / #ebc462`, но обязательно напиши к каждому цвету крутой **комментарий**, для чего он нужен (фон, текст, плашка) и от какого из двух главных цветов он произведен.
2. **Абстракция AnimatedPatternBackground**: В файле `lib/widgets/animated_pattern_background.dart` убери отрисовку горизонтальных полосок (`_ScanLinePainter`). Данный виджет не должен больше накладывать полосатый паттерн. Можно просто убрать `CustomPaint` и возвращать оттуда `child`.
3. **Глобальный поиск и замена**: Пройдись по всему коду командой поиска или вручную проанализируй основные экраны (Settings, PreGame, RoundScore и т.д.) и виджеты. Удали любые явные вызовы `Colors.white`, `Colors.black`, `Colors.grey`, `Color(0xFF...)` и направь их на новые переменные в `AppStyles`. Семантические (зеленый/красный для ошибок) оставь или переосмысли под новый стиль.
4. **Обновление Memory Bank**: В `memory_bank/design_system.md` задокументируй новую концепцию дизайна: два управляющих цвета `#2c3e50` и `#ebc462`, от которых идут все остальные зависимые цвета.
5. **Установка полезных скиллов**: Скачай и установи в папку `.agents/skills/` современные MCP-скиллы для Flutter, в частности `flutter-skill` (позволяет агентам "видеть" UI и тестировать без кода) и `composio-mcp`. Проверь их работоспособность и задокументируй их наличие в `MEMORY_BANK.md`, чтобы все агенты знали об этих новых возможностях.

**После выполнения:** отметь ✅ и перенеси промпт в `agent_tasks/old_prompts_code-agent.md`.



---
## 🟠 code-agent | Статус: ⏳ Ожидает выполнения

### Задача: Динамическая математика цветов и полное удаление старого мусора
1. **Динамический `AppStyles` без хардкода оттенков**: Пользователь хочет задавать только **ДВА** цвета (`primaryBg` и `primaryAccent`), а всё остальное должно считаться математикой на лету (getter-ами). 
   - Зайди в `lib/utils/app_styles.dart`. Оставь `const primaryBg = Color(0xFF2C3E50);` и `const primaryAccent = Color(0xFFEBC462);`.
   - Настрой динамические геттеры! Например, светлые оттенки делай через смешивание с белым `Color.lerp(primaryBg, Colors.white, 0.1)`, темные — `Color.lerp(primaryBg, Colors.black, 0.2)`. Текст делай через полупрозрачность `primaryAccent.withValues(alpha: 0.7)`.
   - Создай геттер `static Color get cardBg => Color.lerp(primaryBg, Colors.white, 0.05)!;`
   - Создай геттер `static Color get darkAccent => Color.lerp(primaryBg, Colors.black, 0.2)!;`
   - **САМОЕ ВАЖНОЕ:** Это сломает использование `const AppStyles.cardBg` в коде (например, в `BoxDecoration`). **ТВОЯ ЗАДАЧА — пройти по всем экранам и удалить слово `const` там, где компилятор начнет ругаться.** Не бойся убирать `const`, гибкость палитры сейчас важнее микрооптимизации.

2. **Тотальное удаление `AnimatedPatternBackground`**: Не просто делай цвет `scanLineColor` прозрачным. **Полностью удали файл** `lib/widgets/animated_pattern_background.dart`. Пройдись по всем 13+ экранам (`main_menu_screen.dart`, `rules_screen.dart`, `voting_screen.dart` и т.д.) и удали обертку `AnimatedPatternBackground()`, оставив только её `child`, либо заменив на `Container(color: AppStyles.primaryBg)`. Проверь, чтобы не осталось ни одного упоминания в импортах.

**После выполнения:** отметь ✅ и перенеси промпт в `agent_tasks/old_prompts_code-agent.md`.



---
## 🟠 code-agent | Статус: ⏳ Ожидает выполнения

### Задача: Компонентная база для экранов (Настройки игры)

Пользователь просит перевести экран "Настройки Игры" (`lib/screens/game_settings_screen.dart` или эквивалентный по значению экран перед раундом, где используется `AppStrings.gameSettingsTitle`) на переиспользуемые UI компоненты, чтобы в будущем весь дизайн в приложении можно было изменить, поправив лишь базовые виджеты, и чтобы сейчас экран настроек органично вписывался в стиль главного меню, но не был жестко привязан к нему. 

**Шаги:**
1. Ознакомься со стилем `lib/screens/main_menu_screen.dart`.
2. В папке `lib/widgets/common/` создай базовые переиспользуемые виджеты (если их нет):
   - `GameButton` (принимает текст, коллбэк, берет стили строго из `AppStyles`).
   - `GameScreenTitle` (для заголовков, чтобы "НАСТРОЙКИ ИГРЫ" и другие имели единый шрифт и размер).
   - Любые другие нужные обертки (например, для карточек).
3. Добавь в `lib/utils/app_styles.dart` нужные `get` для `TextStyle`, чтобы управлять шрифтами экранов из одной точки.
4. Вычисти хардкод.
5. Задокументируй добавленные виджеты в `memory_bank/project_structure.md`.

**После выполнения:** отметь ✅ и перенеси промпт в `agent_tasks/old_prompts_code-agent.md`. Обязательно вызови скрипт архивации.



---
## 🟠 code-agent | Статус: ⏳ Ожидает выполнения

### Задача: Новая переменная для текста настроек игры

Пользователь хочет выделить текст на странице настроек в отдельную цветовую переменную, чтобы в будущем ее было легко поменять независимо от других текстов. 

**Шаги:**
1. Открой `lib/utils/app_styles.dart`.
2. Создай новую геттер-переменную (или константу) `static Color get settings_game_text_colors`.
3. Присвой ей значение переменной `primaryBg` (то есть `Color(0xFF2C3E50)`). Напиши комментарий, что этот цвет используется специально для текстов внутри кнопок и менюшек на странице настроек игры.

**После выполнения:** отметь ✅ и перенеси промпт в `agent_tasks/old_prompts_code-agent.md`. Обязательно вызови скрипт архивации.



---
## 🟠 code-agent | Статус: ⏳ Ожидает выполнения

### Задача: Переменная цвета для кнопок выбора локации

Пользователь хочет выделить текст на кнопках в меню выбора локаций в отдельную переменную для гибкого управления дизайном в будущем.

**Шаги:**
1. Открой файл `lib/utils/app_styles.dart`.
2. Создай новый геттер (например, `static Color get location_menu_button_text_color`).
3. Присвой ему значение переменной `primaryAccent` (`Color(0xFFEBC462)`). 
4. Добавь комментарий, что данный цвет используется для текста кнопок в меню "Выбор локации", за исключением кнопки подтверждения.

**После выполнения:** отметь ✅ и перенеси промпт в `agent_tasks/old_prompts_code-agent.md`. Обязательно вызови скрипт архивации.


