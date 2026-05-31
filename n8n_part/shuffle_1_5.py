import re
import json
import random

def parse_md_hints(filepath):
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"File {filepath} not found!")
        return {}
        
    locations = {}
    blocks = re.split(r'## \d+\. ', content)
    for block in blocks[1:]:
        lines = block.strip().split('\n')
        name = lines[0].strip()
        
        hints = []
        in_hints = False
        for line in lines[1:]:
            line = line.strip()
            if line.startswith('* **Подсказки:**') or line.startswith('* **Подсказки**'):
                in_hints = True
            elif in_hints and (line.startswith('- ‼️') or line.startswith('- ') or line.startswith('‼️')):
                hint_text = line.replace('- ‼️', '').replace('- ', '').replace('‼️', '').strip()
                hints.append(hint_text)
                
        locations[name] = hints
    return locations

def main():
    original_hints = {}
    for i in range(1, 6):
        locs = parse_md_hints(f"n8n_part/group_{i}_review.md")
        original_hints.update(locs)
        
    print(f"Parsed {len(original_hints)} locations from MD files 1-5.")
    
    pool = []
    fixed_hints = {}
    
    for loc, hints in original_hints.items():
        if len(hints) >= 2:
            fixed_hints[loc] = hints[:2]
            pool.extend(hints[2:])
        else:
            fixed_hints[loc] = hints
            
    print(f"Collected {len(pool)} hints to shuffle.")
    random.shuffle(pool)
    
    final_hints = {}
    pool_idx = 0
    
    for loc, f_hints in fixed_hints.items():
        loc_hints = list(f_hints)
        needed = 5 - len(loc_hints)
        for _ in range(needed):
            if len(pool) > 0:
                loc_hints.append(pool[pool_idx % len(pool)])
                pool_idx += 1
        final_hints[loc] = loc_hints
        
    stats_path = "assets/data/locations_stats.json"
    with open(stats_path, "r", encoding="utf-8") as f:
        stats = json.load(f)
        
    locs_data = stats.get("locations", {})
    
    for loc, hints in final_hints.items():
        if loc not in locs_data:
            locs_data[loc] = {"location_chosed_times": 0}
            
        hints_private = []
        for h in hints:
            hints_private.append({
                "text": h,
                "hint_choosed_times": 0
            })
        locs_data[loc]["hints_private"] = hints_private
        
    stats["locations"] = locs_data
    
    with open(stats_path, "w", encoding="utf-8") as f:
        json.dump(stats, f, ensure_ascii=False, indent=2)
        
    # Generate report
    print("\n" + "="*50)
    print("ОТЧЕТ ПО ПЕРЕМЕШИВАНИЮ (ГРУППЫ 1-5)")
    print("="*50 + "\n")
    
    sample_locs = random.sample(list(original_hints.keys()), min(10, len(original_hints)))
    for loc in sample_locs:
        print(f"📍 Локация: {loc}")
        print("БЫЛО (Оригинальные подсказки):")
        orig = original_hints[loc]
        for idx, h in enumerate(orig):
            print(f"  {idx+1}. {h}")
        
        print("СТАЛО (После перемешивания):")
        curr = final_hints[loc]
        for idx, h in enumerate(curr):
            prefix = "[ОСТАЛОСЬ]" if idx < 2 else "[ПРИЛЕТЕЛО ИЗ ДРУГОЙ ЛОКАЦИИ]"
            print(f"  {idx+1}. {h} {prefix}")
        print("-" * 50)

if __name__ == "__main__":
    main()
