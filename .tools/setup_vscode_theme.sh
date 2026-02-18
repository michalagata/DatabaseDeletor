#!/bin/bash

# ==============================================================================
# VS Code Cursor Theme Setup (macOS)
# ==============================================================================
# This script configures VS Code to look like Cursor with different scope options:
#   --complete   : Full configuration (editor + menu + colors)
#   --windowonly : Only editor window appearance (colors, fonts, minimap)
#   --menuonly   : Only left sidebar menu appearance
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

VSCODE_DIR=".vscode"
SETTINGS_FILE="$VSCODE_DIR/settings.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==============================================================================
# USAGE
# ==============================================================================
usage() {
    cat <<EOF
Usage: $0 [OPTION]

Options:
    --complete   Apply full Cursor-like configuration (editor + menu + colors)
    --windowonly Apply only editor window appearance (colors, fonts, minimap)
                 Does NOT modify left sidebar menu settings
    --menuonly   Apply only left sidebar menu appearance
                 Does NOT modify editor window settings

Examples:
    $0 --complete
    $0 --windowonly
    $0 --menuonly

EOF
    exit 1
}

# ==============================================================================
# VALIDATE ARGUMENT
# ==============================================================================
if [[ $# -ne 1 ]]; then
    echo -e "${RED}ERROR:${NC} Exactly one option is required."
    echo
    usage
fi

MODE="$1"
case "$MODE" in
    --complete|--windowonly|--menuonly)
        ;;
    *)
        echo -e "${RED}ERROR:${NC} Invalid option: $MODE"
        echo
        usage
        ;;
esac

# ==============================================================================
# ENSURE VSCODE DIRECTORY EXISTS
# ==============================================================================
mkdir -p "$VSCODE_DIR"

# ==============================================================================
# PYTHON SCRIPT TO MERGE SETTINGS
# ==============================================================================
python3 <<PYTHON_SCRIPT
import json
import os
import sys

settings_path = "$SETTINGS_FILE"
mode = "$MODE"

# Cursor-like theme settings
cursor_theme_settings = {
    "--complete": {
        "workbench.colorTheme": "Default Dark Modern",
        "editor.fontFamily": "SF Mono, Menlo, Monaco, 'Courier New', monospace",
        "editor.fontSize": 13,
        "editor.lineHeight": 20,
        "editor.minimap.enabled": False,
        "editor.stickyScroll.enabled": True,
        "window.commandCenter": False,
        "workbench.activityBar.location": "hidden",
        "workbench.statusBar.visible": True,
        "workbench.sideBar.location": "left",
        "workbench.editor.showTabs": "multiple",
        "chat.editor.fontFamily": "SF Mono, Menlo, monospace",
        "workbench.colorCustomizations": {
            "editor.background": "#121212",
            "sideBar.background": "#121212",
            "activityBar.background": "#121212",
            "statusBar.background": "#121212",
            "titleBar.activeBackground": "#121212",
            "editorGroupHeader.tabsBackground": "#121212",
            "tab.activeBackground": "#121212",
            "tab.inactiveBackground": "#121212",
            "tab.border": "#121212",
            "editorLineNumber.activeForeground": "#ffffff",
            "editorLineNumber.foreground": "#444444"
        }
    },
    "--windowonly": {
        "workbench.colorTheme": "Default Dark Modern",
        "editor.fontFamily": "SF Mono, Menlo, Monaco, 'Courier New', monospace",
        "editor.fontSize": 13,
        "editor.lineHeight": 20,
        "editor.minimap.enabled": False,
        "editor.stickyScroll.enabled": True,
        "window.commandCenter": False,
        "chat.editor.fontFamily": "SF Mono, Menlo, monospace",
        "workbench.colorCustomizations": {
            "editor.background": "#121212",
            "statusBar.background": "#121212",
            "titleBar.activeBackground": "#121212",
            "editorGroupHeader.tabsBackground": "#121212",
            "tab.activeBackground": "#121212",
            "tab.inactiveBackground": "#121212",
            "tab.border": "#121212",
            "editorLineNumber.activeForeground": "#ffffff",
            "editorLineNumber.foreground": "#444444"
        }
    },
    "--menuonly": {
        "workbench.activityBar.location": "hidden",
        "workbench.sideBar.location": "left",
        "workbench.colorCustomizations": {
            "sideBar.background": "#121212",
            "activityBar.background": "#121212"
        }
    }
}

# Load existing settings or create empty dict
existing_settings = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path, 'r', encoding='utf-8') as f:
            existing_settings = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        print(f"Warning: Could not parse existing settings.json: {e}", file=sys.stderr)
        existing_settings = {}

# Get new settings for the selected mode
new_settings = cursor_theme_settings.get(mode, {})

# Deep merge function
def deep_merge(base, update):
    """Recursively merge update into base."""
    result = base.copy()
    for key, value in update.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result

# Merge new settings into existing
merged_settings = deep_merge(existing_settings, new_settings)

# Write back to file
try:
    with open(settings_path, 'w', encoding='utf-8') as f:
        json.dump(merged_settings, f, indent=4, ensure_ascii=False)
    print(f"SUCCESS: Settings updated for mode: {mode}")
    sys.exit(0)
except IOError as e:
    print(f"ERROR: Could not write to {settings_path}: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} VS Code settings updated successfully."
    echo
    echo "Mode applied: $MODE"
    case "$MODE" in
        --complete)
            echo "  - Editor window appearance"
            echo "  - Left sidebar menu appearance"
            echo "  - Color customizations"
            ;;
        --windowonly)
            echo "  - Editor window appearance only"
            echo "  - Color customizations for editor"
            echo "  - Left sidebar menu NOT modified"
            ;;
        --menuonly)
            echo "  - Left sidebar menu appearance only"
            echo "  - Editor window NOT modified"
            ;;
    esac
    echo
    echo "Please restart VS Code to see the changes."
else
    echo -e "${RED}✗${NC} Failed to update settings."
    exit $EXIT_CODE
fi
