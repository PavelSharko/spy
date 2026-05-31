import re
import json

with open("n8n_part/group_7_review.md", "r", encoding="utf-8") as f:
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
        "roles": roles,
        "hints": hints
    })

# Update locations_data.dart
dart_path = "lib/data/locations_data.dart"
with open(dart_path, "r", encoding="utf-8") as f:
    dart_code = f.read()

# Overwrite the old "Фэнтези миры" array
group_pattern = r'(\{\s*"groupName": "Фэнтези миры",\s*"locations": \[)(.*?)(\],\s*\})'
new_loc_list = "\n" + "".join([f'        "{l["name"]}",\n' for l in locations]) + "      "
if re.search(group_pattern, dart_code, flags=re.DOTALL):
    dart_code = re.sub(group_pattern, r'\1' + new_loc_list + r'\3', dart_code, flags=re.DOTALL)

# Update roles map (either replace existing or append)
for l in locations:
    role_pattern = r'"{0}": \[.*?\]'.format(re.escape(l["name"]))
    new_roles_list = f'"{l["name"]}": [\n' + "".join([f'      "{r}",\n' for r in l["roles"]]) + '    ]'
    if re.search(role_pattern, dart_code, flags=re.DOTALL):
        dart_code = re.sub(role_pattern, new_roles_list, dart_code, flags=re.DOTALL)
    else:
        # insert at the end of Фэнтези миры section
        insert_marker = r'(// Фэнтези миры\s*)'
        if re.search(insert_marker, dart_code):
            dart_code = re.sub(insert_marker, r'\1' + new_roles_list + ',\n    ', dart_code, count=1)
        else:
            # fallback insert
            dart_code = dart_code.replace('static const Map<String, List<String>> roles = {', 
                                          'static const Map<String, List<String>> roles = {\n    ' + new_roles_list + ',')

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
    
    if l["hints"]:
        stats["locations"][l["name"]]["hints_private"] = [{"text": h, "hint_choosed_times": 0} for h in l["hints"]]

with open(stats_path, "w", encoding="utf-8") as f:
    json.dump(stats, f, ensure_ascii=False, indent=2)

print(f"Updated Group 7 with {len(locations)} locations.")
