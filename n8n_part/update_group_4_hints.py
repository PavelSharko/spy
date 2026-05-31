import re
import json

with open("n8n_part/group_4_review.md", "r", encoding="utf-8") as f:
    content = f.read()

locations = []
blocks = re.split(r'## \d+\. (.+)', content)[1:]
for i in range(0, len(blocks), 2):
    loc_name = blocks[i].strip()
    loc_content = blocks[i+1]
    
    # Remove Roles block
    loc_content_no_roles = re.sub(r'\* \*\*Роли:\*\*.*?\n', '', loc_content)
    
    hints = []
    for line in loc_content_no_roles.split('\n'):
        line = line.strip()
        if not line or line.startswith('* **Подсказки'):
            continue
            
        if line.startswith('- ‼️'):
            line = line[len('- ‼️'):].strip()
        elif line.startswith('- '):
            line = line[len('- '):].strip()
        elif line.startswith('‼️'):
            line = line[len('‼️'):].strip()
            
        if line:
            hints.append(line)
    
    locations.append({
        "name": loc_name,
        "hints": hints
    })

stats_path = "assets/data/locations_stats.json"
with open(stats_path, "r", encoding="utf-8") as f:
    stats = json.load(f)

for l in locations:
    if l["name"] in stats["locations"]:
        stats["locations"][l["name"]]["hints_private"] = [{"text": h, "hint_choosed_times": 0} for h in l["hints"]]

with open(stats_path, "w", encoding="utf-8") as f:
    json.dump(stats, f, ensure_ascii=False, indent=2)

print(f"Updated hints for Group 4 in locations_stats.json.")
