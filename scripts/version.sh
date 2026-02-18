#!/usr/bin/env zsh
# Versioning script for Versioner application

set -Eeuo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORKING_DIR="${WORKING_DIR:-$PROJECT_ROOT}"
CONFIG_FILE="${CONFIG_FILE:-$PROJECT_ROOT/ProjectOverride.json}"
LOG_LEVEL="${LOG_LEVEL:-Information}"
STORE_VERSION_FILE="${STORE_VERSION_FILE:-false}"
USE_DEFAULTS="${USE_DEFAULTS:-false}"

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

# Help function
show_help() {
    cat << EOF
Versioner Versioning Script

Usage: $0 [OPTIONS]

OPTIONS:
    -w, --working-dir DIR     Working directory [default: project root]
    -c, --config FILE         Configuration file [default: ProjectOverride.json]
    -l, --log-level LEVEL     Log level (Verbose|Debug|Information|Warning|Error|Fatal) [default: Information]
    -s, --store-version       Store version in version.txt file
    -d, --use-defaults        Use default settings
    -h, --help                Show this help message

EXAMPLES:
    $0                                    # Version current project with defaults
    $0 -w /path/to/project -d             # Version specific project with defaults
    $0 -c custom-config.json -s           # Use custom config and store version file
    $0 -l Debug -w /path/to/project       # Debug mode for specific project

ENVIRONMENT VARIABLES:
    WORKING_DIR        Working directory (overrides -w)
    CONFIG_FILE        Configuration file (overrides -c)
    LOG_LEVEL          Log level (overrides -l)
    STORE_VERSION_FILE Store version file flag (overrides -s)
    USE_DEFAULTS       Use defaults flag (overrides -d)
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -w|--working-dir)
                WORKING_DIR="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
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
    
    # Check if config file exists (if not using defaults)
    if [[ "$USE_DEFAULTS" != "true" && ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file does not exist: $CONFIG_FILE"
        exit 1
    fi
    
    # Validate log level
    local valid_levels=("Verbose" "Debug" "Information" "Warning" "Error" "Fatal")
    if [[ ! " ${valid_levels[*]} " =~ " $LOG_LEVEL " ]]; then
        log_error "Invalid log level: $LOG_LEVEL. Must be one of: ${valid_levels[*]}"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Check if Versioner is available
check_versioner() {
    log_info "Checking Versioner availability..."
    
    # Check if we can find Versioner CLI
    local versioner_paths=(
        "$PROJECT_ROOT/DEPLOYMENT/Versioner.Cli"
        "$PROJECT_ROOT/DEPLOYMENT/Versioner.Cli.exe"
        "./Versioner.Cli"
        "./Versioner.Cli.exe"
        "versioner"
    )
    
    local versioner_cmd=""
    for path in "${versioner_paths[@]}"; do
        if command -v "$path" &> /dev/null || [[ -f "$path" ]]; then
            versioner_cmd="$path"
            break
        fi
    done
    
    if [[ -z "$versioner_cmd" ]]; then
        log_error "Versioner CLI not found. Please build the project first."
        log_info "Run: $SCRIPT_DIR/build.sh"
        exit 1
    fi
    
    log_success "Versioner found: $versioner_cmd"
    echo "$versioner_cmd"
}

# Run Versioner
run_versioner() {
    local versioner_cmd="$1"
    
    log_info "Running Versioner..."
    log_info "Working directory: $WORKING_DIR"
    log_info "Log level: $LOG_LEVEL"
    log_info "Use defaults: $USE_DEFAULTS"
    log_info "Store version file: $STORE_VERSION_FILE"
    
    # Prepare Versioner command
    local versioner_args=(
        --workingfolder "$WORKING_DIR"
        --loglevel "$LOG_LEVEL"
    )
    
    # Add config file if not using defaults
    if [[ "$USE_DEFAULTS" != "true" && -f "$CONFIG_FILE" ]]; then
        versioner_args+=(--configurationfile "$CONFIG_FILE")
    elif [[ "$USE_DEFAULTS" == "true" ]]; then
        versioner_args+=(--usedefaults)
    fi
    
    # Add store version file flag
    if [[ "$STORE_VERSION_FILE" == "true" ]]; then
        versioner_args+=(--storeversionfile)
    fi
    
    # Change to working directory
    cd "$WORKING_DIR"
    
    # Run Versioner
    log_info "Executing: $versioner_cmd ${versioner_args[*]}"
    "$versioner_cmd" "${versioner_args[@]}"
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Versioning completed successfully"
    else
        log_error "Versioning failed with exit code: $exit_code"
    fi
    
    return $exit_code
}

# Show version information
show_version_info() {
    log_info "Version information:"
    
    # Show git information
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local git_hash
        git_hash=$(git rev-parse --short HEAD)
        local git_branch
        git_branch=$(git branch --show-current)
        local git_commit_count
        git_commit_count=$(git rev-list --count HEAD)
        
        echo "  Git hash: $git_hash"
        echo "  Git branch: $git_branch"
        echo "  Commit count: $git_commit_count"
    fi
    
    # Show version file if it exists
    if [[ -f "$WORKING_DIR/version.txt" ]]; then
        echo "  Version file:"
        cat "$WORKING_DIR/version.txt" | sed 's/^/    /'
    fi
}

# Main versioning process
main() {
    log_info "Starting Versioner versioning process..."
    log_info "Project root: $PROJECT_ROOT"
    log_info "Script directory: $SCRIPT_DIR"
    
    # Parse arguments
    parse_args "$@"
    
    # Validate environment
    validate_environment
    
    # Check Versioner availability
    local versioner_cmd
    versioner_cmd=$(check_versioner)
    
    # Run Versioner
    run_versioner "$versioner_cmd"
    local exit_code=$?
    
    # Show version information
    show_version_info
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Versioner versioning process completed successfully!"
    else
        log_error "Versioner versioning process failed with exit code: $exit_code"
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"
