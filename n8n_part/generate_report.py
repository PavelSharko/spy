import json
import re
import random

def parse_md_hints(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    locations = {}
    blocks = re.split(r'## \d+\. ', content)
    for block in blocks[1:]:
        lines = block.strip().split('\n')
        name = lines[0].strip()
        hints = []
        in_hints = False
        for line in lines[1:]:
            line = line.strip()
            if line.startswith('* **Подсказки:**'):
                in_hints = True
            elif in_hints and (line.startswith('- ‼️') or line.startswith('- ') or line.startswith('‼️')):
                hint_text = line.replace('- ‼️', '').replace('- ', '').replace('‼️', '').strip()
                hints.append(hint_text)
        locations[name] = hints
    return locations

def main():
    original_hints = {}
    for i in range(5, 11):
        locs = parse_md_hints(f"n8n_part/group_{i}_review.md")
        original_hints.update(locs)

    with open("assets/data/locations_stats.json", "r", encoding="utf-8") as f:
        stats = json.load(f)
    
    current_hints = {}
    locs_data = stats.get("locations", {})
    for loc, data in locs_data.items():
        hints = [h["text"] for h in data.get("hints_private", [])]
        current_hints[loc] = hints

    # Select 10 random locations that are in original_hints
    sample_locs = random.sample(list(original_hints.keys()), min(10, len(original_hints)))

    for loc in sample_locs:
        print(f"📍 Локация: {loc}")
        print("БЫЛО (Оригинальные подсказки):")
        orig = original_hints[loc]
        for idx, h in enumerate(orig):
            print(f"  {idx+1}. {h}")
        
        print("СТАЛО (После перемешивания):")
        curr = current_hints.get(loc, [])
        for idx, h in enumerate(curr):
            prefix = "[ОСТАЛОСЬ]" if idx < 2 else "[ПРИЛЕТЕЛО ИЗ ДРУГОЙ ЛОКАЦИИ]"
            print(f"  {idx+1}. {h} {prefix}")
        print("-" * 50)

if __name__ == "__main__":
    main()
