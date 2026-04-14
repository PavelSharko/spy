import sys
import subprocess
import json
import re

def fix_errors():
    print("Running dart analyze...")
    result = subprocess.run(['dart', 'analyze', '--format=json'], capture_output=True, text=True)
    out = result.stdout
    
    # Extract JSON part
    if "{" in out:
        out = out[out.find("{"):]
    
    try:
        data = json.loads(out)
    except Exception as e:
        print("Failed to parse json. Trying to fix using regex blindly across files.")
        return blindly_fix_consts()
        
    diagnostics = data.get("diagnostics", [])
    
    files_to_fix = {}
    for d in diagnostics:
        filepath = d["location"]["file"]
        line = d["location"]["range"]["start"]["line"]
        col = d["location"]["range"]["start"]["column"]
        code = d["code"]
        
        if code in ["invalid_constant", "undefined_named_parameter"]:
            if filepath not in files_to_fix:
                files_to_fix[filepath] = []
            files_to_fix[filepath].append((line, col, code))

    for filepath, errs in files_to_fix.items():
        with open(filepath, "r") as f:
            lines = f.readlines()
            
        modified = False
        
        # Sort errors from bottom to top so line replacements don't shift line numbers 
        # (Actually we are doing line replacement without shifting line count, so it's fine)
        for (line, col, code) in reversed(sorted(errs, key=lambda x: x[0])):
            l = line - 1
            if l < 0 or l >= len(lines):
                continue
            
            # If invalid constant, we look backwards on current and previous lines to remove `const `
            # A common case is `const Text(` or `const SizedBox(` or `const BoxDecoration(` or `side: const BorderSide`
            target_lines = [l, l-1, l-2, l-3]
            for tl in target_lines:
                if 0 <= tl < len(lines):
                    # Find 'const ' and remove it
                    if 'const ' in lines[tl] and 'AppStyles' in ''.join(lines[tl:l+1]):
                        # Make sure we don't just remove `const` blindly, but we'll take the risk inside this narrow window
                        lines[tl] = lines[tl].replace("const ", "")
                        modified = True
                        break
                    elif 'const ' in lines[tl]:
                        # If AppStyles is nearby
                        lines[tl] = lines[tl].replace("const ", "")
                        modified = True
                        break

        if modified:
            with open(filepath, "w") as f:
                f.writelines(lines)
            print(f"Fixed {filepath}")

def blindly_fix_consts():
    import os
    for root, _, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                
                # Replace typical const wrappers followed by something containing AppStyles
                # Just remove `const` everywhere there's a problem? No.
                # Actually, simply removing `const ` before typical widgets in these files.
                # Let's remove `const ` before Text, Icon, BoxDecoration, BorderSide, EdgeInsets, Padding, TextStyle, BoxConstraints
                patterns = [
                    r'const\s+(Text\()',
                    r'const\s+(Icon\()',
                    r'const\s+(BoxDecoration\()',
                    r'const\s+(BorderSide\()',
                    r'const\s+(TextStyle\()',
                    r'const\s+(Padding\()',
                    r'const\s+(EdgeInsets\.)',
                    r'const\s+(BoxConstraints\()',
                    r'const\s+(SizedBox\()',
                    r'const\s+(\[)'
                ]
                
                orig = content
                for p in patterns:
                    content = re.sub(p, r'\1', content)
                
                if orig != content:
                    with open(filepath, 'w') as f:
                        f.write(content)

fix_errors()
