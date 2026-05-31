import re

script_path = "n8n_part/generate_default_cards.py"

with open(script_path, "r", encoding="utf-8") as f:
    code = f.read()

new_filter_code = """
    # Filter out problematic IP characters that might cause Midjourney bans
    banned_ips = [
        "Магистр Йода", "Джабба Хатт", "Чубакка", "Мандалорец", 
        "Гомер Симпсон", "Барт Симпсон", "Мардж", "Дарт Вейдер", 
        "Люк Скайуокер", "Император Палпатин"
    ]
    safe_roles = []
    for r in roles:
        if r not in banned_ips:
            safe_roles.append(r)
        else:
            safe_roles.append("Персонаж")
            
    safe_loc = location
    if "Симпсоны" in safe_loc: safe_loc = "Мультяшный город"
    if "Звездные войны" in safe_loc: safe_loc = "Огромная космическая станция"
            
    payload = {
        "location": safe_loc,
        "roles": safe_roles,
"""

code = code.replace("""    payload = {
        "location": location,
        "roles": roles,""", new_filter_code)

with open(script_path, "w", encoding="utf-8") as f:
    f.write(code)

print("Generator script patched to bypass IP filters for Simpsons and Star Wars!")
