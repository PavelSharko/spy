#!/usr/bin/env python3
import os
import re
import sys
import json
import time
import base64
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed

# n8n Webhook configuration
WEBHOOK_PROD = "https://n8n.sharksbots.com/webhook/get-scene-picture"
WEBHOOK_TEST = "https://n8n.sharksbots.com/webhook-test/get-scene-picture"
USERNAME = "spygame"
PASSWORD = "secretspy"

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCATIONS_FILE = os.path.join(BASE_DIR, "lib", "data", "locations_data.dart")
ASSETS_DIR = os.path.join(BASE_DIR, "assets", "images", "defaults")

def parse_locations_data():
    """Parses locations_data.dart to extract groups and roles maps dynamically."""
    if not os.path.exists(LOCATIONS_FILE):
        print(f"[-] Error: locations_data.dart not found at: {LOCATIONS_FILE}")
        sys.exit(1)

    with open(LOCATIONS_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Parse groups list
    # We find groups inside the `static const List<Map<String, dynamic>> groups = [...]` block
    groups_match = re.search(r"static const List<Map<String, dynamic>> groups = \[(.*?)\];\s*static const Map", content, re.DOTALL)
    if not groups_match:
        # Try a broader regex if structure differs slightly
        groups_match = re.search(r"groups = \[(.*?)\];", content, re.DOTALL)
    
    if not groups_match:
        print("[-] Error: Could not find groups block in locations_data.dart")
        sys.exit(1)

    groups_block = groups_match.group(1)
    
    # Extract each group object: {"groupName": "...", "locations": [...]}
    group_blocks = re.findall(r"\{\s*\"groupName\":\s*\"([^\"]+)\",\s*\"locations\":\s*\[(.*?)\]\s*,?\s*\},?", groups_block, re.DOTALL)
    
    parsed_groups = []
    for g_name, locs_text in group_blocks:
        locs = [l.strip().strip('"').strip("'") for l in locs_text.split(",") if l.strip()]
        parsed_groups.append({
            "groupName": g_name,
            "locations": locs
        })

    # 2. Parse roles map
    # static const Map<String, List<String>> roles = { ... }
    roles_match = re.search(r"roles = \{(.*?)\};", content, re.DOTALL)
    parsed_roles = {}
    if roles_match:
        roles_block = roles_match.group(1)
        # Parse: "Location": [ "Role1", "Role2" ]
        entries = re.findall(r"\"([^\"]+)\":\s*\[(.*?)\]", roles_block, re.DOTALL)
        for loc, r_text in entries:
            r_list = [r.strip().strip('"').strip("'") for r in r_text.split(",") if r.strip()]
            parsed_roles[loc] = r_list

    return parsed_groups, parsed_roles

def fetch_and_save_image(url, location, roles, output_path, auth_header):
    """Sends POST request to n8n webhook and saves generated image bytes."""

    # Filter out problematic Star Wars IP characters that might cause Midjourney bans
    safe_roles = []
    for r in roles:
        if r not in ["Магистр Йода", "Джабба Хатт", "Чубакка", "Мандалорец"]:
            safe_roles.append(r)
        else:
            safe_roles.append("Инопланетянин")
            
    payload = {
        "location": location,
        "roles": safe_roles,

        "type_query": "gen_card_for_location",
        "generation_style": "как настоящее фото",
        "need_add_faces": False
    }
    
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data)
    req.add_header("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    req.add_header("Authorization", auth_header)
    req.add_header("Content-Type", "application/json")
    
    try:
        # Timeout at 90s because image generation can be slow
        with urllib.request.urlopen(req, timeout=90) as response:
            if response.status == 200:
                image_bytes = response.read()
                if len(image_bytes) > 1000:  # Valid image check
                    os.makedirs(os.path.dirname(output_path), exist_ok=True)
                    with open(output_path, "wb") as out_f:
                        out_f.write(image_bytes)
                    return True, len(image_bytes)
                else:
                    return False, "Response body was too small (invalid image)"
            else:
                return False, f"Server returned status code {response.status}"
    except urllib.error.HTTPError as e:
        return False, f"HTTP Error {e.code}: {e.read().decode('utf-8', errors='ignore')}"
    except Exception as e:
        return False, f"Exception: {str(e)}"

def main():
    use_test = "--test" in sys.argv
    webhook_url = WEBHOOK_TEST if use_test else WEBHOOK_PROD
    
    print("=" * 60)
    print("🎨 SPY GAME: AUTO IMAGE GENERATION SCRIPT")
    print(f"[+] Target Webhook: {webhook_url}")
    print(f"[+] Output Directory: {ASSETS_DIR}")
    print("=" * 60)

    # 1. Parse dart file
    print("[+] Parsing locations_data.dart...")
    groups, roles = parse_locations_data()
    
    total_locations = sum(len(g["locations"]) for g in groups)
    print(f"[+] Successfully loaded {len(groups)} groups with {total_locations} total locations!")

    # 2. Build list of pending tasks
    tasks = []
    auth_str = base64.b64encode(f"{USERNAME}:{PASSWORD}".encode("utf-8")).decode("utf-8")
    auth_header = f"Basic {auth_str}"

    for g_idx, group in enumerate(groups):
        g_num = g_idx + 1
        group_dir = os.path.join(ASSETS_DIR, f"group_{g_num}")
        
        for l_idx, location in enumerate(group["locations"]):
            l_num = l_idx + 1
            filename = f"{g_num}-{l_num}.jpeg"
            filepath = os.path.join(group_dir, filename)
            
            # Skip if file already exists and is non-empty (allows resume)
            if os.path.exists(filepath) and os.path.getsize(filepath) > 1000:
                continue
                
            loc_roles = roles.get(location, ["Гражданин", "Шпион"])
            tasks.append({
                "location": location,
                "roles": loc_roles,
                "filepath": filepath,
                "filename": f"group_{g_num}/{filename}"
            })

    total_pending = len(tasks)
    if total_pending == 0:
        print("[+] All 100 location cards are already generated and present in the asset folders!")
        return

    print(f"[+] Found {total_pending} missing cards out of {total_locations} total locations.")
    print("[+] Starting generation in batches of 10 requests...")

    # 3. Execute in batches of 10
    batch_size = 10
    success_count = 0
    fail_count = 0
    
    for i in range(0, total_pending, batch_size):
        batch = tasks[i:i+batch_size]
        print(f"\n[~] Processing batch {i // batch_size + 1} ({len(batch)} requests)...")
        
        # Parallel fetch inside the batch to speed up
        with ThreadPoolExecutor(max_workers=batch_size) as executor:
            futures = {
                executor.submit(
                    fetch_and_save_image, 
                    webhook_url, 
                    t["location"], 
                    t["roles"], 
                    t["filepath"], 
                    auth_header
                ): t for t in batch
            }
            
            for future in as_completed(futures):
                task = futures[future]
                try:
                    success, result = future.result()
                    if success:
                        print(f"  [✓] Successfully generated: {task['location']} -> {task['filename']} ({result} bytes)")
                        success_count += 1
                    else:
                        print(f"  [✗] Failed to generate {task['location']} ({task['filename']}): {result}")
                        fail_count += 1
                except Exception as exc:
                    print(f"  [✗] Task generated an exception for {task['location']}: {exc}")
                    fail_count += 1
        
        # Throttling between batches to be gentle on n8n and Gemini APIs
        if i + batch_size < total_pending:
            print("[~] Waiting 60 seconds before starting the next batch to respect API rate-limits...")
            time.sleep(60)

    print("\n" + "=" * 60)
    print("🏁 GENERATION RUN COMPLETED!")
    print(f"[+] Successfully generated: {success_count} cards")
    print(f"[+] Failed: {fail_count} cards")
    print(f"[+] Total assets now complete: {total_locations - (total_pending - success_count)}/100")
    print("=" * 60)

if __name__ == "__main__":
    main()
