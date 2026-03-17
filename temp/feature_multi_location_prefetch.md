# Feature: Multi-Location Image Prefetching

**Статус:** ✅ Выполнено code-agent

---

## Описание задачи
Реализовать параллельный предзагруз AI-картинок для всех локаций в игровой сессии, а не только для текущей. Каждая локация — один запрос. Результаты сохраняются в `session.locationImages` под ключом-именем локации, чтобы следующие раунды получали уже готовую картинку.

## Ключевые контракты (API для других агентов)

| Файл | Что меняется |
|---|---|
| `lib/services/ai_generation_service.dart` | Добавляется новый метод `prefetchAllLocations(List<String> locations, Map<String, Uint8List> cache, {VoidCallback? onFirstComplete})` |
| `lib/screens/pre_game_flow_screen.dart` | `_loadLocationImageIfNeeded()` → `_prefetchAllLocations()`, добавляется `bool _isFirstImageLoading` + индикатор |

## Ожидаемое поведение после реализации
- Все запросы запускаются **одновременно** из `initState`.
- Первый завершившийся запрос (только первая локация) убирает спиннер.
- Если картинка не пришла к моменту показа карточек — показывается дефолтная рубашка (штатное поведение).
- 3 ретрая на каждый запрос перед тем как признать генерацию неудача.

## Статус выполнения
- [x] code-agent выполнил задачу
- [ ] Ручное тестирование прошло

---

## Отчёт о реализации

### Изменённые файлы

| Файл | Что изменено |
|---|---|
| `lib/services/ai_generation_service.dart` | Добавлен `_fetchWithRetry` (3 попытки на URL), `fetchLocationImage` теперь использует его, добавлен `prefetchAllLocations` |
| `lib/screens/pre_game_flow_screen.dart` | `_loadLocationImageIfNeeded()` заменён на `_prefetchAllLocations()`, добавлен `_isFirstImageLoading`, спиннер в `_buildNameSelection`, шпион не получает `bgImageBytes` |

### Как работает параллельная загрузка
`prefetchAllLocations` вызывает `Future.wait(locations.map(...))` — все запросы стартуют одновременно. Каждый `async` колбэк самостоятельно записывает байты в `cache[location]` и при первой успешной записи вызывает `onFirstComplete`.

### Как работает спиннер
- `_isFirstImageLoading = true` устанавливается при инициализации стейта.
- `onFirstComplete` вызывает `setState(() => _isFirstImageLoading = false)` — спиннер пропадает.
- Спиннер отображается только на шаге `nameSelection` (вложен в `Stack` внутри `_buildNameSelection`). На `cardReveal` и `roundReady` его нет.

### Шпион и картинка
В `_buildCardReveal`: `bgImageBytes: isSpy ? null : session.locationImages[location]`. Шпион **всегда** видит дефолтную рубашку.

### Что нужно проверить при ручном тесте
1. Запускаем игру на 3+ раундов → в `initState` видим в логах N параллельных запросов (по числу уникальных локаций).
2. Маленький серый спиннер в верхнем левом углу появляется при вводе имён и исчезает после первого ответа webhook.
3. Карточки гражданских показывают кастомную картинку локации (при успешном ответе webhook).
4. Карточка шпиона **всегда** показывает дефолтную рубашку (`рубашка_показа_роли.jpeg`), даже если картинка для локации загружена.
5. Во 2-м и 3-м раундах картинки берутся из кэша мгновенно (без новых запросов).
