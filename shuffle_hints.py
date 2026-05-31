import re
import json
import random

def main():
    # 1. Get the list of locations for Groups 5 to 10 (indices 4 to 9)
    with open("lib/data/locations_data.dart", "r", encoding="utf-8") as f:
        dart_code = f.read()

    groups_match = re.search(r'(static const List<Map<String, dynamic>> groups = \[\s*)(.*?)(\s*\];\s*static const Map)', dart_code, flags=re.DOTALL)
    if not groups_match:
        print("Could not parse groups")
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

    print(f"Found {len(target_locations)} locations for groups 5-10.")

    # 2. Read locations_stats.json
    with open("assets/data/locations_stats.json", "r", encoding="utf-8") as f:
        data = json.load(f)

    locs_data = data.get("locations", {})

    pool = []
    # Collect hints 3, 4, 5
    for loc in target_locations:
        if loc in locs_data:
            hints = locs_data[loc].get("hints_private", [])
            if len(hints) >= 5:
                # Add hints index 2, 3, 4 to pool
                pool.extend(hints[2:])
            elif len(hints) > 2:
                pool.extend(hints[2:])
        else:
            print(f"Location {loc} not found in locations_stats.json!")

    print(f"Collected {len(pool)} hints for shuffling.")

    # 3. Shuffle
    random.shuffle(pool)

    # 4. Reassign
    pool_idx = 0
    for loc in target_locations:
        if loc in locs_data:
            hints = locs_data[loc].get("hints_private", [])
            if len(hints) > 2:
                new_hints = hints[:2]
                num_to_replace = len(hints) - 2
                
                # Take from pool
                for _ in range(num_to_replace):
                    if pool_idx < len(pool):
                        new_hints.append(pool[pool_idx])
                        pool_idx += 1
                
                locs_data[loc]["hints_private"] = new_hints

    data["locations"] = locs_data

    # 5. Save
    with open("assets/data/locations_stats.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("Successfully shuffled and saved hints!")

if __name__ == "__main__":
    main()
