import re
import json

def get_locations_from_md(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    locations = []
    blocks = re.split(r'## \d+\. ', content)
    for block in blocks[1:]:
        lines = block.strip().split('\n')
        name = lines[0].strip()
        
        roles = []
        hints = []
        
        in_hints = False
        for line in lines[1:]:
            line = line.strip()
            if line.startswith('* **Роли:**'):
                roles_str = line.replace('* **Роли:**', '').strip()
                roles = [r.strip() for r in roles_str.split(',')]
            elif line.startswith('* **Подсказки:**'):
                in_hints = True
            elif in_hints and line.startswith('- ‼️'):
                hints.append(line.replace('- ‼️', '').strip())
                
        locations.append({
            "name": name,
            "roles": roles,
            "hints": hints
        })
    return locations

def update_dart_file(locations):
    with open("lib/data/locations_data.dart", "r", encoding="utf-8") as f:
        dart_code = f.read()

    # Find the 10th group and replace its name and locations
    # It's currently "Необычные и абстрактные"
    group_pattern = r'("groupName": "Необычные и абстрактные",\s*"locations": \[\s*)(.*?)(\s*\],)'
    new_locs_list = "\n".join([f'        "{l["name"]}",' for l in locations])
    # Replace "Необычные и абстрактные" with "Исторические эпохи"
    dart_code = re.sub(group_pattern, r'"groupName": "Исторические эпохи",\n      "locations": [\n' + new_locs_list + r'\n      ],', dart_code, flags=re.DOTALL)
    
    with open("lib/data/locations_data.dart", "w", encoding="utf-8") as f:
        f.write(dart_code)

if __name__ == "__main__":
    locs = get_locations_from_md("n8n_part/group_10_review.md")
    update_dart_file(locs)
    print(f"Successfully fixed Group 10 to Исторические эпохи!")
