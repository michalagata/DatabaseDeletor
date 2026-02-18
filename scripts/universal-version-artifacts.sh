#!/usr/bin/env zsh
# Universal Versioner Artifacts Script
# Works with any .NET project in any repository
# Uses dotnet Versioner.Cli.dll for cross-platform compatibility

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
VERSIONER_DIR="${VERSIONER_DIR:-}"
WORKING_DIR="${WORKING_DIR:-$(pwd)}"
LOG_LEVEL="${LOG_LEVEL:-I}"
STORE_VERSION_FILE="${STORE_VERSION_FILE:-true}"
USE_DEFAULTS="${USE_DEFAULTS:-true}"
CLEANUP_BACKUPS="${CLEANUP_BACKUPS:-true}"

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

log_step() {
    echo -e "\n${BLUE}🔧 $1${NC}"
}

# Help function
show_help() {
    cat << EOF
Universal Versioner Artifacts Script

This script provides universal versioning for any .NET project using Versioner.Cli.dll.
It automatically detects and uses the appropriate Versioner installation.

Usage: $0 [OPTIONS]

OPTIONS:
    -w, --working-dir DIR     Working directory [default: current directory]
    -l, --log-level LEVEL     Log level (V|D|I|W|E|F) [default: I]
    -s, --store-version       Store version in version.txt file [default: true]
    -d, --use-defaults        Use default settings [default: true]
    -v, --versioner-dir DIR   Versioner installation directory [auto-detect]
    -c, --cleanup-backups     Clean up .bak files after versioning [default: true]
    -h, --help                Show this help message

EXAMPLES:
    $0                                    # Version current directory with defaults
    $0 -w /path/to/project -d             # Version specific project with defaults
    $0 -l D -w /path/to/project           # Debug mode for specific project
    $0 -v /path/to/versioner              # Use specific Versioner installation
    $0 -w /path/to/project -s              # Version with version.txt stored in repository root

ENVIRONMENT VARIABLES:
    VERSIONER_DIR              Versioner installation directory (overrides -v)
    WORKING_DIR                Working directory (overrides -w)
    LOG_LEVEL                  Log level (overrides -l)
    STORE_VERSION_FILE         Store version file flag (overrides -s)
    USE_DEFAULTS               Use defaults flag (overrides -d)
    CLEANUP_BACKUPS            Cleanup backups flag (overrides -c)

AUTO-DETECTION:
    The script will automatically search for Versioner in the following locations:
    1. VERSIONER_DIR environment variable
    2. /Users/anubis/Apps/Versioner/
    3. ./versioner/ directory
    4. ../versioner/ directory
    5. ~/.local/bin/versioner/
    6. /usr/local/bin/versioner/
    7. /opt/versioner/
    8. Any directory containing Versioner.Cli.dll

REQUIREMENTS:
    - .NET 10.0 Runtime or SDK
    - Git repository (for versioning)
    - Versioner.Cli.dll (auto-detected or specified)
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -w=*|--working-dir=*)
                WORKING_DIR="${1#*=}"
                shift
                ;;
            -w|--working-dir)
                WORKING_DIR="$2"
                shift 2
                ;;
            -l=*|--log-level=*)
                LOG_LEVEL="${1#*=}"
                shift
                ;;
            -l|--log-level)
                LOG_LEVEL="$2"
                shift 2
                ;;
            -s|--store-version)
                STORE_VERSION_FILE="true"
                shift
                ;;
            -d|--use-defaults)
                USE_DEFAULTS="true"
                shift
                ;;
            -v=*|--versioner-dir=*)
                VERSIONER_DIR="${1#*=}"
                shift
                ;;
            -v|--versioner-dir)
                VERSIONER_DIR="$2"
                shift 2
                ;;
            -c|--cleanup-backups)
                CLEANUP_BACKUPS="true"
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
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository. Versioner requires a git repository."
        exit 1
    fi
    
    # Check if working directory exists
    if [[ ! -d "$WORKING_DIR" ]]; then
        log_error "Working directory does not exist: $WORKING_DIR"
        exit 1
    fi
    
    # Validate log level
    local valid_levels="V D I W E F"
    if [[ ! " $valid_levels " =~ " $LOG_LEVEL " ]]; then
        log_error "Invalid log level: $LOG_LEVEL. Must be one of: $valid_levels"
        exit 1
    fi
    
    # Check if .NET is available
    if ! command -v dotnet &> /dev/null; then
        log_error ".NET runtime not found. Please install .NET 8.0 or later."
        exit 1
    fi
    
    local dotnet_version
    dotnet_version=$(dotnet --version 2>/dev/null || echo "unknown")
    log_info ".NET version: $dotnet_version"
    
    log_success "Environment validation passed"
}

# Auto-detect Versioner installation
detect_versioner() {
    # If VERSIONER_DIR is already set, use it
    if [[ -n "$VERSIONER_DIR" ]]; then
        if [[ -f "$VERSIONER_DIR/Cli/Versioner.Cli.csproj" ]]; then
            echo "$VERSIONER_DIR"
            return 0
        else
            log_error "Cli/Versioner.Cli.csproj not found in specified directory: $VERSIONER_DIR"
            exit 1
        fi
    fi
    
    # Search for Versioner in common locations
    local current_dir
    current_dir=$(pwd)
    
    # First, check if we're in a Versioner project directory
    if [[ -f "$current_dir/Cli/Versioner.Cli.csproj" ]]; then
        echo "$current_dir"
        return 0
    fi
    
    # Search in parent directories
    local search_dir="$current_dir"
    while [[ "$search_dir" != "/" ]]; do
        if [[ -f "$search_dir/Cli/Versioner.Cli.csproj" ]]; then
            echo "$search_dir"
            return 0
        fi
        search_dir=$(dirname "$search_dir")
    done
    
    # Search in standard locations
    local search_paths=(
        "/Users/anubis/Apps/Versioner"
        "./versioner"
        "../versioner"
        "$HOME/.local/bin/versioner"
        "/usr/local/bin/versioner"
        "/opt/versioner"
        "/usr/bin/versioner"
        "/usr/local/versioner"
    )
    
    # Check each path
    for path in "${search_paths[@]}"; do
        if [[ -f "$path/Cli/Versioner.Cli.csproj" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    log_error "Versioner project not found. Please:"
    log_error "1. Run this script from a Versioner project directory"
    log_error "2. Set VERSIONER_DIR environment variable to the Versioner project root"
    log_error "3. Use -v/--versioner-dir option to specify the Versioner project root"
    log_error "4. Install Versioner in one of the standard locations"
    exit 1
}

# Run Versioner
run_versioner() {
    local versioner_dir="$1"
    
    log_step "Running Versioner..."
    log_info "Versioner directory: $versioner_dir"
    log_info "Working directory: $WORKING_DIR"
    log_info "Log level: $LOG_LEVEL"
    log_info "Use defaults: $USE_DEFAULTS"
    log_info "Store version file: $STORE_VERSION_FILE"
    
    # Prepare Versioner command
    local versioner_args=(
        "-w=$WORKING_DIR"
        "-l=$LOG_LEVEL"
    )
    
    # Add use defaults flag
    if [[ "$USE_DEFAULTS" == "true" ]]; then
        versioner_args+=("-d")
    fi
    
    # Always add store version file flag (-s) to create version.txt in repository root
    versioner_args+=("-s")
    
    # Change to project root directory (where the .csproj files are)
    cd "$versioner_dir" || {
        log_error "Failed to change to project root directory: $versioner_dir"
        exit 1
    }
    
    # Run Versioner using dotnet run
    log_info "Executing: dotnet run --project Cli/Versioner.Cli.csproj -- ${versioner_args[*]}"
    dotnet run --project Cli/Versioner.Cli.csproj -- "${versioner_args[@]}"
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Versioning completed successfully"
    else
        log_error "Versioning failed with exit code: $exit_code"
    fi
    
    return $exit_code
}

# Clean up backup files
cleanup_backup_files() {
    if [[ "$CLEANUP_BACKUPS" != "true" ]]; then
        log_info "Skipping backup file cleanup (disabled)"
        return 0
    fi
    
    log_step "Cleaning up backup files..."
    
    local backup_count=0
    find "$WORKING_DIR" -name "*.bak" -type f -print0 | while IFS= read -r -d '' file; do
        log_info "Removing: $file"
        rm "$file"
        ((backup_count++))
    done
    
    if [[ $backup_count -gt 0 ]]; then
        log_success "Removed $backup_count backup files"
    else
        log_info "No backup files found"
    fi
}

# Show version information
show_version_info() {
    log_step "Version information:"
    
    # Show git information
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local git_hash
        git_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        local git_branch
        git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        local git_commit_count
        git_commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "unknown")
        
        echo -e "${WHITE}  Git hash: ${CYAN}$git_hash${NC}"
        echo -e "${WHITE}  Git branch: ${CYAN}$git_branch${NC}"
        echo -e "${WHITE}  Commit count: ${CYAN}$git_commit_count${NC}"
    fi
    
    # Show version file if it exists
    if [[ -f "$WORKING_DIR/version.txt" ]]; then
        echo -e "${WHITE}  Version file:${NC}"
        cat "$WORKING_DIR/version.txt" | sed 's/^/    /'
    fi
}

# Show summary
show_summary() {
    log_header "📊 VERSIONING SUMMARY"
    
    echo -e "${WHITE}Working Directory: ${CYAN}$WORKING_DIR${NC}"
    echo -e "${WHITE}Log Level: ${CYAN}$LOG_LEVEL${NC}"
    echo -e "${WHITE}Use Defaults: ${CYAN}$USE_DEFAULTS${NC}"
    echo -e "${WHITE}Store Version File: ${CYAN}$STORE_VERSION_FILE${NC}"
    echo -e "${WHITE}Cleanup Backups: ${CYAN}$CLEANUP_BACKUPS${NC}"
    echo -e "${WHITE}Versioning Time: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    
    # Check for versioned files
    local versioned_files=0
    if [[ -f "$WORKING_DIR/version.txt" ]]; then
        versioned_files=$((versioned_files + 1))
    fi
    
    # Count .csproj files that might have been versioned
    local csproj_files
    csproj_files=$(find "$WORKING_DIR" -name "*.csproj" -type f | wc -l | tr -d ' ')
    if [[ $csproj_files -gt 0 ]]; then
        versioned_files=$((versioned_files + csproj_files))
    fi
    
    echo -e "${WHITE}Files processed: ${CYAN}$versioned_files${NC}"
}

# Main versioning process
main() {
    log_header "🚀 UNIVERSAL VERSIONER ARTIFACTS SCRIPT 🚀"
    echo -e "${WHITE}Script Directory: ${CYAN}$SCRIPT_DIR${NC}"
    echo -e "${WHITE}Working Directory: ${CYAN}$WORKING_DIR${NC}"
    echo -e "${WHITE}Timestamp: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    
    # Parse arguments
    parse_args "$@"
    
    # Validate environment
    validate_environment
    
    # Auto-detect Versioner
    log_info "Auto-detecting Versioner installation..."
    local versioner_dir
    versioner_dir=$(detect_versioner)
    log_success "Found Versioner at: $versioner_dir"
    
    # Run Versioner
    run_versioner "$versioner_dir"
    local exit_code=$?
    
    # Clean up backup files
    cleanup_backup_files
    
    # Show version information
    show_version_info
    
    # Show summary
    show_summary
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Versioning process completed successfully!"
    else
        log_error "Versioning process failed with exit code: $exit_code"
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"
