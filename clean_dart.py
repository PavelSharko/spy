import re

with open("lib/data/locations_data.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Keys to remove from roles and hints
keys_to_remove = [
    "Сон", "Гигантский магазин", "Летающий город", "Поезд времени",
    "Бесконечный офис", "Остров шоу", "VR переговорка", "Магический рынок",
    "Город шепота", "Кафе между мирами"
]

for key in keys_to_remove:
    pattern_roles = r'"{0}": \[.*?\](?:,\s*)?'.format(re.escape(key))
    text = re.sub(pattern_roles, '', text, flags=re.DOTALL)

with open("lib/data/locations_data.dart", "w", encoding="utf-8") as f:
    f.write(text)

