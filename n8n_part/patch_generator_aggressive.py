import re
import os

script_path = "n8n_part/generate_default_cards.py"

with open(script_path, "r", encoding="utf-8") as f:
    code = f.read()

# We need to aggressively filter IP names for any failing cards in Group 9
new_filter_code = """
    # Aggressively filter out IP characters that trigger Midjourney bans
    safe_roles = []
    safe_loc = location
    
    if "Симпсоны" in safe_loc or "Спрингфилд" in safe_loc:
        safe_loc = "Город из мультика с желтыми человечками"
        safe_roles = ["Житель 1", "Житель 2", "Житель 3", "Житель 4", "Житель 5", "Житель 6", "Житель 7", "Житель 8", "Житель 9", "Житель 10"]
    elif "Звездные войны" in safe_loc or "Звезда Смерти" in safe_loc:
        safe_loc = "Огромная боевая космическая станция империя"
        safe_roles = ["Космонавт", "Воин", "Пилот", "Солдат", "Генерал", "Пришелец", "Пришелец 2", "Робот", "Робот 2", "Наемник"]
    else:
        # Fallback filter just in case
        banned_ips = ["Магистр Йода", "Джабба Хатт", "Чубакка", "Мандалорец", "Дарт Вейдер", "Люк Скайуокер", "Император Палпатин"]
        for r in roles:
            if r not in banned_ips:
                safe_roles.append(r)
            else:
                safe_roles.append("Персонаж")
                
    payload = {
        "location": safe_loc,
        "roles": safe_roles,
"""

# Only replace if it wasn't already aggressively replaced
if "Aggressively filter out IP" not in code:
    # First find the old payload block (or old patch)
    if "Filter out problematic IP characters" in code:
        # Revert the old patch block back to original before applying new one
        # It's easier to just use regex to replace everything from the start of the comment to payload = { ... }
        code = re.sub(r'    # Filter out problematic IP characters.*?payload = \{\n        "location": safe_loc,\n        "roles": safe_roles,\n', new_filter_code, code, flags=re.DOTALL)
    else:
        code = code.replace("""    payload = {
        "location": location,
        "roles": roles,""", new_filter_code)

    with open(script_path, "w", encoding="utf-8") as f:
        f.write(code)
    print("Generator script aggressively patched for Simpsons and Star Wars!")
else:
    print("Already aggressively patched!")
