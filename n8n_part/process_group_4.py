import re
import json

with open("n8n_part/group_4_review.md", "r", encoding="utf-8") as f:
    content = f.read()

# Make sure roles for Museum are 10
if "Чучело, Экспонат" in content and "Школьник на экскурсии" not in content:
    content = content.replace(
        "Турист иностранец, Директор музея, Уборщица",
        "Турист иностранец, Директор музея, Уборщица, Школьник"
    )

hints_dict = {
    "Кинотеатр": [
        "‼️ Раздражают ли чавкающие соседи?",
        "‼️ Выключают ли тут свет?",
        "‼️ Нужно ли тут сидеть тихо?",
        "‼️ Принято ли тут спать?",
        "‼️ Можно ли тут поставить на паузу?",
        "‼️ Часто ли тут целуются?"
    ],
    "Ночной клуб": [
        "‼️ Сильно ли тут бьет по ушам?",
        "‼️ Строгий ли тут фейс-контроль?",
        "‼️ Сильно ли тут потеют?",
        "‼️ Легко ли тут познакомиться?",
        "‼️ Можно ли тут встретить рассвет?",
        "‼️ Бесплатно ли наливают на баре?"
    ],
    "Караоке бар": [
        "‼️ Бывает ли тут стыдно за других?",
        "‼️ Сильно ли тут фальшивят?",
        "‼️ Обязательно ли тут иметь талант?",
        "‼️ Часто ли тут передают микрофон?",
        "‼️ Раздражает ли громкий вой?",
        "‼️ Можно ли тут сорвать голос?"
    ],
    "Торговый центр": [
        "‼️ Легко ли тут потратить все деньги?",
        "‼️ Часто ли тут теряются дети?",
        "‼️ Работает ли тут кондиционер?",
        "‼️ Долго ли тут бродят без цели?",
        "‼️ Бывают ли тут безумные скидки?",
        "‼️ Много ли тут сумасшедших подростков?"
    ],
    "Компьютерный клуб": [
        "‼️ Сильно ли тут матерятся?",
        "‼️ Пахнет ли тут подростковым потом?",
        "‼️ Сильно ли тут стучат по клавишам?",
        "‼️ Приходят ли сюда злые мамы?",
        "‼️ Можно ли тут зависнуть на сутки?",
        "‼️ Часто ли тут горят пуканы?"
    ],
    "Казино": [
        "‼️ Легко ли тут слить всю зарплату?",
        "‼️ Строгий ли тут дресс-код?",
        "‼️ Можно ли тут стать миллионером?",
        "‼️ Часто ли тут блефуют?",
        "‼️ Наливают ли тут бесплатно для азарта?",
        "‼️ Опасно ли тут мухлевать?"
    ],
    "Музыкальный фестиваль": [
        "‼️ Сильно ли тут месят грязь?",
        "‼️ Спят ли тут прямо на земле?",
        "‼️ Легко ли тут оглохнуть?",
        "‼️ Можно ли тут встретить кумира?",
        "‼️ Дорого ли тут стоит вода?",
        "‼️ Много ли тут невменяемых людей?"
    ],
    "Аквапарк": [
        "‼️ Легко ли тут захлебнуться?",
        "‼️ Обязательно ли тут раздеваться?",
        "‼️ Сильно ли тут воняет хлоркой?",
        "‼️ Писают ли тут тайком?",
        "‼️ Страшно ли тут скатываться вниз?",
        "‼️ Можно ли тут утонуть?"
    ],
    "Зоопарк": [
        "‼️ Специфический ли тут запах?",
        "‼️ Можно ли тут кормить местных?",
        "‼️ Сидят ли тут в клетках?",
        "‼️ Много ли тут диких особей?",
        "‼️ Безопасно ли тут совать пальцы?",
        "‼️ Платный ли сюда вход?"
    ],
    "Музей": [
        "‼️ Можно ли тут трогать руками?",
        "‼️ Заставляют ли тут говорить шепотом?",
        "‼️ Скучно ли тут детям?",
        "‼️ Сильно ли тут тянет в сон?",
        "‼️ Обязательно ли тут быть культурным?",
        "‼️ Ходят ли тут группами?"
    ]
}

# Add hints to markdown
new_md = ""
for block in re.split(r'(## \d+\. .+?\n)', content):
    if block.startswith("## "):
        new_md += block
        loc_name = block.split(". ")[1].strip()
    elif "* **Роли:**" in block:
        new_md += block.rstrip() + "\n* **Подсказки:**\n"
        for hint in hints_dict[loc_name]:
            new_md += f"  - {hint}\n"
        new_md += "\n"
    else:
        new_md += block

with open("n8n_part/group_4_review.md", "w", encoding="utf-8") as f:
    f.write(new_md)

# Parse locations to update dart and json
locations = []
blocks = re.split(r'## \d+\. (.+)', new_md)[1:]
for i in range(0, len(blocks), 2):
    loc_name = blocks[i].strip()
    loc_content = blocks[i+1]
    
    roles_match = re.search(r'\* \*\*Роли:\*\* (.+)', loc_content)
    if not roles_match:
        continue
    roles = [r.strip() for r in roles_match.group(1).split(',')]
    
    locations.append({
        "name": loc_name,
        "roles": roles,
        "hints": hints_dict[loc_name]
    })

# Update locations_data.dart
dart_path = "lib/data/locations_data.dart"
with open(dart_path, "r", encoding="utf-8") as f:
    dart_code = f.read()

# Replace Group Name "Развлечения и встречи" with "Городские развлечения"
dart_code = dart_code.replace('"Развлечения и встречи"', '"Городские развлечения"')

group_pattern = r'(\{\s*"groupName": "Городские развлечения",\s*"locations": \[)(.*?)(\],\s*\})'
new_loc_list = "\n" + "".join([f'        "{l["name"]}",\n' for l in locations]) + "      "
dart_code = re.sub(group_pattern, r'\1' + new_loc_list + r'\3', dart_code, flags=re.DOTALL)

for l in locations:
    role_pattern = r'"{0}": \[.*?\]'.format(re.escape(l["name"]))
    new_roles_list = f'"{l["name"]}": [\n' + "".join([f'      "{r}",\n' for r in l["roles"]]) + '    ]'
    if re.search(role_pattern, dart_code, flags=re.DOTALL):
        dart_code = re.sub(role_pattern, new_roles_list, dart_code, flags=re.DOTALL)
    else:
        # If renamed, insert manually
        insert_marker = r'(// Городские развлечения\s*)'
        if not re.search(insert_marker, dart_code):
             insert_marker = r'(// Развлечения и встречи\s*)'
        dart_code = re.sub(insert_marker, r'\1' + new_roles_list + ',\n    ', dart_code, count=1)

with open(dart_path, "w", encoding="utf-8") as f:
    f.write(dart_code)

# Update locations_stats.json
stats_path = "assets/data/locations_stats.json"
with open(stats_path, "r", encoding="utf-8") as f:
    stats = json.load(f)

for l in locations:
    if l["name"] not in stats["locations"]:
        stats["locations"][l["name"]] = {
            "location_chosed_times": 0,
            "hints_private": []
        }
    stats["locations"][l["name"]]["hints_private"] = [{"text": h.replace("- ‼️", "").replace("‼️", "").strip(), "hint_choosed_times": 0} for h in l["hints"]]

with open(stats_path, "w", encoding="utf-8") as f:
    json.dump(stats, f, ensure_ascii=False, indent=2)

print("Group 4 updated successfully!")
