# Design System: Sandy Cream & Warm Brown

## Общая Концепция
Игра использует теплую, землистую цветовую палитру, создающую ощущение старого засекреченного документа или ретро-устройства. Основной фон — песочно-кремовый, с эффектом "помех старого телевизора" (медленно движущиеся вверх горизонтальные линии). Акценты расставлены теплыми коричневыми оттенками.

## Централизованная Палитра (`AppStyles.dart`)

| Роль | Цвет | Назначение |
|---|---|---|
| `bgColor` | `#F5E6CC` (Sandy Cream) | Основной задний фон всех экранов |
| `accent` | `#6D4C41` (Warm Brown) | Основные кнопки, важные акценты, заголовки карточек |
| `darkAccent` | `#3E2723` (Deep Espresso) | Текст логотипа, обводки кнопок, жирный текст |
| `textSecondary`| `#8D6E63` (Lighter Brown) | Вторичный текст, мелкие подписи |
| `cardBg` | `#FFF8F0` (Warm White) | Фон для карточек, контейнеров и панелей |
| `scanLineColor`| `#22C4A87A` (Dark Sand 13%) | Цвет анимированных полос (ТВ-помехи) на кремовом фоне |

### Семантические Цвета
Оставлены для ситуаций, где цвет несет игровую смысловую нагрузку (таймеры, результаты):
- `success`: `#388E3C` (Зеленый) — Шпион найден, правильный ответ
- `danger`: `#C62828` (Красный) — Шпион не найден, ошибка, штрафное время
- `warning`: `#FFA000` (Оранжевый) — Подсказки, случайный выбор

## Ключевые Паттерны Имплементации

### 1. Анимированный Фон (TV Static)
Виджет `AnimatedPatternBackground` оборачивает основной контент **каждого** экрана (обычно сразу внутри `Scaffold` > `Container(color: ...)`).
- **По умолчанию:** Использует кремовый фон и песочные линии.
- **Для Семантических Экранов:** Если экран имеет зеленый или красный фон (например, `VotingResultScreen`), используется метод `AppStyles.deriveStripeColor(bgColor)`, который автоматически генерирует цвет линий, чуть более темный, чем переданный фон.

```dart
// Стандартное использование
Container(
  color: AppStyles.bgColor,
  child: AnimatedPatternBackground(
    child: SafeArea( ... ),
  ),
)

// Использование с семантическим цветом
Container(
  color: AppStyles.danger,
  child: AnimatedPatternBackground(
    lineColor: AppStyles.deriveStripeColor(AppStyles.danger),
    child: SafeArea( ... ),
  ),
)
```

### 2. Типографика
- **Главный Шрифт Logo:** `Russo One` (используется на титульном экране благодаря отличной поддержке кириллицы и блочной, мультяшной стилистике). Основной текст в приложении использует системный шрифт.
- **Цвета Текста:** Избегайте использования `Colors.white` на кремовом фоне! Используйте `AppStyles.darkAccent` для заголовков и `AppStyles.textSecondary` для описаний. Белый текст (`Colors.white`) допустим только поверх темных кнопок (`AppStyles.accent`) или семантических фонов (красный/зеленый).

### 3. Карточки и Контейнеры
Для карточек, модальных окон и выделенных блоков используйте цвет `AppStyles.cardBg`. Он создает мягкий контраст с `AppStyles.bgColor`. Для обводки карточек можно применять `AppStyles.darkAccent.withOpacity(0.1)` (или `AppStyles.accent.withOpacity(0.2)`).

```dart
Container(
  decoration: BoxDecoration(
    color: AppStyles.cardBg,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: AppStyles.accent.withOpacity(0.2)),
  ),
  child: ...
)
```

### 4. Кнопки (`MenuButton` и другие)
- **Primary:** Фон `AppStyles.accent`, текст `AppStyles.cardBg`, обводка `AppStyles.darkAccent`.
- **Secondary (Outlined):** Фон прозрачный, текст `AppStyles.darkAccent`, обводка `AppStyles.accent`.
