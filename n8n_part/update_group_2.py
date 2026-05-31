import re
import json

# 1. Parse group_2_review.md
with open("n8n_part/group_2_review.md", "r", encoding="utf-8") as f:
    content = f.read()

locations = []
blocks = re.split(r'## \d+\. (.+)', content)[1:]
for i in range(0, len(blocks), 2):
    loc_name = blocks[i].strip()
    loc_content = blocks[i+1]
    
    roles_match = re.search(r'\* \*\*Роли:\*\* (.+)', loc_content)
    if not roles_match:
        continue
    roles = [r.strip() for r in roles_match.group(1).split(',')]
    
    hints_section = re.search(r'\* \*\*Подсказки:\*\*(.*?)(?:\n\n|\Z)', loc_content, re.DOTALL)
    hints = []
    if hints_section:
        hints_lines = hints_section.group(1).split('\n')
        for line in hints_lines:
            line = line.strip()
            if line.startswith('- ‼️'):
                hints.append(line.replace('- ‼️', '').strip())
            elif line.startswith('- '):
                hints.append(line.replace('- ', '').strip())
    
    locations.append({
        "name": loc_name,
        "roles": roles,
        "hints": [h for h in hints if h]
    })

# print(json.dumps(locations, ensure_ascii=False, indent=2))

# 2. Update locations_data.dart
dart_path = "lib/data/locations_data.dart"
with open(dart_path, "r", encoding="utf-8") as f:
    dart_code = f.read()

# Update group 2 locations list
group_pattern = r'(\{\s*"groupName": "Работа и бизнес",\s*"locations": \[)(.*?)(\],\s*\})'
new_loc_list = "\n" + "".join([f'        "{l["name"]}",\n' for l in locations]) + "      "
dart_code = re.sub(group_pattern, r'\1' + new_loc_list + r'\3', dart_code, flags=re.DOTALL)

# Update roles dictionary
for l in locations:
    # Check if role exists
    role_pattern = r'"{0}": \[.*?\]'.format(re.escape(l["name"]))
    new_roles_list = f'"{l["name"]}": [\n' + "".join([f'      "{r}",\n' for r in l["roles"]]) + '    ]'
    if re.search(role_pattern, dart_code, flags=re.DOTALL):
        dart_code = re.sub(role_pattern, new_roles_list, dart_code, flags=re.DOTALL)
    else:
        # Just insert it under the // Работа и бизнес comment
        insert_marker = r'(// Работа и бизнес\s*)'
        dart_code = re.sub(insert_marker, r'\1' + new_roles_list + ',\n    ', dart_code, count=1)

with open(dart_path, "w", encoding="utf-8") as f:
    f.write(dart_code)

# 3. Update locations_stats.json
stats_path = "assets/data/locations_stats.json"
with open(stats_path, "r", encoding="utf-8") as f:
    stats = json.load(f)

for l in locations:
    stats["locations"][l["name"]] = {
        "location_chosed_times": 0,
        "hints_private": [{"text": h, "hint_choosed_times": 0} for h in l["hints"]]
    }

with open(stats_path, "w", encoding="utf-8") as f:
    json.dump(stats, f, ensure_ascii=False, indent=2)

print(f"Updated dart and json files with {len(locations)} locations.")
