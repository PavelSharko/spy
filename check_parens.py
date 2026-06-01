with open("lib/screens/game_round_screen.dart", "r") as f:
    lines = f.readlines()

for i, line in enumerate(lines[1340:1390]):
    print(f"{1340+i}: {line.rstrip()}")
