#!/usr/bin/env zsh
# maintainDotnetSDK.sh
# Centralized .NET SDK detection, version checking, and automatic installation
# Tries to install latest SDK (10) first
# Usage: source maintainDotnetSDK.sh && ensure_dotnet_sdk

# Allow sourcing this script (don't use strict mode if sourced)
if [[ "${(%):-%x}" == "${0}" ]]; then
    set -Eeuo pipefail
fi
IFS=$'\n\t'

# Get script directory (works both when executed and when sourced)
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if .NET SDK is installed and returns appropriate version
# Returns 0 if SDK is available and version >= 10.0, 1 otherwise
check_dotnet() {
    if ! command -v dotnet &> /dev/null; then
        return 1
    fi
    
    local dotnet_version=$(dotnet --version 2>/dev/null || echo "")
    if [[ -z "$dotnet_version" ]]; then
        return 1
    fi
    
    log_info "Detected .NET SDK version: $dotnet_version"
    
    # Check if version is 10.0 or later
    local major_version=$(echo "$dotnet_version" | cut -d. -f1)
    if [ "$major_version" -lt 10 ]; then
        log_warning ".NET SDK version $dotnet_version is too old (requires 10.0 or later)"
        return 1
    fi
    
    return 0
}

# Detect the latest available .NET SDK version
# Returns version string (e.g., "10.0")
detect_latest_sdk_version() {
    # Try to get latest version from Microsoft's API or use hardcoded fallback
    local latest_version="10.0"
    
    # Try to fetch latest LTS version from Microsoft
    if command -v curl &> /dev/null; then
        local api_response=$(curl -sSL "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/LTS/latest.version" 2>/dev/null || echo "")
        if [[ -n "$api_response" ]]; then
            # Extract major.minor version
            local detected_version=$(echo "$api_response" | head -1 | cut -d. -f1-2)
            if [[ -n "$detected_version" ]]; then
                latest_version="$detected_version"
                log_info "Detected latest LTS SDK version from Microsoft API: $latest_version"
            fi
        fi
    elif command -v wget &> /dev/null; then
        local api_response=$(wget -qO- "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/LTS/latest.version" 2>/dev/null || echo "")
        if [[ -n "$api_response" ]]; then
            local detected_version=$(echo "$api_response" | head -1 | cut -d. -f1-2)
            if [[ -n "$detected_version" ]]; then
                latest_version="$detected_version"
                log_info "Detected latest LTS SDK version from Microsoft API: $latest_version"
            fi
        fi
    fi
    
    # Fallback to hardcoded latest (10.0) if API call fails
    if [[ "$latest_version" == "10.0" ]]; then
        log_info "Using hardcoded latest SDK version: $latest_version"
    fi
    
    echo "$latest_version"
}

# Check if specific .NET SDK version is already installed
# Returns 0 if version is installed, 1 otherwise
check_dotnet_version_installed() {
    local required_version="$1"
    
    # First check if dotnet command exists
    if ! command -v dotnet &> /dev/null; then
        return 1
    fi
    
    # Get installed SDK versions
    local installed_versions=$(dotnet --list-sdks 2>/dev/null || echo "")
    if [[ -z "$installed_versions" ]]; then
        return 1
    fi
    
    # Check if required version (major.minor) is in the list
    # Extract major.minor from required_version (e.g., "10.0" from "10.0" or "10.0.1")
    local required_major_minor=$(echo "$required_version" | cut -d. -f1-2)
    
    # Check if any installed SDK matches the required major.minor version
    while IFS= read -r installed_version; do
        if [[ -n "$installed_version" ]]; then
            # Extract major.minor from installed version (format: "10.0.123 [path]")
            local installed_major_minor=$(echo "$installed_version" | cut -d' ' -f1 | cut -d. -f1-2)
            if [[ "$installed_major_minor" == "$required_major_minor" ]]; then
                log_info "Found installed .NET SDK version matching $required_major_minor: $installed_version"
                return 0
            fi
        fi
    done <<< "$installed_versions"
    
    return 1
}

# Install specific .NET SDK version
install_dotnet_sdk_version() {
    local version="$1"
    local os_type="$2"
    
    # Extract major.minor version for checking
    local major_minor_version=$(echo "$version" | cut -d. -f1-2)
    
    # Check if this version is already installed
    if check_dotnet_version_installed "$major_minor_version"; then
        log_info ".NET SDK version $major_minor_version is already installed, skipping download and installation"
        return 0
    fi
    
    log_info "Installing .NET SDK $version for $os_type..."
    
    # Use dotnet-install.sh script (works on Linux, macOS, and Windows)
    local install_script="/tmp/dotnet-install.sh"
    
    # Download install script
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        log_error "Neither wget nor curl is available. Cannot download .NET SDK installer."
        return 1
    fi
    
    log_info "Downloading .NET SDK installer..."
    if command -v wget &> /dev/null; then
        if ! wget -q https://dot.net/v1/dotnet-install.sh -O "$install_script"; then
            log_error "Failed to download dotnet-install.sh"
            return 1
        fi
    else
        if ! curl -sSL https://dot.net/v1/dotnet-install.sh -o "$install_script"; then
            log_error "Failed to download dotnet-install.sh"
            return 1
        fi
    fi
    
    chmod +x "$install_script"
    
    # Determine install directory
    local install_dir=""
    if [[ "$os_type" == "macos" ]]; then
        install_dir="$HOME/.dotnet"
    else
        # Linux: try /usr/share/dotnet (system-wide) or fall back to $HOME/.dotnet
        if [[ -w "/usr/share" ]]; then
            install_dir="/usr/share/dotnet"
        else
            install_dir="$HOME/.dotnet"
            log_warning "Cannot write to /usr/share, installing to $install_dir (user-specific)"
        fi
    fi
    
    log_info "Installing .NET SDK $version to $install_dir..."
    
    # Run installer
    if "$install_script" --channel "$version" --install-dir "$install_dir" --version latest; then
        # Add to PATH for current session
        export PATH="$install_dir:$PATH"
        export DOTNET_ROOT="$install_dir"
        
        # Verify installation
        if "$install_dir/dotnet" --version &> /dev/null; then
            local installed_version=$("$install_dir/dotnet" --version)
            log_success "Installed .NET SDK version: $installed_version"
            
            # Add to PATH permanently (if possible)
            if [[ "$os_type" != "macos" ]] && [[ -w "/etc/profile.d" ]]; then
                echo "export PATH=\"$install_dir:\$PATH\"" > /etc/profile.d/dotnet.sh
                echo "export DOTNET_ROOT=\"$install_dir\"" >> /etc/profile.d/dotnet.sh
                chmod +x /etc/profile.d/dotnet.sh
                log_info "Added .NET SDK to system PATH (/etc/profile.d/dotnet.sh)"
            elif [[ -f "$HOME/.bashrc" ]] || [[ -f "$HOME/.zshrc" ]]; then
                local shell_rc=""
                if [[ -f "$HOME/.bashrc" ]]; then
                    shell_rc="$HOME/.bashrc"
                else
                    shell_rc="$HOME/.zshrc"
                fi
                
                if ! grep -q "DOTNET_ROOT" "$shell_rc" 2>/dev/null; then
                    echo "" >> "$shell_rc"
                    echo "# .NET SDK" >> "$shell_rc"
                    echo "export PATH=\"$install_dir:\$PATH\"" >> "$shell_rc"
                    echo "export DOTNET_ROOT=\"$install_dir\"" >> "$shell_rc"
                    log_info "Added .NET SDK to PATH in $shell_rc"
                fi
            fi
            
            # Clean up
            rm -f "$install_script"
            return 0
        else
            log_error "Installation completed but dotnet command not found"
            rm -f "$install_script"
            return 1
        fi
    else
        log_error "Failed to install .NET SDK $version"
        rm -f "$install_script"
        return 1
    fi
}

# Install .NET SDK automatically if not available
# Tries to install latest SDK (10) first
install_dotnet_sdk() {
    # Check if already installed
    if check_dotnet; then
        log_info ".NET SDK is already installed"
        return 0
    fi
    
    log_info ".NET SDK not found. Attempting automatic installation..."
    
    # Detect OS
    local os_type=""
    if [[ "$(uname)" == "Linux" ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            os_type="$ID"
        else
            os_type="linux"
        fi
    elif [[ "$(uname)" == "Darwin" ]]; then
        os_type="macos"
    else
        log_error "Unsupported OS for automatic .NET SDK installation"
        return 1
    fi
    
    log_info "Detected OS: $os_type"
    
    # Detect latest SDK version
    local latest_version=$(detect_latest_sdk_version)
    log_info "Latest SDK version: $latest_version"
    
    # Try to install latest SDK first
    log_info "Attempting to install .NET SDK $latest_version (latest)..."
    if install_dotnet_sdk_version "$latest_version" "$os_type"; then
        log_success ".NET SDK $latest_version installed successfully"
        return 0
    fi
    
    log_error "Failed to install .NET SDK $latest_version"
    return 1
}

# Ensure .NET SDK is available (check and install if needed)
ensure_dotnet_sdk() {
    if check_dotnet; then
        return 0
    fi
    
    log_info ".NET SDK not found, attempting automatic installation..."
    if install_dotnet_sdk; then
        # Verify after installation
        if check_dotnet; then
            return 0
        else
            log_error ".NET SDK was installed but verification failed"
            return 1
        fi
    else
        log_error "Failed to install .NET SDK automatically"
        log_error ""
        log_error "Please install .NET SDK manually:"
        log_error "  Visit: https://dotnet.microsoft.com/download"
        log_error "  Or use: wget https://dot.net/v1/dotnet-install.sh && chmod +x dotnet-install.sh && ./dotnet-install.sh --channel 10.0"
        return 1
    fi
}

# Export functions for use in other scripts
export -f check_dotnet check_dotnet_version_installed detect_latest_sdk_version install_dotnet_sdk_version install_dotnet_sdk ensure_dotnet_sdk
export -f log_info log_success log_warning log_error

