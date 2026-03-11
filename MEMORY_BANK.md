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
| [business_logic.md](memory_bank/business_logic.md) | Бизнес-логика: раунды, роли, подсказки, голосование, очки |
| [agent_instructions.md](memory_bank/agent_instructions.md) | Протокол для AI-агентов: как читать, менять и обновлять память |

---

## 🚀 Быстрый старт (для агентов)

### Как начать работу

1. **Прочитай этот файл** — пойми структуру проекта.
2. **Найди нужный файл** в `memory_bank/` — подробности по теме.
3. **Изучи код** — следуй паттернам из `code_patterns.md`.
4. **Обнови память** — после завершения фичи проверь, нужно ли дополнить файлы в `memory_bank/`.

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

---

## ⚠️ Главное правило

> **Основная задача агента — НЕ менять `MEMORY_BANK.md`, а дополнять детальные файлы в папке `memory_bank/`.**
>
> Этот файл обновляется **только** при добавлении нового файла в `memory_bank/`.
