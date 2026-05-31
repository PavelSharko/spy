import re
with open("lib/data/locations_data.dart", "r", encoding="utf-8") as f:
    text = f.read()

groups_match = re.search(r"static const List<Map<String, dynamic>> groups = \[(.*?)\];\s*static const Map", text, re.DOTALL)
if groups_match:
    group_blocks = re.findall(r'\{\s*"groupName":\s*"([^"]+)",', groups_match.group(1))
    for i, g in enumerate(group_blocks):
        print(f"{i+1}. {g}")
else:
    print("Not found")
