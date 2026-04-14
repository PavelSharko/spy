import re
files = [
    'lib/screens/role_guess_screen.dart',
    'lib/screens/rules_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/spy_last_word_screen.dart',
    'lib/screens/voting_screen.dart',
    'lib/widgets/camera_overlay.dart',
    'lib/widgets/game_card.dart'
]
patterns = [
    r'\bconst\s+(Text\()',
    r'\bconst\s+(Icon\()',
    r'\bconst\s+(BoxDecoration\()',
    r'\bconst\s+(BorderSide\()',
    r'\bconst\s+(TextStyle\()',
    r'\bconst\s+(Padding\()',
    r'\bconst\s+(EdgeInsets\.)',
    r'\bconst\s+(BoxConstraints\()',
    r'\bconst\s+(SizedBox\()',
    r'\bconst\s+(\[)',
    r'\bconst\s+(Row\()',
    r'\bconst\s+(Column\()',
    r'\bconst\s+(ListView\()',
    r'\bconst\s+(Expanded\()'
]

for fp in files:
    with open(fp, 'r') as f:
        content = f.read()
    orig = content
    for p in patterns:
        content = re.sub(p, r'\1', content)
    if orig != content:
        with open(fp, 'w') as f:
            f.write(content)
        print("Fixed", fp)
