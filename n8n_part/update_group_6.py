import re
import json

with open("n8n_part/group_6_review.md", "r", encoding="utf-8") as f:
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

# Update roles map (either replace existing or append)
for l in locations:
    role_pattern = r'"{0}": \[.*?\]'.format(re.escape(l["name"]))
    new_roles_list = f'"{l["name"]}": [\n' + "".join([f'      "{r}",\n' for r in l["roles"]]) + '    ]'
    if re.search(role_pattern, dart_code, flags=re.DOTALL):
        dart_code = re.sub(role_pattern, new_roles_list, dart_code, flags=re.DOTALL)

with open(dart_path, "w", encoding="utf-8") as f:
    f.write(dart_code)

print("Updated Group 6 roles in dart file.")
