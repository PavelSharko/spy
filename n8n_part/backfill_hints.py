import re

new_hints = [
    "Сильно ли тут пахнет старостью?",
    "Часто ли тут бьют посуду?",
    "Нужно ли тут платить дважды?",
    "Обязательно ли тут улыбаться?",
    "Можно ли тут встретить призрака?",
    "Легко ли тут сломать ногу?",
    "Сильно ли тут болит голова?",
    "Часто ли тут вызывают полицию?",
    "Много ли тут сумасшедших?",
    "Можно ли тут заработать?",
    "Сильно ли тут дует сквозняк?"
]

with open("n8n_part/group_5_review.md", "r", encoding="utf-8") as f:
    content = f.read()

locations = []
blocks = re.split(r'## \d+\. (.+)', content)[1:]

for i in range(0, len(blocks), 2):
    loc_name = blocks[i].strip()
    loc_content = blocks[i+1]
    
    roles_match = re.search(r'\* \*\*Роли:\*\* (.+)', loc_content)
    roles = roles_match.group(1).strip() if roles_match else ""
    
    hints_section = re.search(r'\* \*\*Подсказки:\*\*(.*?)(?:\n\n|\Z)', loc_content, re.DOTALL)
    hints = []
    if hints_section:
        for line in hints_section.group(1).split('\n'):
            if line.strip():
                hints.append(line.strip())
                
    locations.append({
        "name": loc_name,
        "roles": roles,
        "hints": hints
    })

hint_idx = 0
for loc in locations:
    while len(loc["hints"]) < 5 and hint_idx < len(new_hints):
        loc["hints"].append(f"‼️ {new_hints[hint_idx]}")
        hint_idx += 1

header = re.split(r'## \d+\.', content)[0]
new_content = header

for idx, loc in enumerate(locations):
    new_content += f"## {idx+1}. {loc['name']}\n"
    new_content += f"* **Роли:** {loc['roles']}\n"
    new_content += f"* **Подсказки:**\n"
    for h in loc['hints']:
        # Format properly
        h_clean = h.replace("‼️", "").replace("-", "").strip()
        new_content += f"  - ‼️ {h_clean}\n"
    new_content += "\n"

with open("n8n_part/group_5_review.md", "w", encoding="utf-8") as f:
    f.write(new_content)

for loc in locations:
    print(f"- {loc['name']}: {len(loc['hints'])} подсказок")
