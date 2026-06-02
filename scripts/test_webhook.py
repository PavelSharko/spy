import base64
import requests

url = "https://n8n.sharksbots.com/webhook/get-scene-picture"
username = "spygame"
password = "secretspy"
auth = base64.b64encode(f"{username}:{password}".encode()).decode()
headers = {
    "Authorization": f"Basic {auth}",
    "Content-Type": "application/json"
}

payload = {
    "location": "Город на луне",
    "roles": [], 
    "type_query": "gen_card_for_finish_round",
    "generation_style": "как настоящее фото",
    "faces_for_role": False,
    "spy_is_win": True
}
res = requests.post(url, json=payload, headers=headers)
print("Status:", res.status_code)
print("Content length:", len(res.content))
if len(res.content) < 500:
    print("Response:", res.text)
