#!/usr/bin/env zsh
set -e
# _authorize_Nuget.sh
# Interactive script to setup NuGet API Key

# Detect script directory (cross-compatible way)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${(%):-%x}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Load common functions if available
if [[ -f "$SCRIPT_DIR/_common.sh" ]]; then
    source "$SCRIPT_DIR/_common.sh"
else
    # Minimal fallback logging functions
    info() { echo -e "\033[34m[INFO]\033[0m $*"; }
    error() { echo -e "\033[31m[ERROR]\033[0m $*" >&2; }
    success() { echo -e "\033[32m[SUCCESS]\033[0m $*"; }
    step() { echo -e "\n\033[36m$1\033[0m"; }
fi

PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "NuGet Authorization Wizard"
echo "========================================"
echo "1) Log in to nuget.org and generate key (Interactive)"
echo "2) Enter existing API key manually"
echo "========================================"
echo -n "Select option [1/2]: "
read option

API_KEY=""

if [[ "$option" == "1" ]]; then
    step "Opening NuGet.org..."
    # URL to API Keys page (forces login if needed)
    URL="https://www.nuget.org/users/account/LogOn?returnUrl=%2Faccount%2Fapikeys"
    
    if command -v open >/dev/null; then
        open "$URL"
    elif command -v xdg-open >/dev/null; then
        xdg-open "$URL"
    else
        info "Please open this URL in your browser: $URL"
    fi
    
    echo ""
    echo "INSTRUCTIONS:"
    echo "1. Log in to NuGet.org"
    echo "2. Generate a new API Key (Select 'Push' scope and Glob Pattern '*')"
    echo "3. Copy the key"
    echo ""
    echo -n "Paste the generated API Key here: "
    read -r API_KEY
    
elif [[ "$option" == "2" ]]; then
    echo -n "Enter your NuGet API Key: "
    read -r API_KEY
else
    error "Invalid option."
    exit 1
fi

if [[ -z "$API_KEY" ]]; then
    error "API Key cannot be empty."
    exit 1
fi

# Save to file
step "Saving API Key..."
KEY_FILE="$PROJECT_ROOT/.nuget-api-key"
echo "$API_KEY" > "$KEY_FILE"
success "Key saved to: $KEY_FILE"

# chmod restricted
chmod 600 "$KEY_FILE"

# Ask about global persistence
echo ""
echo "Do you want to add this key globally to your user profile?"
echo "This will add 'export NUGET_API_KEY=...' to your ~/.zshrc (or ~/.bash_profile)"
echo "Note: This is useful for persistence across terminal sessions."
echo -n "Add globally? [y/N]: "
read global_opt

if [[ "$global_opt" =~ ^[Yy]$ ]]; then
    # Detect shell config
    SHELL_CONFIG=""
    if [[ "$SHELL" =~ "zsh" ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [[ "$SHELL" =~ "bash" ]]; then
        if [[ -f "$HOME/.bash_profile" ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
    fi
    
    if [[ -z "$SHELL_CONFIG" ]]; then
        error "Could not detect shell configuration file. Skipping global export."
    else
        step "Updating $SHELL_CONFIG..."
        
        # Check if already exists (naive check)
        if grep -q "export NUGET_API_KEY=" "$SHELL_CONFIG"; then
            # Replace existing? Or warn?
            # Let's verify if user wants to replace
             echo "NUGET_API_KEY is already defined in $SHELL_CONFIG."
             echo -n "Update it? [y/N]: "
             read update_opt
             if [[ "$update_opt" =~ ^[Yy]$ ]]; then
                # Remove old lines (simple sed, might be risky if multiline or formatted differently, but standard is one line)
                # Safer: Append new one at the end, last one usually wins in shell sourcing, 
                # OR use SED to replace.
                # Let's allow appending with a comment, simpler and safer than complex sed in-place for now.
                echo "" >> "$SHELL_CONFIG"
                echo "# NuGet API Key updated by _authorize_Nuget.sh on $(date)" >> "$SHELL_CONFIG"
                echo "export NUGET_API_KEY=\"$API_KEY\"" >> "$SHELL_CONFIG"
                success "Appended new key to $SHELL_CONFIG"
             fi
        else
            echo "" >> "$SHELL_CONFIG"
            echo "export NUGET_API_KEY=\"$API_KEY\"" >> "$SHELL_CONFIG"
            success "Added to $SHELL_CONFIG"
        fi
        
        info "Please run 'source $SHELL_CONFIG' or restart your terminal to apply changes."
    fi
fi

echo ""
echo "Authorization setup complete."
echo "You can now run: ./_buildAndPublishAndReleaseNuget.sh"
