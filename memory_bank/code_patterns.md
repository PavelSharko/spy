# 🧩 Паттерны кода

> Последнее обновление: 2026-03-10

---

## 1. Синглтоны (Global Singletons)

Проект активно использует глобальные синглтоны — **без** IoC / DI-контейнера.

| Класс | Способ | Где используется |
|---|---|---|
| `StorageService` | Глобальная переменная `final storageService = StorageService()` | Инициализация в `main()`, используется на экранах |
| `AppSettings` | `AppSettings._() + static final instance` | `SoundService`, `SettingsScreen` |
| `SoundService` | `SoundService._() + static final instance` | Все виджеты/экраны при нажатии кнопок |

**Паттерн нового синглтона:**
```dart
class MyService {
  MyService._();
  static final MyService instance = MyService._();
  // ...методы...
}
```

---

## 2. Константные классы (Static Registries)

Все константы, строки и пути вынесены в отдельные классы с **приватным конструктором** и `static const` полями.

| Класс | Файл | Назначение |
|---|---|---|
| `AppStrings` | `utils/app_strings.dart` | Все UI-строки на русском |
| `AppImages` | `utils/app_images.dart` | Пути к изображениям (`assets/images/...`) |
| `AppStyles` | `utils/app_styles.dart` | `BoxDecoration` для фонов экранов |
| `GameRules` | `utils/game_rules.dart` | Очки, штрафы, лимиты (min/max игроков, раундов) |
| `GameSounds` | `utils/game_sounds.dart` | Пути к аудиофайлам |
| `LocationsData` | `data/locations_data.dart` | Список локаций и ролей |
| `NamesData` | `data/names_data.dart` | Списки смешных имён и качеств |

**Паттерн:**
```dart
class AppXxx {
  AppXxx._(); // приватный конструктор — запрет на инстанцирование
  static const String someValue = '...';
}
```

> **Правило:** Никогда не хардкодь строки, пути к ассетам или числовые константы прямо в виджетах. Всегда добавляй в соответствующий registry-класс.

---

## 3. Навигация

| Действие | Как реализовано |
|---|---|
| Переход вперёд | `Navigator.push(context, MaterialPageRoute(builder: ...))` |
| Передача данных между экранами | Через конструктор экрана (например, `PreGameFlowScreen(session: session)`) |
| Возврат данных | `Navigator.pop(context, result)` + `await Navigator.push(...)` |
| Выход в главное меню | `Navigator.pushAndRemoveUntil(MainMenuScreen(), (route) => false)` |

> **Нет** именованных маршрутов. Все переходы — через `MaterialPageRoute`.

---

## 4. Стилизация экранов

Каждый экран оборачивается в `Container` с `BoxDecoration` из `AppStyles`:

```dart
Scaffold(
  extendBodyBehindAppBar: true,
  backgroundColor: Colors.transparent,
  body: Container(
    decoration: AppStyles.mainBackgroundDecoration,
    child: SafeArea(
      child: // ... содержимое экрана
    ),
  ),
)
```

- `AppStyles.mainBackgroundDecoration` — основной фон (image + darken filter)
- `AppStyles.rulesBackgroundDecoration` — фон для правил

**Фоновые картинки** загружаются через `AssetImage` с `colorFilter` для затемнения. Прозрачность задаётся через `AppStyles.backgroundOpacity`.

---

## 5. Звуковая система

### Добавить новый звук:

1. Положи `.wav` файл в `assets/audio/`
2. Зарегистрируй путь в `GameSounds`:
   ```dart
   static const String mySound = 'audio/my_sound.wav';
   ```
3. Используй через `AudioPlayer`:
   ```dart
   final player = AudioPlayer();
   await player.play(AssetSource(GameSounds.mySound));
   ```

### Звук нажатия кнопки:
```dart
SoundService.instance.playClick();
```
Вызывается **в каждом** `onPressed` до выполнения логики.

---

## 6. Хранение данных (StorageService)

### Архитектура
- **`assets/data/`** — исходные JSON-файлы (шаблоны)
- При **первом запуске** копируются в `Documents/` устройства
- Далее читаются/записываются из локальной копии
- На **Web** — всегда из ассетов (read-only)

### Файлы данных
| Файл | Содержимое |
|---|---|
| `locations_stats.json` | Счётчики выбора локаций + приватные подсказки |
| `universal_hints.json` | Универсальные подсказки (round-robin) |

### Алгоритм «умного» выбора локаций
- Считает `location_chosed_times` для каждой локации
- Кандидаты: `current_count <= min_count + 1` (max-gap = 2)
- Счётчики **никогда не сбрасываются**

---

## 7. Виджеты — соглашения

| Принцип | Описание |
|---|---|
| **Переиспользуемость** | Виджеты в `widgets/` не привязаны к конкретному экрану |
| **Callbacks** | Логика передаётся через `VoidCallback` / `ValueChanged<T>` |
| **Sound on tap** | Каждый виджет **сам** вызывает `SoundService.instance.playClick()` |
| **Composition** | Используется `Stack` с `Positioned` для overlay-элементов (ExitGameButton) |

### GameCard — анимация переворота
- `AnimationController` + `Tween<double>(0, π)`
- Матричная трансформация `Matrix4.rotationY(angle)`
- При `angle > π/2` — показывается лицевая сторона (с компенсацией зеркальности)

---

## 8. State Management

- **Provider** используется для `GameProvider` (пока пустой `ChangeNotifier`)
- Основной стейт передаётся **напрямую** через конструкторы экранов (`GameSession`)
- Локальное состояние — через `StatefulWidget` + `setState()`
- `GameSession` — мутабельный объект, передаваемый по ссылке через цепочку экранов

---

## 9. Именование файлов

| Тип | Конвенция | Пример |
|---|---|---|
| Экраны | `*_screen.dart` | `voting_screen.dart` |
| Виджеты | `*без суффикса*.dart` или описательное | `game_card.dart`, `exit_game_button.dart` |
| Утилиты | `app_*.dart` / `game_*.dart` / `sound_*.dart` | `app_strings.dart` |
| Модели | описательное | `player.dart`, `game_session.dart` |
| Данные | `*_data.dart` | `locations_data.dart` |

---

## 10. Добавление нового экрана — чеклист

1. Создай файл в `lib/screens/new_screen.dart`
2. Используй `AppStyles.mainBackgroundDecoration` для фона
3. Добавь `ExitGameButton` в `Stack` если экран — часть игрового потока
4. Все строки — в `AppStrings`
5. Все константы — в `GameRules`
6. Каждая кнопка — `SoundService.instance.playClick()` в `onPressed`
7. Навигация: `Navigator.push(context, MaterialPageRoute(...))`
8. Обнови `memory_bank/project_structure.md`
