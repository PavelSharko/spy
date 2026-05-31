import json
import re

dart_path = "lib/data/locations_data.dart"
with open(dart_path, "r", encoding="utf-8") as f:
    content = f.read()

groups_match = re.search(r'\{\s*"groupName": "Развлечения и встречи",\s*"locations": \[(.*?)\]\s*\}', content, re.DOTALL)
if groups_match:
    locs = [l.strip().strip('"').strip("'") for l in groups_match.group(1).split(",") if l.strip()]
    
    roles_match = re.search(r"roles = \{(.*?)\};", content, re.DOTALL)
    roles_block = roles_match.group(1)
    
    res = []
    for loc in locs:
        r_match = re.search(r'"{0}": \[.*?\]'.format(re.escape(loc)), roles_block, re.DOTALL)
        if r_match:
            r_list_text = r_match.group(0).split('[')[1].split(']')[0]
            r_list = [r.strip().strip('"').strip("'") for r in r_list_text.split(",") if r.strip()]
            res.append({"name": loc, "roles": r_list})
        else:
            res.append({"name": loc, "roles": []})
            
    print(json.dumps(res, ensure_ascii=False, indent=2))
