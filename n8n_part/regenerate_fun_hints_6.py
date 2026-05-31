import re
import random

with open("n8n_part/group_6_review.md", "r", encoding="utf-8") as f:
    content = f.read()

# Extract all hints
hints = re.findall(r'  - ‼️ (.*?)\n', content)

sad_keywords = [
    "безысходност", "спасение", "жуткие", "темнот", "ограничения", "заболеешь",
    "стресс", "клаустрофоб", "бесполезный", "предател", "паника", "сыро", "холодно",
    "сойти с ума", "выживания", "слезы", "плачут", "жесткие рамки", "опасное место", "свободное время"
]

fun_hints = [
    "Если начнется дискотека, кто первый пойдет в пляс?",
    "Спроси про то, где тут наливают",
    "Как насчет громкой музыки и танцев до утра?",
    "Вопрос про дресс-код на местной вечеринке",
    "Часто ли тут устраивают пранки?",
    "Можно ли сюда заказать пиццу и клоунов?",
    "Про веселье — тут вообще умеют отрываться?",
    "Если я принесу кальян, меня пустят?",
    "Кто тут самый главный тусовщик?",
    "Тут можно устроить свидание вслепую?",
    "Спроси про то, как часто тут смеются до слез",
    "Вопрос про бесплатные коктейли",
    "Если тут врубить рэп на полную, что будет?",
    "Как насчет азартных игр на раздевание?",
    "Можно ли тут снять тик-ток и не получить по шее?",
    "Спроси про наличие караоке"
]
random.shuffle(fun_hints)

kept_hints = []
replaced_count = 0

for h in hints:
    is_sad = any(kw in h.lower() for kw in sad_keywords)
    if is_sad and replaced_count < len(fun_hints):
        kept_hints.append(fun_hints[replaced_count])
        replaced_count += 1
    else:
        kept_hints.append(h)

# If we haven't replaced 15, let's just replace some randomly
while replaced_count < 15:
    idx_to_replace = random.randint(0, len(kept_hints)-1)
    if kept_hints[idx_to_replace] not in fun_hints:
        kept_hints[idx_to_replace] = fun_hints[replaced_count]
        replaced_count += 1

random.shuffle(kept_hints)

locations = []
blocks = re.split(r'## \d+\. (.+)', content)[1:]

locations_list = []
for i in range(0, len(blocks), 2):
    loc_name = blocks[i].strip()
    locations_list.append(loc_name)

new_locations = {}
hint_index = 0

for loc in locations_list:
    assigned_hints = []
    for _ in range(5):
        assigned_hints.append(kept_hints[hint_index])
        hint_index += 1
    new_locations[loc] = assigned_hints

for loc in locations_list:
    replacement = ""
    for h in new_locations[loc]:
        replacement += f"  - ‼️ {h}\n"
    
    # regex replace the existing hints section (which currently has 5 hints)
    pattern = r'(## \d+\. ' + re.escape(loc) + r'\n\* \*\*Роли:\*\*.*?\n\* \*\*Подсказки:\*\*\n)(?:  - ‼️ .*?\n)*'
    content = re.sub(pattern, r'\g<1>' + replacement, content)

with open("n8n_part/group_6_review.md", "w", encoding="utf-8") as f:
    f.write(content)

print(f"Replaced {replaced_count} sad hints with fun ones and reshuffled!")

