#!/usr/bin/env zsh
# Install Versioner from GitHub Releases
# Compatible with macOS (zsh)
# Automatically detects platform and downloads appropriate artifact from latest release
#
# Usage:
#   zsh scripts/_installVersionerFromGithub.sh

set -Eeuo pipefail
IFS=$'\n\t'

# Enable zsh-specific features
setopt +o nomatch 2>/dev/null || true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# GitHub repository (default to Versioner)
GITHUB_REPO="${GITHUB_REPO:-michalagata/Versioner}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE} $1${PURPLE}${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Help function
show_help() {
    cat << EOF
Versioner Installation Script from GitHub

Usage: $0 [OPTIONS]

OPTIONS:
    --installDirectory=DIR    Installation directory
                              [default: /usr/local/bin/versioner/ (Linux/macOS)
                                       C:\\APPS\\AnubisWorks\\Versioner (Windows)]
    --githubRepo=REPO         GitHub repository [default: michalagata/Versioner]
    -h, --help                Show this help message

EXAMPLES:
    $0                                    # Install to default directory
    $0 --installDirectory=/opt/versioner  # Install to custom directory
    $0 --githubRepo=owner/repo            # Install from different repository

ENVIRONMENT VARIABLES:
    VERSIONER_DIR       Installation directory (overrides --installDirectory)
    GITHUB_REPO         GitHub repository (overrides --githubRepo)
EOF
}

# Detect platform
detect_platform() {
    local os_type
    os_type=$(uname -s 2>/dev/null || echo "Unknown")
    
    case "$os_type" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "macos"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            log_error "Unsupported platform: $os_type"
            exit 1
            ;;
    esac
}

# Get default installation directory based on platform
get_default_install_dir() {
    local platform="$1"
    
    case "$platform" in
        linux|macos)
            echo "/usr/local/bin/versioner"
            ;;
        windows)
            echo "C:\\APPS\\AnubisWorks\\Versioner"
            ;;
        *)
            log_error "Unknown platform: $platform"
            exit 1
            ;;
    esac
}

# Get artifact name pattern for platform
get_artifact_pattern() {
    local platform="$1"
    
    case "$platform" in
        linux)
            echo "*Linux*.zip"
            ;;
        macos)
            echo "*macOS*.zip"
            ;;
        windows)
            echo "*Windows*.zip"
            ;;
        *)
            log_error "Unknown platform: $platform"
            exit 1
            ;;
    esac
}

# Parse command line arguments
parse_args() {
    INSTALL_DIR=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --installDirectory=*)
                INSTALL_DIR="${1#*=}"
                shift
                ;;
            --installDirectory)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --githubRepo=*)
                GITHUB_REPO="${1#*=}"
                shift
                ;;
            --githubRepo)
                GITHUB_REPO="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Validate required tools
validate_tools() {
    log_info "Validating required tools..."
    
    # Check for curl or wget
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        log_error "Neither curl nor wget is available. Please install one of them."
        exit 1
    fi
    
    # Check for unzip
    if ! command -v unzip &> /dev/null; then
        log_error "unzip is not installed or not in PATH"
        exit 1
    fi
    
    # Check for gh CLI (optional but preferred)
    if command -v gh &> /dev/null; then
        log_success "GitHub CLI (gh) found - will use for release detection"
        USE_GH_CLI=true
    else
        log_warning "GitHub CLI (gh) not found - will use API directly"
        USE_GH_CLI=false
    fi
    
    log_success "Tool validation passed"
}

# Get latest release tag using GitHub API
get_latest_release_tag() {
    log_info "Fetching latest release from GitHub..."
    
    if [[ "$USE_GH_CLI" == "true" ]]; then
        # Use gh CLI if available
        local latest_tag
        latest_tag=$(gh release list --repo "$GITHUB_REPO" --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null || echo "")
        
        if [[ -n "$latest_tag" ]]; then
            echo "$latest_tag"
            return 0
        fi
    fi
    
    # Fallback to GitHub API
    local api_url="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    local release_json
    
    if command -v curl &> /dev/null; then
        release_json=$(curl -sL "$api_url" || echo "")
    elif command -v wget &> /dev/null; then
        release_json=$(wget -qO- "$api_url" || echo "")
    else
        log_error "Neither curl nor wget available"
        exit 1
    fi
    
    if [[ -z "$release_json" ]]; then
        log_error "Failed to fetch release information from GitHub"
        exit 1
    fi
    
    # Extract tag name (compatible with both jq and grep)
    local tag_name
    if command -v jq &> /dev/null; then
        tag_name=$(echo "$release_json" | jq -r '.tag_name' 2>/dev/null || echo "")
    else
        tag_name=$(echo "$release_json" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
    fi
    
    if [[ -z "$tag_name" ]]; then
        log_error "Could not extract release tag from GitHub API response"
        exit 1
    fi
    
    echo "$tag_name"
}

# Get download URL for artifact
get_artifact_url() {
    local release_tag="$1"
    local platform="$2"
    local artifact_pattern
    artifact_pattern=$(get_artifact_pattern "$platform")
    
    log_info "Finding artifact for platform: $platform (pattern: $artifact_pattern)"
    
    if [[ "$USE_GH_CLI" == "true" ]]; then
        # Use gh CLI to get asset URL
        local asset_url
        asset_url=$(gh release view "$release_tag" --repo "$GITHUB_REPO" --json assets --jq ".[] | select(.name | test(\"$artifact_pattern\")) | .url" 2>/dev/null | head -1 || echo "")
        
        if [[ -n "$asset_url" ]]; then
            # Convert API URL to download URL
            echo "$asset_url" | sed 's|api\.github\.com/repos/|github.com/|' | sed 's|/releases/assets/|/releases/download/|' | sed 's|/assets/|/|'
            return 0
        fi
    fi
    
    # Fallback to GitHub API
    local api_url="https://api.github.com/repos/$GITHUB_REPO/releases/tags/$release_tag"
    local release_json
    
    if command -v curl &> /dev/null; then
        release_json=$(curl -sL "$api_url" || echo "")
    elif command -v wget &> /dev/null; then
        release_json=$(wget -qO- "$api_url" || echo "")
    else
        log_error "Neither curl nor wget available"
        exit 1
    fi
    
    if [[ -z "$release_json" ]]; then
        log_error "Failed to fetch release assets from GitHub"
        exit 1
    fi
    
    # Extract download URL for matching artifact
    local download_url
    if command -v jq &> /dev/null; then
        # Use jq to find asset matching pattern
        download_url=$(echo "$release_json" | jq -r ".assets[] | select(.name | test(\"$artifact_pattern\")) | .browser_download_url" 2>/dev/null | head -1 || echo "")
    else
        # Fallback to grep/sed
        local asset_name
        asset_name=$(echo "$release_json" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -i "$artifact_pattern" | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
        
        if [[ -n "$asset_name" ]]; then
            download_url="https://github.com/$GITHUB_REPO/releases/download/$release_tag/$asset_name"
        fi
    fi
    
    if [[ -z "$download_url" ]]; then
        log_error "Could not find artifact matching pattern: $artifact_pattern"
        log_error "Available assets in release $release_tag:"
        if command -v jq &> /dev/null; then
            echo "$release_json" | jq -r '.assets[].name' 2>/dev/null || true
        else
            echo "$release_json" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true
        fi
        exit 1
    fi
    
    echo "$download_url"
}

# Download artifact
download_artifact() {
    local url="$1"
    local output_file="$2"
    
    log_info "Downloading artifact from: $url"
    
    if command -v curl &> /dev/null; then
        if curl -L -o "$output_file" "$url"; then
            log_success "Download completed"
            return 0
        fi
    elif command -v wget &> /dev/null; then
        if wget -O "$output_file" "$url"; then
            log_success "Download completed"
            return 0
        fi
    fi
    
    log_error "Failed to download artifact"
    return 1
}

# Create installation directory
create_installation_directory() {
    local install_dir="$1"
    
    log_info "Preparing installation directory: $install_dir"
    
    # Check if directory exists and has files
    if [[ -d "$install_dir" ]]; then
        if [[ -n "$(ls -A "$install_dir" 2>/dev/null)" ]]; then
            log_warning "Installation directory exists and contains files"
            log_info "Cleaning installation directory..."
            rm -rf "${install_dir:?}"/* "${install_dir:?}"/.* 2>/dev/null || true
            log_success "Installation directory cleaned"
        fi
    else
        log_info "Creating installation directory..."
        mkdir -p "$install_dir"
        if [[ $? -ne 0 ]]; then
            log_error "Failed to create installation directory: $install_dir"
            log_error "You may need to run with sudo (Linux/macOS) or as Administrator (Windows)"
            exit 1
        fi
        log_success "Installation directory created"
    fi
}

# Extract artifact
extract_artifact() {
    local zip_file="$1"
    local install_dir="$2"
    
    log_info "Extracting artifact to: $install_dir"
    
    if unzip -o "$zip_file" -d "$install_dir" >/dev/null 2>&1; then
        log_success "Artifact extracted successfully"
        return 0
    else
        log_error "Failed to extract artifact"
        return 1
    fi
}

# Set executable permissions
set_executable_permissions() {
    local install_dir="$1"
    local platform="$2"
    
    log_info "Setting executable permissions..."
    
    # Find executable files
    local executable_name=""
    case "$platform" in
        linux|macos)
            executable_name="Versioner.Cli"
            ;;
        windows)
            executable_name="Versioner.Cli.exe"
            ;;
    esac
    
    # Set permissions for executable
    if [[ -f "$install_dir/$executable_name" ]]; then
        chmod +x "$install_dir/$executable_name"
        log_success "Executable permissions set for $executable_name"
    else
        # Try to find any executable
        local found_executable
        found_executable=$(find "$install_dir" -type f -name "Versioner.Cli*" 2>/dev/null | head -1 || echo "")
        if [[ -n "$found_executable" ]]; then
            chmod +x "$found_executable"
            log_success "Executable permissions set for $(basename "$found_executable")"
        else
            log_warning "No Versioner executable found to set permissions"
        fi
    fi
}

# Test installation
test_installation() {
    local install_dir="$1"
    local platform="$2"
    
    log_info "Testing installation..."
    
    local executable_path=""
    case "$platform" in
        linux|macos)
            executable_path="$install_dir/Versioner.Cli"
            ;;
        windows)
            executable_path="$install_dir/Versioner.Cli.exe"
            ;;
    esac
    
    # Try to find executable if default path doesn't exist
    if [[ ! -f "$executable_path" ]]; then
        executable_path=$(find "$install_dir" -type f -name "Versioner.Cli*" 2>/dev/null | head -1 || echo "")
    fi
    
    if [[ -z "$executable_path" ]] || [[ ! -f "$executable_path" ]]; then
        log_error "Versioner executable not found in installation directory"
        return 1
    fi
    
    log_info "Found executable: $executable_path"
    
    # Test by checking version or help
    if [[ "$platform" == "windows" ]]; then
        # On Windows, we can't easily test .exe on Linux/macOS
        log_info "Windows executable detected - skipping runtime test (would require Windows environment)"
        log_success "Installation appears complete"
    else
        # Test executable
        if "$executable_path" --version >/dev/null 2>&1 || "$executable_path" --help >/dev/null 2>&1; then
            log_success "Versioner executable is working correctly"
            
            # Try to get version
            local version_output
            version_output=$("$executable_path" --version 2>/dev/null || echo "")
            if [[ -n "$version_output" ]]; then
                log_info "Installed version: $version_output"
            fi
        else
            log_warning "Versioner executable test failed (this might be normal if dependencies are missing)"
            log_warning "However, the executable file exists and has correct permissions"
        fi
    fi
    
    return 0
}

# Check and set VERSIONER_DIR environment variable
check_environment_variable() {
    local install_dir="$1"
    
    log_info "Checking VERSIONER_DIR environment variable..."
    
    if [[ -n "${VERSIONER_DIR:-}" ]]; then
        if [[ "$VERSIONER_DIR" != "$install_dir" ]]; then
            log_warning "VERSIONER_DIR is set to: $VERSIONER_DIR"
            log_warning "But installation directory is: $install_dir"
            log_info "Consider updating VERSIONER_DIR to match installation directory"
        else
            log_success "VERSIONER_DIR is correctly set to: $VERSIONER_DIR"
        fi
    else
        log_warning "VERSIONER_DIR environment variable is not set"
        log_info "To use Versioner easily, add the following to your shell profile:"
        echo ""
        case "$SHELL_TYPE" in
            zsh)
                echo -e "${CYAN}  export VERSIONER_DIR=\"$install_dir\"${NC}"
                echo -e "${CYAN}  export PATH=\"\$VERSIONER_DIR:\$PATH\"${NC}"
                echo -e "${YELLOW}  Add to ~/.zshrc${NC}"
                ;;
            bash)
                echo -e "${CYAN}  export VERSIONER_DIR=\"$install_dir\"${NC}"
                echo -e "${CYAN}  export PATH=\"\$VERSIONER_DIR:\$PATH\"${NC}"
                echo -e "${YELLOW}  Add to ~/.bashrc or ~/.bash_profile${NC}"
                ;;
            *)
                echo -e "${CYAN}  export VERSIONER_DIR=\"$install_dir\"${NC}"
                echo -e "${CYAN}  export PATH=\"\$VERSIONER_DIR:\$PATH\"${NC}"
                ;;
        esac
        echo ""
    fi
}

# Show installation summary
show_summary() {
    local install_dir="$1"
    local release_tag="$2"
    local platform="$3"
    
    log_header "📊 INSTALLATION SUMMARY"
    
    echo -e "${WHITE}Installation Directory: ${CYAN}$install_dir${NC}"
    echo -e "${WHITE}Release Tag: ${CYAN}$release_tag${NC}"
    echo -e "${WHITE}Platform: ${CYAN}$platform${NC}"
    echo -e "${WHITE}Installation Time: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
    
    # Show directory contents
    echo -e "${WHITE}Installed Files:${NC}"
    ls -la "$install_dir" 2>/dev/null | head -10 || true
    local total_files
    total_files=$(find "$install_dir" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [[ $total_files -gt 10 ]]; then
        echo -e "${CYAN}... and $((total_files - 10)) more files${NC}"
    fi
    echo ""
}

# Main installation process
main() {
    log_header "🚀 VERSIONER INSTALLATION FROM GITHUB 🚀"
    
    # Parse arguments
    parse_args "$@"
    
    # Detect platform
    local platform
    platform=$(detect_platform)
    log_info "Detected platform: $platform"
    
    # Determine installation directory
    if [[ -n "${VERSIONER_DIR:-}" ]]; then
        INSTALL_DIR="$VERSIONER_DIR"
        log_info "Using VERSIONER_DIR environment variable: $INSTALL_DIR"
    elif [[ -z "$INSTALL_DIR" ]]; then
        INSTALL_DIR=$(get_default_install_dir "$platform")
        log_info "Using default installation directory: $INSTALL_DIR"
    else
        log_info "Using provided installation directory: $INSTALL_DIR"
    fi
    
    # Normalize path (handle Windows paths)
    if [[ "$platform" == "windows" ]]; then
        # Convert forward slashes to backslashes for Windows
        INSTALL_DIR=$(echo "$INSTALL_DIR" | sed 's|/|\\|g')
    fi
    
    # Validate tools
    validate_tools
    
    # Get latest release
    local release_tag
    release_tag=$(get_latest_release_tag)
    log_success "Latest release: $release_tag"
    
    # Get artifact download URL
    local artifact_url
    artifact_url=$(get_artifact_url "$release_tag" "$platform")
    log_success "Found artifact URL: $artifact_url"
    
    # Create temporary directory for download
    local temp_dir
    temp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t versioner-install)
    local zip_file="$temp_dir/versioner-${platform}.zip"
    
    # Download artifact
    if ! download_artifact "$artifact_url" "$zip_file"; then
        log_error "Failed to download artifact"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Create installation directory
    create_installation_directory "$INSTALL_DIR"
    
    # Extract artifact
    if ! extract_artifact "$zip_file" "$INSTALL_DIR"; then
        log_error "Failed to extract artifact"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Set executable permissions
    set_executable_permissions "$INSTALL_DIR" "$platform"
    
    # Test installation
    if ! test_installation "$INSTALL_DIR" "$platform"; then
        log_warning "Installation test had issues, but files are installed"
    fi
    
    # Check environment variable
    check_environment_variable "$INSTALL_DIR"
    
    # Show summary
    show_summary "$INSTALL_DIR" "$release_tag" "$platform"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_success "Versioner installed successfully!"
    echo ""
    echo -e "${WHITE}To use Versioner, run:${NC}"
    case "$platform" in
        linux|macos)
            echo -e "${CYAN}  $INSTALL_DIR/Versioner.Cli --help${NC}"
            ;;
        windows)
            echo -e "${CYAN}  $INSTALL_DIR\\Versioner.Cli.exe --help${NC}"
            ;;
    esac
    echo ""
}

# Run main function with all arguments
main "$@"

