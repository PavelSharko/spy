import re
import json
import random
import os

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
            if line.startswith('* **Подсказки:**') or line.startswith('* **Подсказки**'):
                in_hints = True
            elif in_hints and (line.startswith('- ‼️') or line.startswith('- ') or line.startswith('‼️') or line.startswith('-')):
                # clean up line
                hint_text = line
                if hint_text.startswith('- ‼️'):
                    hint_text = hint_text[4:]
                elif hint_text.startswith('- '):
                    hint_text = hint_text[2:]
                elif hint_text.startswith('‼️'):
                    hint_text = hint_text[2:]
                elif hint_text.startswith('-'):
                    hint_text = hint_text[1:]
                hint_text = hint_text.strip()
                if hint_text:
                    hints.append(hint_text)
        locations[name] = hints
    return locations

def main():
    # 1. Parse Group 9 review file
    group_9_path = "n8n_part/group_9_review.md"
    print(f"[+] Parsing corrected hints from {group_9_path}...")
    group_9_md = parse_md_hints(group_9_path)
    
    for loc, hints in group_9_md.items():
        print(f"  - {loc}: {len(hints)} hints found.")
        
    # 2. Read current stats JSON
    stats_path = "assets/data/locations_stats.json"
    with open(stats_path, "r", encoding="utf-8") as f:
        stats = json.load(f)
    
    locs_data = stats.get("locations", {})
    
    # 3. Put all Group 9 corrected hints into stats JSON temporarily (so that they are the source of truth)
    for loc, hints in group_9_md.items():
        # Update or create location key
        if loc not in locs_data:
            locs_data[loc] = {"location_chosed_times": 0}
            
        hints_private = []
        for h in hints:
            hints_private.append({
                "text": h,
                "hint_choosed_times": 0
            })
        locs_data[loc]["hints_private"] = hints_private
        
    # 4. Save to JSON first so it's committed/written
    stats["locations"] = locs_data
    with open(stats_path, "w", encoding="utf-8") as f:
        json.dump(stats, f, ensure_ascii=False, indent=2)
    print("[✓] Corrected Group 9 hints successfully merged into JSON!")
    
    # 5. Now perform Shuffle for Groups 5-10
    print("[+] Shuffling hints for Groups 5-10 (indices 4 to 9) using the new Group 9 hints...")
    with open("lib/data/locations_data.dart", "r", encoding="utf-8") as f:
        dart_code = f.read()

    groups_match = re.search(r'(static const List<Map<String, dynamic>> groups = \[\s*)(.*?)(\s*\];\s*static const Map)', dart_code, flags=re.DOTALL)
    if not groups_match:
        print("[-] Error: Could not parse groups from locations_data.dart")
        return
        
    groups_text = groups_match.group(2)
    group_blocks = re.findall(r'\{\s*"groupName": "(.*?)",\s*"locations": \[\s*(.*?)\s*\],\s*\}', groups_text, flags=re.DOTALL)

    target_locations = []
    # Indices 4 to 9 represent groups 5 to 10
    for i in range(4, 10):
        if i < len(group_blocks):
            loc_list_text = group_blocks[i][1]
            locs = re.findall(r'"([^"]+)"', loc_list_text)
            target_locations.extend(locs)

    print(f"[+] Found {len(target_locations)} locations for groups 5-10.")

    # Re-read stats JSON
    with open(stats_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    locs_data = data.get("locations", {})

    pool = []
    # Collect hints 3, 4, 5 from groups 5-10
    for loc in target_locations:
        if loc in locs_data:
            hints = locs_data[loc].get("hints_private", [])
            if len(hints) > 2:
                # Add hints from index 2 onwards to pool
                pool.extend([h["text"] for h in hints[2:]])
        else:
            print(f"[-] Warning: Location {loc} not found in locations_stats.json!")

    print(f"[+] Collected {len(pool)} hints for shuffling.")

    # Shuffle the pool
    random.shuffle(pool)

    # Reassign back, keeping first 2 hints locked
    pool_idx = 0
    for loc in target_locations:
        if loc in locs_data:
            hints = locs_data[loc].get("hints_private", [])
            if len(hints) > 2:
                # Keep first 2 original hints
                new_hints = hints[:2]
                num_to_replace = len(hints) - 2
                
                # Take new hints from the shuffled pool
                for _ in range(num_to_replace):
                    new_hints.append({
                        "text": pool[pool_idx % len(pool)],
                        "hint_choosed_times": 0
                    })
                    pool_idx += 1
                
                locs_data[loc]["hints_private"] = new_hints

    data["locations"] = locs_data

    # Save final JSON
    with open(stats_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("[✓] Successfully shuffled and saved final hints for Groups 5-10!")

if __name__ == "__main__":
    main()
