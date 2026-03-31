# 📁 Структура проекта

> Последнее обновление: 2026-03-31

---

## Дерево директорий

```
spy/
├── lib/
│   ├── main.dart                  # Точка входа, MaterialApp, тема, Provider
│   ├── data/                      # Статические данные (локации, имена)
│   │   ├── locations_data.dart    # 10 групп × 10 локаций + роли для каждой
│   │   └── names_data.dart        # Генератор случайных имён (качество + существительное)
│   ├── models/                    # Модели данных
│   │   ├── game_session.dart      # Сессия игры: игроки, раунды, локации, шпион
│   │   └── player.dart            # Игрок: имя, очки, роль
│   ├── providers/                 # State management
│   │   └── game_provider.dart     # ChangeNotifier (пока пустой, заготовка)
│   ├── screens/                   # Экраны приложения
│   │   ├── main_menu_screen.dart          # Главное меню
│   │   ├── game_settings_screen.dart      # Настройки игры (игроки, время, раунды, локация)
│   │   ├── location_selection_screen.dart  # Выбор локации (группы / случайно)
│   │   ├── pre_game_flow_screen.dart      # Предигровой поток (выбор имён, раздача карт)
│   │   ├── game_round_screen.dart         # Основной экран раунда (таймер, подсказки, ходы)
│   │   ├── voting_screen.dart             # Голосование за шпиона
│   │   ├── voting_result_screen.dart      # Результат голосования
│   │   ├── spy_last_word_screen.dart      # Последнее слово шпиона (угадай локацию)
│   │   ├── role_guess_screen.dart         # Мини-игра "Угадай роль"
│   │   ├── round_score_screen.dart        # Результаты раунда / финальный рейтинг
│   │   ├── rules_screen.dart              # Правила игры
│   │   └── settings_screen.dart           # Настройки приложения (звук, dev-режим)
│   ├── services/                  # Сервисы
│   │   └── storage_service.dart   # JSON-персистентность: локации, подсказки, статистика
│   ├── utils/                     # Утилиты и константы
│   │   ├── app_images.dart        # Централизованные пути к изображениям
│   │   ├── app_settings.dart      # In-memory настройки (звук, dev-режим)
│   │   ├── app_strings.dart       # Все строки UI (русский язык)
│   │   ├── app_styles.dart        # Декорации фонов (BoxDecoration)
│   │   ├── game_rules.dart        # Константы правил: очки, штрафы, лимиты
│   │   ├── game_sounds.dart       # Пути к аудиофайлам
│   │   └── sound_service.dart     # Singleton для проигрывания звуков
│   └── widgets/                   # Переиспользуемые виджеты
│       ├── camera_overlay.dart     # Оверлей захвата фото с овальной рамкой
│       ├── exit_game_button.dart   # Кнопка выхода с подтверждением
│       ├── game_card.dart          # Анимированная карточка (flip-эффект)
│       ├── menu_button.dart        # Кнопка меню (primary / outlined)
│       ├── number_selector.dart    # ±-селектор числа
│       └── settings_button.dart    # Большая квадратная кнопка настройки
├── assets/
│   ├── audio/                     # Звуковые файлы (.wav)
│   ├── data/                      # JSON-данные (locations_stats, universal_hints)
│   └── images/                    # Фоновые изображения, иконка
├── pubspec.yaml                   # Зависимости и ассеты
└── memory_bank/                   # 📖 Документация проекта (вы тут)
```

---

## Ключевые файлы — краткое описание

### `lib/main.dart`
- Инициализация `StorageService` (async)
- `MultiProvider` с `GameProvider`
- Тема: синяя, Material3
- Стартовый экран: `MainMenuScreen`

### `lib/models/game_session.dart`
- Хранит: список игроков, кол-во раундов, текущий раунд, время игры
- `secretLocationsQueue` — предвычисленный список локаций на все раунды
- Методы: `assignRoles()`, `addScoreToSpy()`, `addScoreToCivilians()`

### `lib/models/player.dart`
- Поля: `name`, `totalScore`, `roundScore`, `role` (nullable — null для шпиона)

### `lib/services/storage_service.dart`
- Глобальный синглтон `storageService`
- Работает с `locations_stats.json` и `universal_hints.json`
- Алгоритм «умного» выбора локаций (max-gap = 2)
- Round-robin для универсальных подсказок

### `lib/data/locations_data.dart`
- 10 тематических групп по 10 локаций = 100 локаций
- Для каждой локации — список из 10 ролей

---

## Зависимости (pubspec.yaml)

| Пакет | Назначение |
|---|---|
| `provider` ^6.1.1 | State management |
| `uuid` ^4.5.3 | Генерация уникальных ID сессий |
| `audioplayers` ^6.5.1 | Звуковые эффекты |
| `path_provider` ^2.1.2 | Путь к документам для JSON-хранилища |
| `cupertino_icons` ^1.0.8 | iOS-стиль иконок |
| `image_picker` ^1.2.1 | Захват фото игроков (Web/Mobile) |
| `http` ^1.6.0 | Запросы к AI Webhook (n8n) |
