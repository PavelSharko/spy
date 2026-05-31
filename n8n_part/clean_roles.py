import re
import json

def clean_file(filename):
    with open(filename, "r", encoding="utf-8") as f:
        content = f.read()

    # Manual overrides for specific weird parenthesis
    content = content.replace("Бард (Лютик)", "Лютик")
    content = content.replace("Предатель (Сайфер)", "Сайфер")
    
    # Regex to remove all other parenthesis in roles lines
    def clean_roles_line(match):
        prefix = match.group(1)
        roles = match.group(2)
        # Remove (anything)
        clean_roles = re.sub(r'\s*\([^)]*\)', '', roles)
        return prefix + clean_roles

    content = re.sub(r'^(\* \*\*Роли:\*\* )(.*)$', clean_roles_line, content, flags=re.MULTILINE)
    
    with open(filename, "w", encoding="utf-8") as f:
        f.write(content)
        
    return content

clean_file("n8n_part/group_7_review.md")
content_8 = clean_file("n8n_part/group_8_review.md")

# Now let's sync Group 7 and 8 into Dart
def get_locations_from_md(content):
    locations = []
    blocks = re.split(r'## \d+\. (.+)', content)[1:]
    for i in range(0, len(blocks), 2):
        loc_name = blocks[i].strip()
        loc_content = blocks[i+1]
        
        roles_match = re.search(r'\* \*\*Роли:\*\* (.+)', loc_content)
        if not roles_match: continue
        roles = [r.strip() for r in roles_match.group(1).split(',')]
        
        loc_content_no_roles = re.sub(r'\* \*\*Роли:\*\*.*?\n', '', loc_content)
        hints = []
        for line in loc_content_no_roles.split('\n'):
            line = line.strip()
            if line.startswith('- ‼️'): line = line[len('- ‼️'):].strip()
            elif line.startswith('- '): line = line[len('- '):].strip()
            elif line.startswith('‼️'): line = line[len('‼️'):].strip()
            if line and not line.startswith('* **Подсказки'): hints.append(line)
        locations.append({"name": loc_name, "roles": roles, "hints": hints})
    return locations

locs_7 = get_locations_from_md(open("n8n_part/group_7_review.md", "r", encoding="utf-8").read())
locs_8 = get_locations_from_md(open("n8n_part/group_8_review.md", "r", encoding="utf-8").read())

all_new_locs = locs_7 + locs_8

with open("lib/data/locations_data.dart", "r", encoding="utf-8") as f:
    dart_code = f.read()

# Update Group 8 array in Dart since we renamed/added locations
# groupName: "Космос и фантастика" (Wait, in Dart it's "Космос и sci-fi" or "Космос и фантастика"? Let's check.)
# In the previous grep it was "Космос и sci-fi"
group_pattern_8 = r'(\{\s*"groupName": "Космос и sci-fi",\s*"locations": \[)(.*?)(\],\s*\})'
new_loc_list_8 = "\n" + "".join([f'        "{l["name"]}",\n' for l in locs_8]) + "      "
if re.search(group_pattern_8, dart_code, flags=re.DOTALL):
    dart_code = re.sub(group_pattern_8, r'\1' + new_loc_list_8 + r'\3', dart_code, flags=re.DOTALL)
else:
    # Try alternate name if needed
    group_pattern_8_alt = r'(\{\s*"groupName": "Космос и фантастика",\s*"locations": \[)(.*?)(\],\s*\})'
    if re.search(group_pattern_8_alt, dart_code, flags=re.DOTALL):
        dart_code = re.sub(group_pattern_8_alt, r'\1' + new_loc_list_8 + r'\3', dart_code, flags=re.DOTALL)

for l in all_new_locs:
    role_pattern = r'"{0}": \[.*?\]'.format(re.escape(l["name"]))
    new_roles_list = f'"{l["name"]}": [\n' + "".join([f'      "{r}",\n' for r in l["roles"]]) + '    ]'
    if re.search(role_pattern, dart_code, flags=re.DOTALL):
        dart_code = re.sub(role_pattern, new_roles_list, dart_code, flags=re.DOTALL)
    else:
        # Fallback insert before end of map
        dart_code = dart_code.replace('static const Map<String, List<String>> roles = {', 
                                      'static const Map<String, List<String>> roles = {\n    ' + new_roles_list + ',')

with open("lib/data/locations_data.dart", "w", encoding="utf-8") as f:
    f.write(dart_code)

print("Roles cleaned and synced to dart!")
