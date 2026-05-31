import re

missing_locations = {
  "Университет": [
    "Профессор", "Студент", "Аспирант", "Арнольд Шварценеггер", "Ректор", "Опоздун", "Физрук", "Декан", "Уборщица", "Первокурсник"
  ],
  "Музыкальная школа": [
    "Преподаватель", "Плачущий ученик", "Пианист", "Гитарист", "Директор", "Вахтерша", "Медведь на ухо", "Киркоров", "Ким Кардашьян", "дворник"
  ],
  "Языковая школа": [
    "Иностранец", "Препод", "Тупой", "Отличник", "Директор", "Чернокожий", "Снуп Догг", "Уборщица", "Овчарка", "Переводчик"
  ],
  "Автошкола": [
    "Инструктор", "Ученик", "Лихач", "Инспектор ГАИ", "Собака", "Взяточник", "Директор", "Тупая телка", "Дональд Трамп", "Уборщица"
  ],
  "Школьный спортзал": [
    "Физрук", "Освобожденный", "Хулиган", "Капитан команды", "Мячик", "Директор", "Толстяк", "дохляк", "Отличник", "Майкл Джексон"
  ],
  "Детский лагерь": [
    "Вожатый", "Хочу домой", "Директор", "Повариха", "Хулиган", "Гомер Симпсон", "Заводила", "Тихоня", "Физрук", "Развратница"
  ],
  "Воскресная школа": [
    "Священник (Батюшка)", "Монахиня", "Послушник", "Брэд Питт", "Дьякон", "Бабушка", "Хулиган", "Руководитель хора", "Уборщица", "Звонарь"
  ],
  "Монастырь Шаолинь": [
    "Настоятель", "Ученик-послушник", "Старый мастер", "Турист-зевака", "Повар-монах", "Мастер кунг-фу", "Переводчик", "Иностранец в поисках просветления", "Мальчик-ученик", "Джеки Чан"
  ]
}

with open("lib/data/locations_data.dart", "r", encoding="utf-8") as f:
    dart_code = f.read()

# 1. Fix missing commas between `],` and `"NextLoc": [`
# Sometimes it looks like `    ]\n    "Маршрутка": [` instead of `    ],\n    "Маршрутка": [`
# Also handle any cases where a comma is missing after `]` before a comment or a string
def fix_commas(match):
    # match.group(1) is everything before the missing comma, e.g. "]"
    # match.group(2) is whitespace
    # match.group(3) is the next line e.g. `"Loc": [` or `// comment`
    return match.group(1) + "," + match.group(2) + match.group(3)

# Find `]` followed by whitespace and then `"` without a comma
dart_code = re.sub(r'(\])(\s*)(\"[^\"]+\"\s*:)', fix_commas, dart_code)
# Also fix `]` followed by whitespace and then `//` without a comma
dart_code = re.sub(r'(\])(\s*)(//.*?\n\s*\"[^\"]+\"\s*:)', fix_commas, dart_code)

# 2. Re-insert the missing 8 locations right before "Школа выживания"
insert_text = ""
for loc, roles in missing_locations.items():
    insert_text += f'    "{loc}": [\n'
    for r in roles:
        insert_text += f'      "{r}",\n'
    insert_text += '    ],\n'

# Find where to insert
# In the file we have `// Образование "Школа выживания": [` which is mangled!
# Let's fix that mangled line too
dart_code = dart_code.replace('    // Образование "Школа выживания": [', '    // Образование\n' + insert_text + '    "Школа выживания": [')

with open("lib/data/locations_data.dart", "w", encoding="utf-8") as f:
    f.write(dart_code)

print("Dart file repaired!")
