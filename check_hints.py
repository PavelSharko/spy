import json

with open("assets/data/locations_stats.json", "r", encoding="utf-8") as f:
    stats = json.load(f)

for loc, data in stats.get("locations", {}).items():
    h = data.get("hints_private", [])
    if len(h) < 5:
        print(f"Location {loc} has {len(h)} hints.")
