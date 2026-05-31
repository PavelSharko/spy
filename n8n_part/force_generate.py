import urllib.request
import urllib.error
import json
import base64
import os

url = "https://n8n.sharksbots.com/webhook/get-scene-picture"
auth_str = base64.b64encode(b"spygame:secretspy").decode("utf-8")
auth_header = f"Basic {auth_str}"

def fetch_safe(loc_name, output_path):
    safe_roles = ["Персонаж " + str(i) for i in range(1, 11)]
    payload = {
        "location": loc_name,
        "roles": safe_roles,
        "type_query": "gen_card_for_location",
        "generation_style": "как настоящее фото",
        "need_add_faces": False
    }
    
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data)
    req.add_header("User-Agent", "Mozilla/5.0")
    req.add_header("Authorization", auth_header)
    req.add_header("Content-Type", "application/json")
    
    print(f"Requesting {loc_name}...")
    try:
        with urllib.request.urlopen(req, timeout=90) as response:
            if response.status == 200:
                image_bytes = response.read()
                if len(image_bytes) > 1000:
                    with open(output_path, "wb") as out_f:
                        out_f.write(image_bytes)
                    print(f"Success for {loc_name}! Saved to {output_path}")
                else:
                    print(f"Failed for {loc_name}: Body too small")
            else:
                print(f"Failed for {loc_name}: Status {response.status}")
    except Exception as e:
        print(f"Failed for {loc_name}: Exception {e}")

fetch_safe("Красивый яркий мультяшный городок в желтых тонах 3d", "assets/images/defaults/group_9/9-2.jpeg")
fetch_safe("Космическая станция в космосе sci-fi", "assets/images/defaults/group_9/9-5.jpeg")
