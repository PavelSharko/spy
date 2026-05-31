import re
import json
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
    # 1. Parse md files 5 to 10
    all_locations = {}
    for i in range(5, 11):
        locs = parse_md_hints(f"n8n_part/group_{i}_review.md")
        all_locations.update(locs)
        
    print(f"Parsed {len(all_locations)} locations from MD files 5-10.")
    
    # 2. Extract hints to pool
    pool = []
    fixed_hints = {} # name -> [hint1, hint2]
    
    for loc, hints in all_locations.items():
        if len(hints) >= 2:
            fixed_hints[loc] = hints[:2]
            pool.extend(hints[2:])
        else:
            fixed_hints[loc] = hints
            print(f"Warning: Location {loc} has less than 2 hints")
            
    print(f"Collected {len(pool)} hints to shuffle.")
    
    # 3. Shuffle pool
    random.shuffle(pool)
    
    # 4. Reassign hints
    final_hints = {}
    pool_idx = 0
    
    for loc, f_hints in fixed_hints.items():
        loc_hints = list(f_hints)
        needed = 5 - len(loc_hints)
        for _ in range(needed):
            if True:
                loc_hints.append(pool[pool_idx % len(pool)])
                pool_idx += 1
        final_hints[loc] = loc_hints
        
    # 5. Read locations_stats.json
    stats_path = "assets/data/locations_stats.json"
    with open(stats_path, "r", encoding="utf-8") as f:
        stats = json.load(f)
        
    locs_data = stats.get("locations", {})
    
    # Clean up garbage from root
    keys_to_delete = [k for k in stats.keys() if k != "locations"]
    for k in keys_to_delete:
        del stats[k]
        
    # Apply to locs_data
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
    
    # 6. Save back
    with open(stats_path, "w", encoding="utf-8") as f:
        json.dump(stats, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully updated locations_stats.json for {len(final_hints)} locations.")

if __name__ == "__main__":
    main()
