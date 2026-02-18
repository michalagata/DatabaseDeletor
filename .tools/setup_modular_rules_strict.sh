#!/bin/bash

# ==============================================================================
# FIXED MODULAR RULES SETUP (Force Bottom Append)
# ==============================================================================
# 1. Finds .mdc files RECURSIVELY in .cursor/
# 2. Compiles them to .github/rules/*.md
# 3. FORCES the index to be at the BOTTOM of copilot-instructions.md
#    (It cuts out the old index wherever it is, and appends the new one at the end)
# ==============================================================================

# 1. AUTO-DETECT ROOT
# Ensure we run from project root, even if called from .tools
current_dir=$(basename "$PWD")
if [ "$current_dir" == ".tools" ]; then
    echo ">> Detected execution from .tools directory. Moving to project root..."
    cd ..
fi

HIDDEN_TOOLS_DIR=".tools"
mkdir -p "$HIDDEN_TOOLS_DIR"

echo ">> Updating Compiler Script in '$HIDDEN_TOOLS_DIR'..."

# ------------------------------------------------------------------------------
# 2. GENERATE THE PYTHON SCRIPT (With "Cut & Append" Logic)
# ------------------------------------------------------------------------------
cat > "$HIDDEN_TOOLS_DIR/compile_mdc.py" <<'EOF'
import os
import sys

# PATHS
SCRIPT_LOC = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_LOC, '..'))
CURSOR_DIR = os.path.join(PROJECT_ROOT, '.cursor')
RULES_DEST_DIR = os.path.join(PROJECT_ROOT, '.github', 'rules')
INSTRUCTIONS_FILE = os.path.join(PROJECT_ROOT, '.github', 'copilot-instructions.md')

# MARKERS
START_MARKER = ""
END_MARKER = ""

def parse_mdc_and_save(filepath):
    """Reads MDC, strips YAML, saves to destination."""
    filename = os.path.basename(filepath)
    base_name = os.path.splitext(filename)[0]
    dest_path = os.path.join(RULES_DEST_DIR, f"{base_name}.md")
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        description = "General rules"
        # Lightweight YAML extraction
        if content.startswith('---'):
            try:
                end_yaml = content.find('---', 3)
                if end_yaml != -1:
                    yaml_content = content[3:end_yaml]
                    clean_content = content[end_yaml+3:].strip()
                    for line in yaml_content.splitlines():
                        if line.strip().startswith('description:'):
                            description = line.split(':', 1)[1].strip()
                            break
                else:
                    clean_content = content
            except:
                clean_content = content
        else:
            clean_content = content

        final_content = (
            f"\n"
            f"# RULE SET: {base_name.upper()}\n"
            f"> Description: {description}\n\n"
            f"{clean_content}"
        )

        with open(dest_path, 'w', encoding='utf-8') as f:
            f.write(final_content)
            
        return (f"{base_name}.md", description)

    except Exception as e:
        print(f"Error processing {filename}: {e}")
        return None

def force_update_instructions_at_bottom(rule_index):
    """
    Removes existing index block (wherever it is) and appends new one to the END.
    """
    
    # 1. Generate the new index block content
    new_block_lines = [START_MARKER]
    new_block_lines.append("## 11) DYNAMIC RULE INDEX (MANDATORY)")
    new_block_lines.append("The following specialized rule files are active. **Copilot must read the specific file** if the user request pertains to its domain:\n")
    
    for filename, desc in rule_index:
        new_block_lines.append(f"- **{filename}**: {desc}")
        new_block_lines.append(f"  (Location: `.github/rules/{filename}`)")
        
    new_block_lines.append("\n> **INSTRUCTION:** Identify which rule set applies, read the file from `.github/rules/`, and strictly follow its content.")
    new_block_lines.append(END_MARKER)
    new_block_str = "\n".join(new_block_lines)

    # 2. Handle File Existence
    if not os.path.exists(INSTRUCTIONS_FILE):
        os.makedirs(os.path.dirname(INSTRUCTIONS_FILE), exist_ok=True)
        with open(INSTRUCTIONS_FILE, 'w', encoding='utf-8') as f:
            f.write("# Copilot Instructions\n\n" + new_block_str)
        return

    # 3. Read Content
    with open(INSTRUCTIONS_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # 4. REMOVE OLD BLOCK (Sanitization)
    start_idx = content.find(START_MARKER)
    end_idx = content.find(END_MARKER)

    if start_idx != -1 and end_idx != -1:
        print("DEBUG: Found existing index. Cutting it out to move it to the bottom.")
        # Cut out the section entirely
        pre_content = content[:start_idx]
        post_content = content[end_idx + len(END_MARKER):]
        clean_content = pre_content + post_content
    else:
        clean_content = content

    # 5. APPEND TO BOTTOM
    # Strip trailing whitespace and add the new block at the absolute end
    final_content = clean_content.strip() + "\n\n" + new_block_str + "\n"

    with open(INSTRUCTIONS_FILE, 'w', encoding='utf-8') as f:
        f.write(final_content)

def main():
    if not os.path.exists(CURSOR_DIR):
        print(f"ERROR: Directory {CURSOR_DIR} does not exist.")
        return

    if not os.path.exists(RULES_DEST_DIR):
        os.makedirs(RULES_DEST_DIR)

    # RECURSIVE SEARCH
    print(f"DEBUG: Scanning {CURSOR_DIR} (Recursive)...")
    
    mdc_files = []
    for root, dirs, files in os.walk(CURSOR_DIR):
        for f in files:
            if f.lower().endswith('.mdc'):
                mdc_files.append(os.path.join(root, f))
            
    mdc_files.sort()
    print(f"DEBUG: Found {len(mdc_files)} .mdc files.")

    # Clean old compiled rules
    for f in os.listdir(RULES_DEST_DIR):
        if f.endswith('.md'):
            os.remove(os.path.join(RULES_DEST_DIR, f))

    rule_index = []
    for filepath in mdc_files:
        result = parse_mdc_and_save(filepath)
        if result:
            rule_index.append(result)

    print(f"Compiled {len(rule_index)} rules.")
    
    # CALL THE FIXED FUNCTION
    force_update_instructions_at_bottom(rule_index)
    
    print("SUCCESS: Instructions updated (Index forced to bottom).")

if __name__ == "__main__":
    main()
EOF

chmod +x "$HIDDEN_TOOLS_DIR/compile_mdc.py"
echo "   [OK] Python script updated."

# ------------------------------------------------------------------------------
# 3. ENSURE VS CODE SETTINGS ARE CORRECT
# ------------------------------------------------------------------------------

python3 -c "
import json
import os

settings_path = '$VSCODE_SETTINGS'

if os.path.exists(settings_path):
    try:
        with open(settings_path, 'r') as f:
            data = json.load(f)
        
        if 'emeraldwalk.runonsave' not in data:
            data['emeraldwalk.runonsave'] = {'commands': []}
        
        commands = data['emeraldwalk.runonsave'].get('commands', [])
        # Remove duplicates
        commands = [c for c in commands if 'compile_mdc.py' not in c['cmd']]

        new_cmd = {
            'match': '.cursor/.*\\.mdc',
            'cmd': 'python3 .tools/compile_mdc.py'
        }
        
        commands.append(new_cmd)
        data['emeraldwalk.runonsave']['commands'] = commands
            
        with open(settings_path, 'w') as f:
            json.dump(data, f, indent=4)
        print('   [OK] settings.json verified.')
            
    except Exception as e:
        print(f'   [ERROR] Settings update failed: {e}')
"

# ------------------------------------------------------------------------------
# 4. EXECUTE NOW TO FIX THE FILE
# ------------------------------------------------------------------------------

echo ">> Executing repair..."
python3 "$HIDDEN_TOOLS_DIR/compile_mdc.py"

echo "=============================================================================="
echo " FIXED. CHECK COPILOT-INSTRUCTIONS.MD NOW."
echo "=============================================================================="