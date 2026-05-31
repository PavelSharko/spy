import re
import random

with open("n8n_part/group_5_review.md", "r", encoding="utf-8") as f:
    content = f.read()

locations = []
blocks = re.split(r'## \d+\. (.+)', content)[1:]

for i in range(0, len(blocks), 2):
    loc_name = blocks[i].strip()
    loc_content = blocks[i+1]
    
    roles_match = re.search(r'\* \*\*Роли:\*\* (.+)', loc_content)
    roles = roles_match.group(1).strip() if roles_match else ""
    
    hints_section = re.search(r'\* \*\*Подсказки:\*\*(.*?)(?:\n\n|\Z)', loc_content, re.DOTALL)
    hints = []
    if hints_section:
        for line in hints_section.group(1).split('\n'):
            if line.strip():
                hints.append(line.strip())
                
    locations.append({
        "name": loc_name,
        "roles": roles,
        "hints": hints
    })

# Collect all hints and their original location
all_hints = []
for loc in locations:
    for h in loc["hints"]:
        all_hints.append({"text": h, "original_loc": loc["name"]})

random.shuffle(all_hints)

new_locations = []
hint_index = 0

# Distribute exactly 5 hints to each location first
for loc in locations:
    assigned_hints = []
    for _ in range(5):
        if hint_index < len(all_hints):
            assigned_hints.append(all_hints[hint_index])
            hint_index += 1
            
    # Now check for matches and remove them
    filtered_hints = []
    for h in assigned_hints:
        if h["original_loc"] != loc["name"]:
            filtered_hints.append(h["text"])
            
    new_locations.append({
        "name": loc["name"],
        "roles": loc["roles"],
        "hints": filtered_hints
    })

# Reconstruct the file
header = re.split(r'## \d+\.', content)[0]
new_content = header

for idx, loc in enumerate(new_locations):
    new_content += f"## {idx+1}. {loc['name']}\n"
    new_content += f"* **Роли:** {loc['roles']}\n"
    new_content += f"* **Подсказки:**\n"
    for h in loc['hints']:
        new_content += f"  {h}\n"
    new_content += "\n"

with open("n8n_part/group_5_review.md", "w", encoding="utf-8") as f:
    f.write(new_content)

print(f"Total hints original: {len(all_hints)}")
assigned_count = sum(len(l["hints"]) for l in new_locations)
print(f"Total hints assigned: {assigned_count}")
dropped_count = len(all_hints) - assigned_count
print(f"Hints dropped (matched original location): {dropped_count}")
for loc in new_locations:
    print(f"- {loc['name']}: {len(loc['hints'])} подсказок")
