import os
import re
import json
import base64
import requests
import time

dart_file = "lib/data/locations_data.dart"
with open(dart_file, 'r', encoding='utf-8') as f:
    content = f.read()

roles_match = re.search(r'static const Map<String, List<String>> roles = \{(.*?)\};', content, re.DOTALL)
if not roles_match:
    print("Could not find roles map")
    exit(1)

roles_str = roles_match.group(1)
# Мы парсим ключи (локации) и их роли.
locations_dict = {}
# Найдём все совпадения "Локация": ["роль1", "роль2"]
loc_matches = re.finditer(r'"([^"]+)":\s*\[(.*?)\]', roles_str, re.DOTALL)
for match in loc_matches:
    loc_name = match.group(1)
    roles_array_str = match.group(2)
    # Вытащим все строковые значения из массива
    roles = re.findall(r'"([^"]+)"', roles_array_str)
    locations_dict[loc_name] = roles

locations = list(locations_dict.keys())
print(f"Found {len(locations)} locations")

url = "https://n8n.sharksbots.com/webhook/get-scene-picture"
username = "spygame"
password = "secretspy"
auth = base64.b64encode(f"{username}:{password}".encode()).decode()
headers = {
    "Authorization": f"Basic {auth}",
    "Content-Type": "application/json"
}

os.makedirs("assets/images/defaults/endgame/win", exist_ok=True)
os.makedirs("assets/images/defaults/endgame/loss", exist_ok=True)

def normalize_name(name):
    name = name.lower()
    name = name.replace(" ", "_")
    name = re.sub(r'[^a-zа-я0-9_]', '', name)
    return name

# Запускаем для всех локаций
for i, loc in enumerate(locations):
    norm_loc = normalize_name(loc)
    
    # Win
    win_path = f"assets/images/defaults/endgame/win/{norm_loc}.jpg"
    if not os.path.exists(win_path):
        payload_win = {
            "location": loc,
            "roles": locations_dict[loc], 
            "type_query": "gen_card_for_finish_round",
            "generation_style": "как настоящее фото",
            "faces_for_role": False,
            "spy_is_win": True
        }
        res_win = requests.post(url, json=payload_win, headers=headers)
        if res_win.status_code == 200 and len(res_win.content) > 100:
            with open(win_path, 'wb') as f:
                f.write(res_win.content)
            print(f"[{i+1}/5] Saved WIN for {loc} (Size: {len(res_win.content)} bytes)")
        else:
            print(f"[{i+1}/5] Failed WIN for {loc} - {res_win.status_code} (Size: {len(res_win.content)} bytes)")
            if len(res_win.content) < 500:
                print(res_win.text)
        time.sleep(6) # Задержка 6 секунд (10 запросов в минуту)
    else:
        print(f"[{i+1}/5] WIN already exists for {loc}")
        
    # Loss
    loss_path = f"assets/images/defaults/endgame/loss/{norm_loc}.jpg"
    if not os.path.exists(loss_path):
        payload_loss = {
            "location": loc,
            "roles": locations_dict[loc],
            "type_query": "gen_card_for_finish_round",
            "generation_style": "как настоящее фото",
            "faces_for_role": False,
            "spy_is_win": False
        }
        res_loss = requests.post(url, json=payload_loss, headers=headers)
        if res_loss.status_code == 200 and len(res_loss.content) > 100:
            with open(loss_path, 'wb') as f:
                f.write(res_loss.content)
            print(f"[{i+1}/5] Saved LOSS for {loc} (Size: {len(res_loss.content)} bytes)")
        else:
            print(f"[{i+1}/5] Failed LOSS for {loc} - {res_loss.status_code} (Size: {len(res_loss.content)} bytes)")
            if len(res_loss.content) < 500:
                print(res_loss.text)
        time.sleep(6) # Задержка 6 секунд (10 запросов в минуту)
    else:
        print(f"[{i+1}/5] LOSS already exists for {loc}")

print("Done")
