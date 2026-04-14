# 🧠 MEMORY BANK — Spy Game

> **Главный хаб проекта.** Этот файл — оглавление «памяти». Детали живут в `memory_bank/`.

---

## 📋 Обзор проекта

| Параметр | Значение |
|---|---|
| **Название** | Spy Game (Шпион) |
| **Платформа** | Flutter (Android / iOS / Web / Desktop) |
| **Язык** | Dart |
| **State-management** | Provider (`ChangeNotifierProvider`) |
| **Хранение данных** | JSON-файлы через `StorageService` (path_provider) |
| **Звук** | `audioplayers` |
| **Версия** | 1.0.0+1 |

---

## 📂 База знаний (`memory_bank/`)

| Файл | Что внутри |
|---|---|
| [project_structure.md](memory_bank/project_structure.md) | Карта директорий и ключевых файлов |
| [code_patterns.md](memory_bank/code_patterns.md) | Паттерны кода: синглтоны, константные классы, навигация, стили |
| [design_system.md](memory_bank/design_system.md) | Новая концепция дизайна, цветовая палитра (primaryBg: #2c3e50, primaryAccent: #ebc462) |
| [business_logic.md](memory_bank/business_logic.md) | Бизнес-логика: раунды, роли, подсказки, голосование, очки |
| [agent_instructions.md](memory_bank/agent_instructions.md) | Протокол для AI-агентов: как читать, менять и обновлять память |
| [manager_protocol.md](memory_bank/manager_protocol.md) | Протокол для main_agent: оркестрация под-агентов, генерация промптов, декомпозиция |
| [app_environment.dart](lib/config/app_environment.dart) | Тестовые и Prod флаги окружения (например, включение секретных функций) |
| [visual_config.dart](lib/utils/visual_config.dart) | Визуальные константы: прозрачности, оверлеи — меняй здесь для быстрой кастомизации |

---

## 🛠 Установленные умные скиллы (MCP)

В папке `.agents/skills/` установлены специальные ресурсы для работы AI:
- `flutter-skill`: набор инструкций для работы с деревом виджетов Flutter, тестирования и взаимодействия агента с UI в режиме реального времени.
- `composio-mcp`: мощный инструмент для доступа агентов к интеграциям и внешним сервисам.

---

## 🤝 Очередь задач (`agent_tasks/`)

> Через этот каталог `main_agent` выдаёт задачи под-агентам. Агентам ничего копировать не нужно.

| Файл | Что внутри |
|---|---|
| [current_tasks.md](agent_tasks/current_tasks.md) | **Очередь** — активные задачи. Каждый агент читает свой раздел, выполняет, ставит ✅ и переносит промпт в архив |
| [old_prompts_ui_agent.md](agent_tasks/old_prompts_ui_agent.md) | Архив выполненных задач ui-agent |
| [old_prompts_code_agent.md](agent_tasks/old_prompts_code_agent.md) | Архив выполненных задач code-agent |
| [old_prompts_rules_agent.md](agent_tasks/old_prompts_rules_agent.md) | Архив выполненных задач rules-agent |

---

## 🧪 Тестирование

| Файл/Папка | Что внутри |
|---|---|
| [plan_for_tests.md](plan_for_tests.md) | Главный хаб и оглавление тест-кейсов (инструкции Playwright + Flutter Web) |
| `tests_bank/` | Папка с файлами тест-кейсов для каждой отдельной фичи |

---

## 🚀 Быстрый старт (для агентов)

### Как начать работу

### Если ты под-агент (ui-agent / code-agent / rules-agent)

1. **Прочитай этот файл** — пойми структуру проекта.
2. **Прочитай `memory_bank/agent_instructions.md`** — правила кода.
3. **Открой `agent_tasks/current_tasks.md`** — найди раздел со своим именем и выполни задачу.
4. **После выполнения:** отметь свой раздел как ✅ в `current_tasks.md` и перенеси промпт в архив `agent_tasks/old_prompts_<имя>.md`.
5. **Обнови память** — при необходимости дополни файлы в `memory_bank/`.

### Если ты main_agent

1. Прочитай этот файл, `memory_bank/manager_protocol.md`, `plan_for_tests.md`.
2. Разбей задачу на роли, составь промпты.
3. **Запиши промпты** в `agent_tasks/current_tasks.md` (каждый агент — свой раздел).
4. Скажи пользователю одну команду для запуска нужного агента.

### Частые задачи → где искать

| Задача | Файл(ы) в memory_bank |
|---|---|
| Добавить новый экран | `project_structure.md` → секция Screens, `code_patterns.md` → Навигация |
| Добавить новую локацию / роли | `project_structure.md` → Data, `business_logic.md` → Локации |
| Изменить систему очков / правила | `business_logic.md` → Scoring, `code_patterns.md` → Константы |
| Добавить звук | `code_patterns.md` → Звуковая система |
| Изменить UI-стили | `code_patterns.md` → Стилизация |
| Добавить новый виджет | `project_structure.md` → Widgets, `code_patterns.md` → Виджет-паттерны |
| Работа с хранилищем / JSON | `code_patterns.md` → StorageService |
| Понять игровой поток | `business_logic.md` → Игровой цикл |
| Изменить прозрачность картинки на карточке | `visual_config.dart` → `VisualConfig` |

---

## ⚠️ Главные правила

> **Под-агенты НЕ меняют `MEMORY_BANK.md` напрямую** — только дополняют файлы в `memory_bank/`. Этот файл трогают только при добавлении новых файлов.
>
> **Единственный источник правды** — файлы в репозитории (`memory_bank/`, `agent_tasks/`, `plan_for_tests.md`). Не полагайся на историю чата.
