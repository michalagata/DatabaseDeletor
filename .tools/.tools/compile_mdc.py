import os
import re
import sys

# Paths are relative to PROJECT ROOT
CURSOR_DIR = '.cursor'
RULES_DEST_DIR = '.github/rules'
INSTRUCTIONS_FILE = '.github/copilot-instructions.md'

# Markers for the index section
START_MARKER = ""
END_MARKER = ""

def parse_mdc_and_save(filename):
    """
    Reads an MDC file, strips YAML, saves as clean MD in destination.
    Returns (base_filename, description_summary).
    """
    src_path = os.path.join(CURSOR_DIR, filename)
    base_name = os.path.splitext(filename)[0]
    dest_path = os.path.join(RULES_DEST_DIR, f"{base_name}.md")
    
    try:
        with open(src_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Extract YAML description if present
        description = "General rules"
        yaml_match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL | re.MULTILINE)
        
        if yaml_match:
            yaml_content = yaml_match.group(1)
            desc_match = re.search(r'description:\s*(.+)', yaml_content)
            if desc_match:
                description = desc_match.group(1).strip()
            
            # Content without YAML
            clean_content = content[yaml_match.end():].strip()
        else:
            clean_content = content.strip()

        # Add explicit header for Copilot context
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

def update_main_instructions(rule_index):
    """Updates .github/copilot-instructions.md with the index of rules."""
    
    index_content = (
        f"\n\n{START_MARKER}\n"
        "## 11) DYNAMIC RULE INDEX (MANDATORY)\n"
        "The following specialized rule files are active. "
        "**Copilot must read the specific file** if the user request pertains to its domain:\n\n"
    )
    
    for filename, desc in rule_index:
        index_content += f"- **{filename}**: {desc}\n  (Location: )\n"
        
    index_content += (
        "\n> **INSTRUCTION:** When addressing a task, identify which rule set applies, "
        "read the corresponding file from , and strictly follow its content.\n"
        f"{END_MARKER}\n"
    )

    if not os.path.exists(INSTRUCTIONS_FILE):
        # Create if missing
        with open(INSTRUCTIONS_FILE, 'w', encoding='utf-8') as f:
            f.write("# Copilot Instructions\n" + index_content)
        return

    with open(INSTRUCTIONS_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = re.compile(f"{re.escape(START_MARKER)}.*?{re.escape(END_MARKER)}", re.DOTALL)
    
    if pattern.search(content):
        new_content = pattern.sub(index_content.strip(), content)
    else:
        new_content = content.strip() + "\n" + index_content

    with open(INSTRUCTIONS_FILE, 'w', encoding='utf-8') as f:
        f.write(new_content)

def main():
    # Verify we are running from root or can find directories
    if not os.path.exists(CURSOR_DIR):
        # Fallback: maybe running inside .tools?
        if os.path.exists(f"../{CURSOR_DIR}"):
            os.chdir("..")
        else:
            print(f"Directory {CURSOR_DIR} not found. Run from project root.")
            return

    if not os.path.exists(RULES_DEST_DIR):
        os.makedirs(RULES_DEST_DIR)

    files = [f for f in os.listdir(CURSOR_DIR) if f.endswith('.mdc')]
    files.sort()

    rule_index = []
    print(f"Compiling {len(files)} rules from {CURSOR_DIR}...")
    
    # Clean destination
    for f in os.listdir(RULES_DEST_DIR):
        if f.endswith('.md'):
            os.remove(os.path.join(RULES_DEST_DIR, f))

    for filename in files:
        result = parse_mdc_and_save(filename)
        if result:
            rule_index.append(result)
            print(f" - [COMPILED] {filename} -> {RULES_DEST_DIR}/{result[0]}")

    update_main_instructions(rule_index)
    print("Main instructions updated successfully.")

if __name__ == "__main__":
    main()
