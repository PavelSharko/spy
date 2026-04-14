import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content
    
    # 1. Remove imports
    content = re.sub(r"import\s+['\"].*?animated_pattern_background\.dart['\"];\s*", "", content)
    
    # 2. Replace AnimatedPatternBackground( with Container(
    content = content.replace("AnimatedPatternBackground(", "Container(")
    
    # 3. Remove unsupported params from AnimatedPatternBackground completely
    content = re.sub(r"^\s*lineColor:.*?\n", "", content, flags=re.MULTILINE)
    content = re.sub(r"^\s*lineHeight:.*?\n", "", content, flags=re.MULTILINE)
    content = re.sub(r"^\s*gapHeight:.*?\n", "", content, flags=re.MULTILINE)
    
    # 4. Remove 'const ' before AppStyles.<prop>
    # Handle possible spaces
    content = re.sub(r"\bconst\s+AppStyles\.", "AppStyles.", content)
    
    # 5. AppStyles.deriveStripeColor(...) -> Colors.transparent
    content = re.sub(r"AppStyles\.deriveStripeColor\([^)]+\)", "Colors.transparent", content)

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
