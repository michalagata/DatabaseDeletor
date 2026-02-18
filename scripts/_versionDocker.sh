#!/usr/bin/env zsh
set -Eeuo pipefail
IFS=$'\n\t'

# Version script for Docker images
# Detects and uses Versioner tool for versioning Docker-related files
# Follows bash best practices from .mdc rules

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
ROOT_DIR="${ROOT_DIR:-$SCRIPT_DIR/..}"
# Default to git root if in a git repository, otherwise use ROOT_DIR
if git rev-parse --git-dir > /dev/null 2>&1; then
    PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel)}"
else
    PROJECT_ROOT="${PROJECT_ROOT:-$ROOT_DIR}"
fi

# shellcheck disable=SC1091
[[ -f "$SCRIPT_DIR/_commonDocker.sh" ]] && source "$SCRIPT_DIR/_commonDocker.sh" || true
[[ -f "$SCRIPT_DIR/_load_env.sh" ]] && source "$SCRIPT_DIR/_load_env.sh" || true

# Source common functions for .NET SDK and project detection
# shellcheck disable=SC1091
if [[ -f "$SCRIPT_DIR/_common.sh" ]]; then
    source "$SCRIPT_DIR/_common.sh"
fi

# Source .NET SDK maintenance functions
# shellcheck disable=SC1091
if [[ -f "$SCRIPT_DIR/maintainDotnetSDK.sh" ]]; then
    source "$SCRIPT_DIR/maintainDotnetSDK.sh"
fi

# Define functions if not already defined
type log >/dev/null 2>&1 || log()   { printf "[%s] %s\n" "$(date +'%F %T')" "$*"; }
type warn >/dev/null 2>&1 || warn() { printf "\033[33m[WARN] %s\033[0m\n" "$*"; }
type error> /dev/null 2>&1 || error(){ printf "\033[31m[ERROR] %s\033[0m\n" "$*" >&2; }
type die  >/dev/null 2>&1 || die()  { error "$*"; exit 1; }

run() {
  if [[ "${DRY_RUN-0}" == "1" ]]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

# Auto-detect Versioner installation (same logic as _versionArtifacts.sh)
detect_versioner() {
    # If VERSIONER_DIR is already set, use it
    if [[ -n "${VERSIONER_DIR:-}" ]]; then
        if [[ -f "$VERSIONER_DIR/Cli/Versioner.Cli.csproj" ]]; then
            echo "$VERSIONER_DIR"
            return 0
        else
            log "ERROR" "Cli/Versioner.Cli.csproj not found in specified directory: $VERSIONER_DIR"
            return 1
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
    
    return 1
}

# Run Versioner for Docker versioning
run_versioner_for_docker() {
    local versioner_dir="$1"
    local working_dir="${2:-$PROJECT_ROOT}"
    
    log "INFO" "Running Versioner for Docker versioning..."
    log "INFO" "Versioner directory: $versioner_dir"
    log "INFO" "Working directory: $working_dir"
    
    # Ensure .NET SDK is available
    if ! ensure_dotnet_sdk; then
        log "ERROR" "Cannot run Versioner - .NET SDK is required"
        return 1
    fi
    
    # ALWAYS use source code to avoid stdin hanging issues with installed binaries/DLLs
    if [[ -f "$versioner_dir/Cli/Versioner.Cli.csproj" ]]; then
        cd "$versioner_dir" || {
            log "ERROR" "Failed to change to Versioner directory: $versioner_dir"
            return 1
        }
        log "INFO" "Using Versioner from source: $versioner_dir/Cli/Versioner.Cli.csproj"
        log "INFO" "Executing: dotnet run --project Cli/Versioner.Cli.csproj -- -w=$working_dir -d -s"
        if dotnet run --project Cli/Versioner.Cli.csproj -- -w="$working_dir" -d -s; then
            log "INFO" "Versioner completed successfully"
            return 0
        else
            log "ERROR" "Versioner failed"
            return 1
        fi
    else
        log "ERROR" "Versioner source not found at $versioner_dir/Cli/Versioner.Cli.csproj"
        return 1
    fi
}

# Get version from Versioner or fallback to default
get_version() {
    local version=""
    
    # Ensure PROJECT_ROOT is set to git root for version.txt placement
    if git rev-parse --git-dir > /dev/null 2>&1; then
        PROJECT_ROOT=$(git rev-parse --show-toplevel)
    fi
    
    # Try to get version from VERSION file (created by Versioner)
    if [[ -f "$PROJECT_ROOT/VERSION" ]]; then
        version=$(cat "$PROJECT_ROOT/VERSION" | tr -d '\n\r' | xargs)
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi
    
    # Try to get version from version.txt (created by Versioner in repository root)
    if [[ -f "$PROJECT_ROOT/version.txt" ]]; then
        version=$(cat "$PROJECT_ROOT/version.txt" | tr -d '\n\r' | xargs)
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi
    
    # Try to detect and run Versioner (will create version.txt in repository root with -s flag)
    local versioner_dir
    if versioner_dir=$(detect_versioner); then
        log "INFO" "Found Versioner at: $versioner_dir"
        log "INFO" "Running Versioner to create version.txt in repository root: $PROJECT_ROOT"
        if run_versioner_for_docker "$versioner_dir" "$PROJECT_ROOT"; then
            # Try to read version.txt from repository root after Versioner run
            if [[ -f "$PROJECT_ROOT/version.txt" ]]; then
                version=$(cat "$PROJECT_ROOT/version.txt" | tr -d '\n\r' | xargs)
                if [[ -n "$version" ]]; then
                    echo "$version"
                    return 0
                fi
            fi
            # Fallback to VERSION file if version.txt not found
            if [[ -f "$PROJECT_ROOT/VERSION" ]]; then
                version=$(cat "$PROJECT_ROOT/VERSION" | tr -d '\n\r' | xargs)
                if [[ -n "$version" ]]; then
                    echo "$version"
                    return 0
                fi
            fi
        fi
    else
        log "WARN" "Versioner not found, using default version"
    fi
    
    # Fallback to default version
    echo "1.0.0"
}

# Configuration
readonly IMAGE_NAME="${IMAGE_NAME:-database-deletor}"
VERSION=$(get_version)
readonly VERSION
readonly GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
readonly GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
readonly BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
readonly PLATFORM="${PLATFORM:-linux/amd64}"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message"
            ;;
    esac
}

# Function to show version information
show_version_info() {
    log "INFO" "Version Information:"
    echo "  Image Name: $IMAGE_NAME"
    echo "  Version: $VERSION"
    echo "  Git Commit: $GIT_COMMIT"
    echo "  Git Branch: $GIT_BRANCH"
    echo "  Build Date: $BUILD_DATE"
    echo "  Platform: $PLATFORM"
}

# Function to generate tags
generate_tags() {
    local custom_tags="${1:-}"
    local tags=()
    
    tags+=("${IMAGE_NAME}:latest")
    tags+=("${IMAGE_NAME}:${VERSION}")
    tags+=("${IMAGE_NAME}:${GIT_COMMIT}")
    tags+=("${IMAGE_NAME}:$(date +'%Y%m%d')")
    tags+=("${IMAGE_NAME}:$(date +'%Y%m%d-%H%M%S')")
    
    if [[ -n "$custom_tags" ]]; then
        IFS=',' read -ra CUSTOM_TAGS_ARRAY <<< "$custom_tags"
        for tag in "${CUSTOM_TAGS_ARRAY[@]}"; do
            tag=$(echo "$tag" | xargs) # Trim whitespace
            if [[ -n "$tag" ]]; then
                tags+=("${IMAGE_NAME}:${tag}")
            fi
        done
    fi
    
    printf '%s\n' "${tags[@]}"
}

# Function to get next version based on SemVer
get_next_version() {
    local current_version="$1"
    local type="$2"
    
    local major=$(echo "$current_version" | cut -d. -f1)
    local minor=$(echo "$current_version" | cut -d. -f2)
    local patch=$(echo "$current_version" | cut -d. -f3)
    
    case "$type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            log "ERROR" "Invalid version type: $type. Must be major, minor, or patch."
            exit 1
            ;;
    esac
    echo "${major}.${minor}.${patch}"
}

# Function to update version in files (placeholder)
update_version_in_files() {
    local new_version="$1"
    log "INFO" "Updating version to $new_version in project files (e.g., Dockerfile, README.md)"
    # Example: sed -i "s/^VERSION=.*/VERSION=\"$new_version\"/" _versionDocker.sh
    # Example: sed -i "s/LABEL version=\".*\"/LABEL version=\"$new_version\"/" Dockerfile
    # This would require more specific file paths and regexes
    log "WARN" "Version update in files is a placeholder and needs specific implementation."
}

# Function to validate version format
validate_version_format() {
    local version_to_validate="$1"
    if [[ "$version_to_validate" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "INFO" "Version '$version_to_validate' is valid SemVer."
        return 0
    else
        log "ERROR" "Version '$version_to_validate' is not a valid SemVer (X.Y.Z)."
        return 1
    fi
}

usage() {
  cat <<'USAGE'
Usage:
  $(basename "$0") [--help] [--dry-run] [--verbose] [ACTION] [OPTIONS]
  
Actions:
  show                    Show version information and generated tags (default)
  tags [CUSTOM_TAGS]      Show all generated tags with optional custom tags
  next [TYPE]             Show next version (major/minor/patch, default: patch)
  update VERSION          Update version in all files
  validate                Validate current version format
  
Options:
  CUSTOM_TAGS             Comma-separated list of custom tags
  TYPE                    Version type: major, minor, patch (default: patch)
  VERSION                 New version number
  
Examples:
  $(basename "$0")                      # Show version info and tags
  $(basename "$0") tags                 # Show all generated tags
  $(basename "$0") tags dev,test        # Show tags with custom dev and test tags
  $(basename "$0") next major           # Show next major version
  $(basename "$0") update 2.2.0         # Update version to 2.2.0
  $(basename "$0") validate             # Validate current version format
USAGE
}

for a in "$@"; do
  case "$a" in
    --help|-h) usage; exit 0 ;;
    --dry-run) export DRY_RUN=1 ;;
    --verbose) export TRACE=1; set -x ;;
    *) ;;
  esac
done

# Main function
main() {
    local action="${1:-show}"
    shift || true # Shift if arguments exist
    
    case "$action" in
        "show")
            show_version_info
            log "INFO" "Generated tags:"
            generate_tags
            ;;
        "tags")
            local custom_tags="$1"
            log "INFO" "Generated tags:"
            generate_tags "$custom_tags"
            ;;
        "next")
            local type="${1:-patch}"
            log "INFO" "Current version: $VERSION"
            local next_version=$(get_next_version "$VERSION" "$type")
            log "INFO" "Next $type version: $next_version"
            ;;
        "update")
            local new_version="$1"
            if [[ -z "$new_version" ]]; then
                log "ERROR" "New version not provided for 'update' action."
                exit 1
            fi
            validate_version_format "$new_version" || exit 1
            update_version_in_files "$new_version"
            log "INFO" "Version updated to $new_version. Please rebuild and re-tag images."
            ;;
        "validate")
            validate_version_format "$VERSION"
            ;;
        *)
            log "ERROR" "Unknown action: $action"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"