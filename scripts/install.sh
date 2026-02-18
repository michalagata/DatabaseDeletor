#!/usr/bin/env zsh
# Install Versioner script for macOS/Linux
# Installs Versioner to /Users/anubis/Apps/Versioner/

set -Eeuo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSIONER_DIR="${VERSIONER_DIR:-/Users/anubis/Apps/Versioner}"
VERSIONER_EXECUTABLE="$VERSIONER_DIR/Versioner.Cli"

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
Versioner Install Script

Usage: $0 [OPTIONS]

OPTIONS:
    -d, --dir DIR             Installation directory [default: /Users/anubis/Apps/Versioner]
    -f, --force               Force installation (overwrite existing)
    -b, --build               Build before installing
    -h, --help                Show this help message

EXAMPLES:
    $0                                    # Install to default directory
    $0 -d /custom/path                    # Install to custom directory
    $0 -f -b                              # Force install with build

ENVIRONMENT VARIABLES:
    VERSIONER_DIR    Installation directory (overrides -d)
EOF
}

# Parse command line arguments
parse_args() {
    FORCE=false
    BUILD=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                VERSIONER_DIR="$2"
                VERSIONER_EXECUTABLE="$VERSIONER_DIR/Versioner.Cli"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--build)
                BUILD=true
                shift
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

# Validate environment
validate_environment() {
    log_info "Validating environment..."
    
    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/Versioner.sln" ]]; then
        log_error "Versioner.sln not found. Please run this script from the project root or scripts directory."
        exit 1
    fi
    
    # Check if unzip is available
    if ! command -v unzip &> /dev/null; then
        log_error "unzip is not installed or not in PATH"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Check if installation exists
check_existing_installation() {
    if [[ -d "$VERSIONER_DIR" && "$(ls -A "$VERSIONER_DIR" 2>/dev/null)" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            log_warning "Existing installation found, will be overwritten"
            return 0
        else
            log_warning "Existing installation found at $VERSIONER_DIR"
            log_info "Use -f/--force to overwrite existing installation"
            return 1
        fi
    fi
    return 0
}

# Build Versioner if needed
build_versioner() {
    if [[ "$BUILD" == "true" ]]; then
        log_info "Building Versioner..."
        "$SCRIPT_DIR/build-linux.sh"
        if [[ $? -eq 0 ]]; then
            log_success "Build completed successfully"
        else
            log_error "Build failed"
            exit 1
        fi
    fi
}

# Find available build
find_build() {
    log_info "Looking for available builds..."
    
    # Check for Linux build
    if [[ -f "$PROJECT_ROOT/DEPLOYMENT/Versioner.Linux.zip" ]]; then
        log_success "Found Linux build"
        echo "$PROJECT_ROOT/DEPLOYMENT/Versioner.Linux.zip"
        return 0
    fi
    
    # Check for Windows build
    if [[ -f "$PROJECT_ROOT/DEPLOYMENT/Versioner.Windows.zip" ]]; then
        log_success "Found Windows build"
        echo "$PROJECT_ROOT/DEPLOYMENT/Versioner.Windows.zip"
        return 0
    fi
    
    log_warning "No built version found"
    return 1
}

# Create installation directory
create_installation_directory() {
    log_info "Creating installation directory: $VERSIONER_DIR"
    
    if [[ -d "$VERSIONER_DIR" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            log_info "Removing existing installation..."
            rm -rf "$VERSIONER_DIR"
        fi
    fi
    
    mkdir -p "$VERSIONER_DIR"
    if [[ $? -eq 0 ]]; then
        log_success "Installation directory created"
    else
        log_error "Failed to create installation directory"
        exit 1
    fi
}

# Install Versioner
install_versioner() {
    local build_file="$1"
    
    log_info "Installing Versioner from $build_file"
    
    # Extract package
    if unzip -o "$build_file" -d "$VERSIONER_DIR"; then
        log_success "Package extracted successfully"
    else
        log_error "Package extraction failed"
        exit 1
    fi
    
    # Set executable permissions
    if [[ -f "$VERSIONER_EXECUTABLE" ]]; then
        chmod +x "$VERSIONER_EXECUTABLE"
        log_success "Executable permissions set for Versioner.Cli"
    elif [[ -f "$VERSIONER_DIR/Versioner.Cli.exe" ]]; then
        chmod +x "$VERSIONER_DIR/Versioner.Cli.exe"
        log_success "Executable permissions set for Versioner.Cli.exe"
    else
        log_warning "No Versioner executable found"
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check if executable exists
    if [[ -f "$VERSIONER_EXECUTABLE" ]]; then
        log_success "Linux executable found: $VERSIONER_EXECUTABLE"
        
        # Test executable
        if "$VERSIONER_EXECUTABLE" --help >/dev/null 2>&1; then
            log_success "Versioner.Cli is working correctly"
        else
            log_warning "Versioner.Cli test failed (this might be normal if dependencies are missing)"
        fi
    elif [[ -f "$VERSIONER_DIR/Versioner.Cli.exe" ]]; then
        log_success "Windows executable found: $VERSIONER_DIR/Versioner.Cli.exe"
        log_info "Windows executable cannot be tested on macOS/Linux"
    else
        log_error "No Versioner executable found"
        exit 1
    fi
    
    # Check for README
    if [[ -f "$VERSIONER_DIR/README.md" ]]; then
        log_success "README.md found"
    else
        log_warning "README.md not found"
    fi
    
    # Count installed files
    local file_count
    file_count=$(find "$VERSIONER_DIR" -type f | wc -l | tr -d ' ')
    log_info "Installed files: $file_count"
}

# Show installation summary
show_summary() {
    log_header "📊 INSTALLATION SUMMARY"
    
    echo -e "${WHITE}Installation Directory: ${CYAN}$VERSIONER_DIR${NC}"
    echo -e "${WHITE}Executable: ${CYAN}$VERSIONER_EXECUTABLE${NC}"
    echo -e "${WHITE}Installation Time: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    
    # Show directory contents
    echo -e "\n${WHITE}Installed Files:${NC}"
    ls -la "$VERSIONER_DIR" | head -10
    local total_files
    total_files=$(find "$VERSIONER_DIR" -type f | wc -l | tr -d ' ')
    if [[ $total_files -gt 10 ]]; then
        echo -e "${CYAN}... and $((total_files - 10)) more files${NC}"
    fi
}

# Main installation process
main() {
    log_header "🚀 VERSIONER INSTALLATION SCRIPT 🚀"
    echo -e "${WHITE}Project Root: ${CYAN}$PROJECT_ROOT${NC}"
    echo -e "${WHITE}Script Directory: ${CYAN}$SCRIPT_DIR${NC}"
    echo -e "${WHITE}Target Directory: ${CYAN}$VERSIONER_DIR${NC}"
    echo -e "${WHITE}Timestamp: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    
    # Parse arguments
    parse_args "$@"
    
    # Validate environment
    validate_environment
    
    # Check existing installation
    if ! check_existing_installation; then
        exit 0
    fi
    
    # Build if requested
    build_versioner
    
    # Find available build
    local build_file
    if ! build_file=$(find_build); then
        log_info "No build found, building now..."
        "$SCRIPT_DIR/build-linux.sh"
        build_file=$(find_build)
        if [[ $? -ne 0 ]]; then
            log_error "Failed to find or create build"
            exit 1
        fi
    fi
    
    # Create installation directory
    create_installation_directory
    
    # Install Versioner
    install_versioner "$build_file"
    
    # Verify installation
    verify_installation
    
    # Show summary
    show_summary
    
    log_success "Versioner installed successfully!"
    echo -e "${WHITE}You can now use the versioning scripts in your projects.${NC}"
    echo -e "${CYAN}Example: $VERSIONER_EXECUTABLE --help${NC}"
}

# Run main function with all arguments
main "$@"
