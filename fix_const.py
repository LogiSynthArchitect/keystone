
import os
import re

def fix_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Pattern to find const widgets that contain LineAwesomeIcons
    # This is a bit complex for regex, but let's try to find common containers
    # const Row(..., children: [ ..., Icon(LineAwesomeIcons.xxx), ... ])
    
    # A simple approach: find all occurrences of 'const' that precede 'LineAwesomeIcons'
    # and check if they are part of the same expression.
    # Since we're dealing with Flutter code, usually 'const' is followed by a class name.
    
    # Let's find all 'const' keywords.
    new_content = content
    
    # Re-read content to be safe
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    modified = False
    for i in range(len(lines)):
        if 'const' in lines[i]:
            # Look ahead a few lines (up to 5) for LineAwesomeIcons
            found_lai = False
            for j in range(i, min(i + 6, len(lines))):
                if 'LineAwesomeIcons.' in lines[j]:
                    found_lai = True
                    break
            
            if found_lai:
                # Check if 'const' is applied to something that contains LineAwesomeIcons.
                # Common patterns:
                # const Row(..., children: [
                # const Column(..., children: [
                # const [
                # const Icon(
                
                # If it's 'const Icon(LineAwesomeIcons.', we already replaced many, 
                # but maybe some missed if they had extra spaces.
                
                # Let's see if this 'const' is on the same line as a widget that *might* contain it.
                if re.search(r'const\s+\w+\s*\(', lines[i]) or re.search(r'const\s+\[', lines[i]):
                    print(f"Found potential problematic const at {file_path}:{i+1}: {lines[i].strip()}")
                    # For safety, let's only remove 'const' if it's followed by a widget and we found LAI nearby.
                    # We can use a simple replacement.
                    old_line = lines[i]
                    lines[i] = lines[i].replace('const ', '')
                    if old_line != lines[i]:
                        modified = True
                        print(f"Removed 'const' from line {i+1}")

    if modified:
        with open(file_path, 'w') as f:
            f.writelines(lines)

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                fix_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
