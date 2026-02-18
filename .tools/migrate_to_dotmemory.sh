#!/bin/bash

# ==============================================================================
# Migration Script: docs/ai -> .memory
# ==============================================================================
# This script moves existing memory files to the new location and updates
# all references in settings, instructions, and tools.
# Compatible with macOS (BSD sed) and Linux.
# ==============================================================================

OLD_DIR="docs/ai"
NEW_DIR=".memory"
VSCODE_SETTINGS=".vscode/settings.json"
INSTRUCTIONS_FILE=".github/copilot-instructions.md"
TOOLS_GEN_SCRIPT="tools/gen_prompts.py"
TOOLS_UPDATE_SCRIPT="tools/update_context.sh"

echo ">> Starting migration from '$OLD_DIR' to '$NEW_DIR'..."

# 1. FILE SYSTEM MIGRATION
# ------------------------------------------------------------------------------
if [ -d "$OLD_DIR" ]; then
    echo "   [MOVE] Detected existing '$OLD_DIR'. Moving contents to '$NEW_DIR'..."
    mkdir -p "$NEW_DIR"
    # Move contents (suppress errors if empty)
    mv "$OLD_DIR"/* "$NEW_DIR/" 2>/dev/null
    
    # Remove old directory structure if empty
    rmdir "$OLD_DIR" 2>/dev/null
    rmdir "docs" 2>/dev/null # Remove parent 'docs' if empty
    echo "   [OK] Files moved."
else
    echo "   [INFO] '$OLD_DIR' not found. Creating '$NEW_DIR' fresh..."
    mkdir -p "$NEW_DIR"
    # Create basic files if they don't exist yet (in case previous script failed)
    touch "$NEW_DIR/STATE.md"
    touch "$NEW_DIR/CONTEXT.md"
    if [ ! -f "$NEW_DIR/workflows.json" ]; then
        echo "{}" > "$NEW_DIR/workflows.json"
    fi
fi

# 2. UPDATE CONFIGURATIONS (SED REPLACEMENT)
# ------------------------------------------------------------------------------
# We use a helper function to handle sed differences between macOS and Linux
perform_sed() {
    local target_file=$1
    local search_pat=$2
    local replace_pat=$3

    if [ -f "$target_file" ]; then
        echo "   [UPDATE] Patching $target_file..."
        # macOS requires '' after -i, Linux does not. We detect OS.
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|$search_pat|$replace_pat|g" "$target_file"
        else
            sed -i "s|$search_pat|$replace_pat|g" "$target_file"
        fi
    else
        echo "   [SKIP] File $target_file not found."
    fi
}

# Apply replacements: looking for 'docs/ai/' and replacing with '.memory/'
# We use pipes | as delimiters to avoid escaping slashes

# Update VS Code Settings
perform_sed "$VSCODE_SETTINGS" "docs/ai/" ".memory/"

# Update Copilot Instructions
perform_sed "$INSTRUCTIONS_FILE" "docs/ai/" ".memory/"
# Also explicitly catch the phrase "docs/ai" without trailing slash if it exists in text
perform_sed "$INSTRUCTIONS_FILE" "docs/ai" ".memory"

# Update Python Tool Script
perform_sed "$TOOLS_GEN_SCRIPT" "docs/ai/" ".memory/"

# Update Bash Tool Script (if it logs paths)
perform_sed "$TOOLS_UPDATE_SCRIPT" "docs/ai/" ".memory/"

echo "=============================================================================="
echo " MIGRATION COMPLETE"
echo "=============================================================================="
echo "1. Memory location is now: $NEW_DIR/"
echo "2. VS Code settings and Copilot instructions have been updated."
echo "3. Please RESTART VS Code to reload the new settings."
echo "=============================================================================="