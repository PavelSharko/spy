import re
def parse_md_hints(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    locations = {}
    blocks = re.split(r'## \d+\. ', content)
    for block in blocks[1:]:
        lines = block.strip().split('\n')
        name = lines[0].strip()
        locations[name] = True
    return list(locations.keys())

for i in range(5, 11):
    locs = parse_md_hints(f"n8n_part/group_{i}_review.md")
    print(f"Group {i} has {len(locs)} locs: {locs}")
