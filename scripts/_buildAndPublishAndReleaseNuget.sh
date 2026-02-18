#!/usr/bin/env zsh
set -Eeuo pipefail
IFS=$'\n\t'
# _buildAndPublishAndReleaseNuget.sh
# Comprehensive script for building, versioning, testing, and releasing to NuGet.org
# WORKFLOW:
# 1. Versioning artifacts (_versionArtifacts.sh)
# 2. Build for all platforms (Linux, macOS, Windows) - self-contained
# 3. Run Tests (ABORT ON FAILURE)
# 4. Publish to NuGet.org (_publishNuget.sh)

# Load common functions
# Universal script directory detection (bash and zsh compatible)
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
    log_header() { echo -e "\033[35m$1\033[0m"; }
    step() { echo -e "\n\033[36m$1\033[0m"; }
fi

PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Scripts
VERSION_SCRIPT="$SCRIPT_DIR/_versionArtifacts.sh"
BUILD_LINUX_SCRIPT="$SCRIPT_DIR/_performBuildLinux.sh"
BUILD_MACOS_SCRIPT="$SCRIPT_DIR/_performBuildMacOS.sh"
BUILD_WINDOWS_SCRIPT="$SCRIPT_DIR/_performBuildWindows.sh"
PUBLISH_NUGET_SCRIPT="$SCRIPT_DIR/_publishNuget.sh"

# Parse arguments
DRY_RUN=false
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        DRY_RUN=true
    fi
done

log_header "🚀 BUILD AND PUBLISH AND RELEASE NUGET 🚀"
echo  "Project Root: $PROJECT_ROOT"
echo  "Dry Run: $DRY_RUN"

# Resolve API Key (Env Var or File)
resolve_api_key() {
    if [[ -n "${NUGET_API_KEY:-}" ]]; then
        return 0
    fi
    
    # Check current directory and project root for key file
    local key_file=".nuget-api-key"
    local key_value=""
    
    if [[ -f "$key_file" ]]; then
        key_value="$(cat "$key_file" | tr -d ' \t\r\n')"
    elif [[ -f "$PROJECT_ROOT/$key_file" ]]; then
        key_value="$(cat "$PROJECT_ROOT/$key_file" | tr -d ' \t\r\n')"
    fi
    
    if [[ -n "$key_value" ]]; then
        export NUGET_API_KEY="$key_value"
        info "Loaded NUGET_API_KEY from file."
        return 0
    fi
    
    return 1
}

# Validation
resolve_api_key

if [[ -z "${NUGET_API_KEY:-}" ]] && [[ "$DRY_RUN" == "false" ]]; then
    error "NUGET_API_KEY environment variable is not set and .nuget-api-key file not found!"
    error "Option A: export NUGET_API_KEY=\"your-key\""
    error "Option B: echo \"your-key\" > .nuget-api-key"
    exit 1
fi


# Function to check scripts existence
check_script() {
    if [[ ! -f "$1" ]]; then
        error "Script not found: $1"
        exit 1
    fi
    chmod +x "$1"
}

check_script "$VERSION_SCRIPT"
check_script "$BUILD_LINUX_SCRIPT"
check_script "$BUILD_MACOS_SCRIPT"
check_script "$BUILD_WINDOWS_SCRIPT"
check_script "$PUBLISH_NUGET_SCRIPT"

# 1. Versioning
step "KROK 1: Wersjonowanie artefaktów"
if ! "$VERSION_SCRIPT" -w "$PROJECT_ROOT"; then
    error "Versioning failed!"
    exit 1
fi

# Verify version
if [[ -f "$PROJECT_ROOT/version.txt" ]]; then
    VERSION=$(cat "$PROJECT_ROOT/version.txt")
    info "Version determined: $VERSION"
else
    error "version.txt not found after versioning!"
    exit 1
fi

# 2. Build for all platforms
step "KROK 2: Build dla wszystkich platform"
info "Building for Linux..."
if ! "$BUILD_LINUX_SCRIPT"; then
    error "Linux build failed!"
    exit 1
fi

info "Building for macOS..."
if ! "$BUILD_MACOS_SCRIPT"; then
    error "macOS build failed!"
    exit 1
fi

info "Building for Windows..."
if ! "$BUILD_WINDOWS_SCRIPT"; then
    error "Windows build failed!"
    exit 1
fi

success "All builds completed successfully."

# 3. Run Tests
step "KROK 3: Uruchomienie testów"
# Find test projects
TEST_PROJECTS=()
while IFS= read -r -d '' file; do
    TEST_PROJECTS+=("$file")
done < <(find "$PROJECT_ROOT" -name "*Tests.csproj" -print0)

if [[ ${#TEST_PROJECTS[@]} -eq 0 ]]; then
    info "No test projects found."
else
    info "Found ${#TEST_PROJECTS[@]} test projects. Running tests..."
    for test_proj in "${TEST_PROJECTS[@]}"; do
        info "Testing $(basename "$test_proj")..."
        if ! dotnet test "$test_proj" --configuration Release --logger "console;verbosity=normal"; then
            error "Tests failed for $(basename "$test_proj")!"
            exit 1
        fi
    done
    success "All tests passed."
fi

# 4. Publish to NuGet
step "KROK 4: Publish to NuGet"
PUBLISH_ARGS=()
if [[ "$DRY_RUN" == "true" ]]; then
    PUBLISH_ARGS+=("--dry-run")
fi

if ! "$PUBLISH_NUGET_SCRIPT" "${PUBLISH_ARGS[@]}"; then
    error "NuGet publish failed!"
    exit 1
fi

log_header "✅ SUCCESS! NuGet release completed."
if [[ "$DRY_RUN" == "false" ]]; then
    info "Verify your package at https://www.nuget.org/packages/"
fi
