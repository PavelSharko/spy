import json
import re

dart_path = "lib/data/locations_data.dart"
with open(dart_path, "r", encoding="utf-8") as f:
    content = f.read()

# find group 5: the 5th group in the list
groups_block = re.search(r'static const List<Map<String, dynamic>> groups = \[(.*?)\];\s*static const Map', content, re.DOTALL).group(1)
group_matches = re.findall(r'\{\s*"groupName": "(.*?)",\s*"locations": \[(.*?)\]\s*\}', groups_block, re.DOTALL)

g_name, loc_text = group_matches[4] # Group 5
locs = [l.strip().strip('"').strip("'") for l in loc_text.split(",") if l.strip()]

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
        
print(f"Group 5: {g_name}")
for r in res:
    print(f"{r['name']}: {', '.join(r['roles'])}")
