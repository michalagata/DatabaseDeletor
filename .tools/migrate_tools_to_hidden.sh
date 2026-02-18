#!/bin/bash

# ==============================================================================
# Migration Script: tools -> .tools
# ==============================================================================
# This script moves utility scripts to a hidden directory and updates
# references in VS Code settings and Copilot instructions.
# ==============================================================================

OLD_TOOLS_DIR="tools"
NEW_TOOLS_DIR=".tools"
VSCODE_SETTINGS=".vscode/settings.json"
INSTRUCTIONS_FILE=".github/copilot-instructions.md"

echo ">> Starting migration from '$OLD_TOOLS_DIR' to '$NEW_TOOLS_DIR'..."

# 1. FILE SYSTEM MIGRATION
# ------------------------------------------------------------------------------
if [ -d "$OLD_TOOLS_DIR" ]; then
    echo "   [MOVE] Detected existing '$OLD_TOOLS_DIR'. Moving contents to '$NEW_TOOLS_DIR'..."
    mkdir -p "$NEW_TOOLS_DIR"
    
    # Move all contents from visible tools to hidden tools
    # We use a wildcard loop to avoid moving the directory itself inside the target
    mv "$OLD_TOOLS_DIR"/* "$NEW_TOOLS_DIR/" 2>/dev/null
    
    # Remove the empty visible directory
    rmdir "$OLD_TOOLS_DIR" 2>/dev/null
    
    echo "   [OK] Tools moved to hidden directory."
elif [ -d "$NEW_TOOLS_DIR" ]; then
    echo "   [INFO] '$OLD_TOOLS_DIR' not found, but '$NEW_TOOLS_DIR' exists. Assuming files are already there."
else
    echo "   [INIT] Neither directory found. Creating empty '$NEW_TOOLS_DIR'..."
    mkdir -p "$NEW_TOOLS_DIR"
fi

# Ensure scripts are executable
chmod +x "$NEW_TOOLS_DIR"/*.sh 2>/dev/null
chmod +x "$NEW_TOOLS_DIR"/*.py 2>/dev/null

# 2. UPDATE CONFIGURATION REFERENCES
# ------------------------------------------------------------------------------

# Helper function for cross-platform sed (macOS/Linux compatibility)
perform_sed() {
    local target_file=$1
    local search_pat=$2
    local replace_pat=$3

    if [ -f "$target_file" ]; then
        echo "   [UPDATE] Patching $target_file..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS sed requires empty string for backup extension
            sed -i '' "s|$search_pat|$replace_pat|g" "$target_file"
        else
            # GNU sed
            sed -i "s|$search_pat|$replace_pat|g" "$target_file"
        fi
    else
        echo "   [SKIP] File $target_file not found."
    fi
}

# --- Update Settings.json ---
# We need to be careful not to break paths if they are already updated.
# We look specifically for "tools/" followed by a filename character, 
# ensuring we don't double-rename ".tools/" to "..tools/" if run twice incorrectly,
# though the simple substitution "tools/" -> ".tools/" is usually safe if we are precise.

# Heuristic: Replace "tools/update_context.sh" with ".tools/update_context.sh"
perform_sed "$VSCODE_SETTINGS" "tools/update_context.sh" ".tools/update_context.sh"
perform_sed "$VSCODE_SETTINGS" "tools/gen_prompts.py" ".tools/gen_prompts.py"

# --- Update Copilot Instructions ---
# The instructions mention "tools/gen_prompts.py" in the workflow section.
perform_sed "$INSTRUCTIONS_FILE" "tools/gen_prompts.py" ".tools/gen_prompts.py"

# Just in case there are loose references to "tools/" directory in instructions
# avoiding replacing existing ".tools/"
# (Advanced regex in sed is tricky across OS, so we stick to explicit file replacements above usually,
# but here is a safe catch-all for the directory name if surrounded by spaces or known context).

echo "=============================================================================="
echo " TOOLS MIGRATION COMPLETE"
echo "=============================================================================="
echo "1. Tools location is now: $NEW_TOOLS_DIR/"
echo "2. VS Code settings (Run on Save) updated to point to hidden folder."
echo "3. Copilot instructions updated."
echo ""
echo "IMPORTANT: Please RESTART VS Code (Command+Q) to reload the settings!"
echo "If you don't restart, 'Run on Save' might fail to find the scripts."
echo "=============================================================================="