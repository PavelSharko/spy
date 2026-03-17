# 📦 Архив выполненных задач — ui-agent

> Сюда переносятся промпты из `agent_tasks/current_tasks.md` после выполнения.
> Порядок: новые сверху.

---

## ✅ Рефакторинг карточки игрока + файл визуальных настроек | 2026-03-17

Прочитай перед началом:
- `memory_bank/code_patterns.md`
- `lib/utils/app_styles.dart` (паттерн для констант стиля)
- `lib/widgets/game_card.dart` (метод _buildFrontSide — там вносишь изменения)

**Шаг 1: Создай `lib/utils/visual_config.dart`**

```dart
import 'package:flutter/material.dart';

/// Визуальные константы приложения.
/// Меняй здесь — результат сразу виден по всему проекту.
class VisualConfig {
  VisualConfig._();

  // ── Карточки игрока ──────────────────────────────────────────────────

  /// Непрозрачность картинки-рубашки на карточке.
  /// 0.0 = невидима, 1.0 = полностью видна.
  static const double cardBgImageOpacity = 0.8;

  /// Непрозрачность белого оверлея поверх картинки.
  /// Делает картинку менее яркой чтобы текст роли хорошо читался.
  static const double cardWhiteOverlayOpacity = 0.20;
}
```

**Шаг 2: Измени `lib/widgets/game_card.dart` — метод `_buildFrontSide`**

В `BoxDecoration`:
- УДАЛИ `gradient: LinearGradient(...)` (красный/зелёный фон).
- Вместо него поставь: `color: AppStyles.darkAccent,`

В Stack после `Opacity` с картинкой:
- УДАЛИ `Positioned.fill` с `DotsPatternPainter`.
- Добавь вместо него:
```dart
// White overlay to soften the background image
Positioned.fill(
  child: ColoredBox(
    color: Colors.white.withValues(alpha: VisualConfig.cardWhiteOverlayOpacity),
  ),
),
```

Замени хардкод `opacity: 0.5` на `VisualConfig.cardBgImageOpacity`.

Добавь `import '../utils/visual_config.dart';` вверху файла.

**Шаг 3: Обнови `memory_bank/code_patterns.md`**

Добавь секцию "Визуальные настройки":
- Все визуальные константы (прозрачности, оверлеи) → в `VisualConfig`.
- Цвета палитры → в `AppStyles`.
- Не хардкодить числа прозрачности в виджетах напрямую.

**Шаг 4: Обнови `MEMORY_BANK.md`**

В таблицу файлов добавь:
```
| Изменить прозрачность картинки на карточке | `lib/utils/visual_config.dart` → VisualConfig |
```

**Шаг 5: После выполнения**
- Отметь этот раздел как ✅ Выполнено в этом файле.
- Перенеси полный текст промпта в `agent_tasks/old_prompts_ui_agent.md`.


