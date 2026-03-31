# 🔬 Webhook Test Suite — Документация

## Запуск

```bash
python3 tests/webhook_test.py
```

Далее вводишь `help_test` для списка всех тестов и команд.

---

## Команды

| Команда | Описание |
|---|---|
| `help_test` | Список всех тестов и команд |
| `run <test_id>` | Запустить тест (primary URL) |
| `run <test_id> fallback` | Запустить тест (fallback URL) |
| `run_all` | Запустить ВСЕ 7 тестов |
| `run_all fallback` | ВСЕ тесты через fallback |
| `quit` / `exit` | Выход |

---

## 7 тестовых кейсов

### 📂 gen_card_for_location — JSON POST (3 теста)

| ID | Игроки | Описание |
|---|---|---|
| `1_1` | 4 | Рандом локация, 3 роли, рандом стиль |
| `1_2` | 5 | Рандом локация, 4 роли, рандом стиль |
| `1_3` | 4 × 3 раунда | 3 последовательных запроса с интервалом 5 сек |

**Что n8n получает:**
```json
{
  "location": "Казино",
  "roles": ["Крупье", "Охранник", "Бармен"],
  "type_query": "gen_card_for_location",
  "generation_style": "аниме",
  "need_add_faces": false
}
```

---

### 📂 gen_card_for_finish_round (4 теста)

| ID | spy_is_win | need_add_faces | Фото | Формат |
|---|---|---|---|---|
| `2_1` | `true` | `true` | 4 JPEG | multipart |
| `2_2` | `false` | `true` | 4 JPEG | multipart |
| `2_3` | `true` | `false` | нет | JSON |
| `2_4` | `false` | `false` | нет | JSON |

**2_3 / 2_4 (без фото) — n8n получает JSON:**
```json
{
  "location": "Школа",
  "roles": ["Учитель", "Директор", "Охранник"],
  "type_query": "gen_card_for_finish_round",
  "generation_style": "комиксы",
  "need_add_faces": false,
  "spy_is_win": true
}
```

**2_1 / 2_2 (с фото) — n8n получает multipart/form-data:**
```
Поля (body):
  location          = "Школа"
  roles             = '["Учитель","Директор","Охранник"]'
  type_query        = "gen_card_for_finish_round"
  generation_style  = "комиксы"
  need_add_faces    = "true"
  spy_is_win        = "true"

Файлы (binary):
  photo_0 → player_0.jpg (image/jpeg) → binary.data0
  photo_1 → player_1.jpg (image/jpeg) → binary.data1
  photo_2 → player_2.jpg (image/jpeg) → binary.data2
  photo_3 → player_3.jpg (image/jpeg) → binary.data3
```

---

## Результаты

Ответы сохраняются в `tests/results/<test_id>.jpg`

---

## Тестовые фото

| Файл | Путь |
|---|---|
| 1-6 | `data_for_test/1.jpeg` .. `data_for_test/6.jpeg` |

---

## Как добавить тест

В `tests/webhook_test.py`:

```python
def test_custom(url):
    payload = {
        "location": "Новая локация",
        "roles": ["Роль1", "Роль2"],
        "type_query": "gen_card_for_location",
        "generation_style": "киберпанк",
        "need_add_faces": False,
    }
    return send_json(url, payload, "custom_1")

register("custom_1", "Описание теста", test_custom)
```
