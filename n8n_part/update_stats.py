#!/usr/bin/env python3
import os
import re
import json

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MD_FILE = os.path.join(BASE_DIR, "n8n_part", "group_1_review.md")
STATS_FILE = os.path.join(BASE_DIR, "assets", "data", "locations_stats.json")

def parse_md_hints():
    if not os.path.exists(MD_FILE):
        print(f"[-] Error: Markdown file not found at: {MD_FILE}")
        return None

    with open(MD_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    # Split by location headings: ## Number. Name
    sections = re.split(r"\n## \d+\.\s*", content)
    
    parsed_data = {}
    for sec in sections[1:]:  # Skip the header section before the first heading
        lines = sec.strip().split("\n")
        if not lines:
            continue
            
        location_name = lines[0].strip()
        hints = []
        
        # Look for the hints section
        in_hints = False
        for line in lines[1:]:
            line_str = line.strip()
            if line_str.startswith("* **Подсказки:**"):
                in_hints = True
                continue
            if in_hints:
                # If we encounter another section or divider, stop
                if line_str.startswith("---") or line_str.startswith("* **Роли:**") or line_str.startswith("## "):
                    break
                # Parse bullet point hint
                if line_str.startswith("-"):
                    hint_text = line_str[1:].strip()
                    # Remove any leading emojis if they weren't cleaned up by the user
                    hint_text = re.sub(r"^[‼️\s]+", "", hint_text).strip()
                    if hint_text:
                        hints.append(hint_text)
                        
        parsed_data[location_name] = hints

    return parsed_data

def update_json_stats(parsed_data):
    if not os.path.exists(STATS_FILE):
        print(f"[-] Error: stats JSON file not found at: {STATS_FILE}")
        return False

    with open(STATS_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    if "locations" not in data:
        data["locations"] = {}

    for loc_name, hints in parsed_data.items():
        print(f"[+] Updating hints for '{loc_name}' ({len(hints)} hints found)...")
        
        # If location doesn't exist, create it
        if loc_name not in data["locations"]:
            data["locations"][loc_name] = {
                "location_chosed_times": 0,
                "hints_private": []
            }
            
        # We replace the hints_private array entirely
        new_hints = []
        existing_hints = {h["text"]: h.get("hint_choosed_times", 0) for h in data["locations"][loc_name].get("hints_private", [])}
        
        for h_text in hints:
            # Preserve choose times if the hint is exactly identical, otherwise default to 0
            choosed_times = existing_hints.get(h_text, 0)
            new_hints.append({
                "text": h_text,
                "hint_choosed_times": choosed_times
            })
            
        data["locations"][loc_name]["hints_private"] = new_hints

    # Write back the updated JSON with pretty printing and original Russian characters
    with open(STATS_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
    print("[✓] JSON stats file successfully updated!")
    return True

def main():
    print("=" * 60)
    print("🔄 SPY GAME: UPDATING STATS JSON")
    print("=" * 60)
    
    parsed_data = parse_md_hints()
    if not parsed_data:
        print("[-] Failed to parse markdown.")
        return
        
    print(f"[+] Parsed {len(parsed_data)} locations from markdown.")
    success = update_json_stats(parsed_data)
    if success:
        print("[+] Done!")

if __name__ == "__main__":
    main()
