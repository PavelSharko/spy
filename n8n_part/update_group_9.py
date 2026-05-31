import re
import json

def get_locations_from_md(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    locations = []
    # Pattern to match:
    # ## 1. Хогвартс (Гарри Поттер)
    # * **Роли:** Гарри Поттер, Альбус Дамблдор...
    # * **Подсказки:**
    #   - Подсказка 1
    #   - Подсказка 2
    
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
            elif in_hints and line.startswith('- '):
                hints.append(line.replace('- ', '').strip())
                
        locations.append({
            "name": name,
            "roles": roles,
            "hints": hints
        })
    return locations

def update_dart_file(locations):
    with open("lib/data/locations_data.dart", "r", encoding="utf-8") as f:
        dart_code = f.read()

    # 1. Update the locations list for group "Киновселенные"
    group_pattern = r'("groupName": "Киновселенные",\s*"locations": \[\s*)(.*?)(\s*\],)'
    
    # Check if group exists, else we might need to find where to put it
    if re.search(group_pattern, dart_code, flags=re.DOTALL):
        new_locs_list = "\n".join([f'        "{l["name"]}",' for l in locations])
        dart_code = re.sub(group_pattern, r'\g<1>' + new_locs_list + r'\g<3>', dart_code, flags=re.DOTALL)
    
    # 2. Add or update roles
    roles_block_match = re.search(r'(static const Map<String, List<String>> roles = \{)(.*?)(\};)', dart_code, re.DOTALL)
    if roles_block_match:
        roles_text = roles_block_match.group(2)
        for l in locations:
            role_pattern = r'"{0}": \[.*?\]'.format(re.escape(l["name"]))
            new_roles_list = f'"{l["name"]}": [\n' + "".join([f'      "{r}",\n' for r in l["roles"]]) + '    ]'
            if re.search(role_pattern, roles_text, flags=re.DOTALL):
                roles_text = re.sub(role_pattern, new_roles_list, roles_text, flags=re.DOTALL)
            else:
                # Append to the end
                if roles_text.strip().endswith(','):
                    roles_text += f'\n    {new_roles_list},'
                else:
                    roles_text += f',\n    {new_roles_list},'
        dart_code = dart_code.replace(roles_block_match.group(2), roles_text)

    # 3. Add or update hints
    hints_block_match = re.search(r'(static const Map<String, List<String>> hints = \{)(.*?)(\};)', dart_code, re.DOTALL)
    if hints_block_match:
        hints_text = hints_block_match.group(2)
        for l in locations:
            hint_pattern = r'"{0}": \[.*?\]'.format(re.escape(l["name"]))
            new_hints_list = f'"{l["name"]}": [\n' + "".join([f'      "{h}",\n' for h in l["hints"]]) + '    ]'
            if re.search(hint_pattern, hints_text, flags=re.DOTALL):
                hints_text = re.sub(hint_pattern, new_hints_list, hints_text, flags=re.DOTALL)
            else:
                if hints_text.strip().endswith(','):
                    hints_text += f'\n    {new_hints_list},'
                else:
                    hints_text += f',\n    {new_hints_list},'
        dart_code = dart_code.replace(hints_block_match.group(2), hints_text)

    with open("lib/data/locations_data.dart", "w", encoding="utf-8") as f:
        f.write(dart_code)

def update_stats_json(locations):
    with open("assets/data/locations_stats.json", "r", encoding="utf-8") as f:
        stats = json.load(f)
        
    for l in locations:
        if l["name"] not in stats:
            stats[l["name"]] = {"played": 0, "spy_wins": 0}
            
    with open("assets/data/locations_stats.json", "w", encoding="utf-8") as f:
        json.dump(stats, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    locs = get_locations_from_md("n8n_part/group_9_review.md")
    update_dart_file(locs)
    update_stats_json(locs)
    print(f"Successfully synced {len(locs)} locations for Group 9!")
