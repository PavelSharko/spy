import re
import random

freaks = [
    "Моргенштерн", "Гомер Симпсон", "Брэд Питт", "Мистер Бин", "Леди Гага",
    "Илон Маск", "Снуп Догг", "Джеки Чан", "Ольга Бузова", "Никита Джигурда",
    "Брюс Уиллис", "Дональд Трамп", "Арнольд Шварценеггер", "Ким Кардашьян", "Чак Норрис",
    "Майкл Джексон", "Человек-паук", "Губка Боб", "Конор Макгрегор", "Филипп Киркоров",
    "Лионель Месси", "Криштиану Роналду", "Хасбик", "Шрек", "Канье Уэст",
    "Майк Тайсон", "Вин Дизель", "Райан Гослинг", "Уилл Смит", "Леонардо Ди Каприо",
    "Дуэйн 'Скала' Джонсон", "Киану Ривз (Джон Уик)", "Альберт Эйнштейн", "Папич", "Дарт Вейдер",
    "Бэтмен", "Дэдпул", "Джастин Бибер", "Джокер", "Том Круз",
    "Рианна", "Бритни Спирс", "Билли Айлиш", "Капитан Америка", "Халк",
    "Терминатор", "Гарри Поттер", "Шерлок Холмс", "Фредди Меркьюри", "Мэрилин Монро",
    "Тони Старк", "Капитан Джек Воробей"
]
random.shuffle(freaks)

boring_keywords = [
    "уборщик", "уборщица", "охранник", "пассажир", "прохожий", "посетитель", 
    "турист", "дворник", "студент", "школьник", "ребенок", "бабка", "сосед", 
    "официант", "кассир", "вахтерша", "администратор", "зевака", "дети"
]
untouchable_keywords = [
    "собака", "кот", "ведро", "приведение", "призрак", "чучело", "мячик", "дохляк", "толстяк", "экспонат",
    "написал в бассейн", "киркоров", "овчарка", "медведь", "обезьяна", "цыганка"
]

with open("lib/data/locations_data.dart", "r", encoding="utf-8") as f:
    dart_code = f.read()

# Locate groups 1-5
group_matches = re.findall(r'\{\s*\"groupName\": \"(.*?)\",\s*\"locations\": \[(.*?)\]', dart_code, re.DOTALL)
first_5 = group_matches[:5]
target_locations = []
for g_name, g_locs in first_5:
    locs = [l.strip().strip('\"') for l in g_locs.split(',') if l.strip()]
    target_locations.extend(locs)

# Extract roles block
roles_block_match = re.search(r'(static const Map<String, List<String>> roles = \{)(.*?)(\};)', dart_code, re.DOTALL)
if not roles_block_match:
    print("Failed to find roles block")
    exit(1)

prefix = roles_block_match.group(1)
roles_text = roles_block_match.group(2)
suffix = roles_block_match.group(3)

# Build a dictionary to map locations to their raw text chunk in the roles string
# Because we want to do precise replacement to not break dart code formatting
loc_roles_matches = list(re.finditer(r'(\"(.*?)\": \[)(.*?)(\])', roles_text, re.DOTALL))

for match in loc_roles_matches:
    full_match = match.group(0)
    loc_name = match.group(2)
    
    if loc_name in target_locations:
        roles_list_str = match.group(3)
        # Parse individual roles
        roles = []
        for rm in re.finditer(r'\"(.*?)\"', roles_list_str):
            roles.append(rm.group(1))
            
        # Find which role to replace
        replace_idx = -1
        
        # Strategy 1: Find a boring role
        for i, r in enumerate(roles):
            if any(bkw in r.lower() for bkw in boring_keywords) and not any(ukw in r.lower() for ukw in untouchable_keywords):
                replace_idx = i
                break
                
        # Strategy 2: If no boring role, find any role that is not untouchable
        if replace_idx == -1:
            # Let's start from the end
            for i in range(len(roles)-1, -1, -1):
                r = roles[i]
                if not any(ukw in r.lower() for ukw in untouchable_keywords):
                    replace_idx = i
                    break
                    
        # Do replacement
        if replace_idx != -1 and freaks:
            new_freak = freaks.pop(0)
            old_role = roles[replace_idx]
            # Replace exactly that string in the roles_list_str
            new_roles_list_str = roles_list_str.replace(f'"{old_role}"', f'"{new_freak}"', 1)
            
            # Now replace the full match in roles_text
            roles_text = roles_text.replace(match.group(0), match.group(0).replace(roles_list_str, new_roles_list_str), 1)

new_dart_code = dart_code.replace(roles_block_match.group(0), prefix + roles_text + suffix)

with open("lib/data/locations_data.dart", "w", encoding="utf-8") as f:
    f.write(new_dart_code)

print("Groups 1-5 roles updated with freaks!")

# Now patch generate_default_cards.py to sleep 60 seconds
with open("n8n_part/generate_default_cards.py", "r", encoding="utf-8") as f:
    gen_code = f.read()

gen_code = gen_code.replace("time.sleep(10)", "time.sleep(60)")
gen_code = gen_code.replace("Waiting 10 seconds", "Waiting 60 seconds")

with open("n8n_part/generate_default_cards.py", "w", encoding="utf-8") as f:
    f.write(gen_code)
print("Generator script patched to 60 seconds sleep.")
