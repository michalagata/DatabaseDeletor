#!/usr/bin/env zsh
# =============================================================================
# Universal Common Functions for .NET Build Scripts
# =============================================================================
# This file provides shared utilities for all .NET build scripts.
# It automatically detects projects, solutions, and test projects.
# All functions are language-agnostic and work with any .NET solution structure.
#
# Usage: source _common.sh
#
# Environment Variables (Optional):
#   PROJECT_ROOT           - Override project root directory
#   SKIP_TESTS            - Set to "true" to skip test execution
#   DOTNET_VERSION_MIN    - Minimum required .NET version (default: 8)
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
DOTNET_VERSION_MIN="${DOTNET_VERSION_MIN:-8}"

# =============================================================================
# Logging Functions
# =============================================================================

error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
    exit 1
}

info() {
    echo -e "${BLUE}INFO:${NC} $*"
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $*"
}

warning() {
    echo -e "${YELLOW}WARNING:${NC} $*"
}

step() {
    echo -e "${CYAN}>>>${NC} $*"
}

log_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE} $1${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# =============================================================================
# Project Detection Functions
# =============================================================================

# Check if current directory is a .NET project
is_dotnet_project() {
    # Check for .sln file in root or any subdirectory (maxdepth 2)
    [[ -n "$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.sln" -type f 2>/dev/null | head -n 1)" ]] || \
    [[ -n "$(find "$PROJECT_ROOT" -maxdepth 3 -name "*.csproj" -type f 2>/dev/null | head -n 1)" ]]
}

# Find all .sln files in the project
find_solution_files() {
    find "$PROJECT_ROOT" -maxdepth 2 -name "*.sln" -type f 2>/dev/null | sort
}

# Get the primary solution file (first .sln found or create a name from project)
get_solution_file() {
    local sln_file
    sln_file="$(find_solution_files | head -n 1)"
    
    if [[ -n "$sln_file" && -f "$sln_file" ]]; then
        echo "$sln_file"
        return 0
    fi
    
    # No solution file found
    return 1
}

# Get solution name (without .sln extension)
get_solution_name() {
    local sln_file
    sln_file="$(get_solution_file 2>/dev/null || echo "")"
    
    local solution_name=""
    
    if [[ -n "$sln_file" && -f "$sln_file" ]]; then
        solution_name="$(basename "$sln_file" .sln)"
    else
        # Try to get name from main project
        local main_proj
        main_proj="$(find_main_project)"
        if [[ -n "$main_proj" && -f "$main_proj" ]]; then
            # Extract AssemblyName or use project filename
            local assembly_name
            assembly_name="$(grep -Eo '<AssemblyName>([^<]+)</AssemblyName>' "$main_proj" 2>/dev/null | sed 's/<AssemblyName>\(.*\)<\/AssemblyName>/\1/' | head -n1 || echo "")"
            if [[ -n "$assembly_name" ]]; then
                solution_name="$assembly_name"
            else
                solution_name="$(basename "$main_proj" .csproj)"
            fi
        else
            # Fallback to directory name
            solution_name="$(basename "$PROJECT_ROOT")"
        fi
    fi
    
    # Strip common project suffixes to get base solution name
    solution_name="${solution_name%.Cli}"
    solution_name="${solution_name%.Core}"
    solution_name="${solution_name%.App}"
    solution_name="${solution_name%.Console}"
    solution_name="${solution_name%.Application}"
    solution_name="${solution_name%.Api}"
    solution_name="${solution_name%.Web}"
    solution_name="${solution_name%.Service}"
    solution_name="${solution_name%.Services}"
    
    echo "$solution_name"
}

# Find all .csproj files (excluding test projects, obj, bin)
find_all_projects() {
    find "$PROJECT_ROOT" -maxdepth 4 -name "*.csproj" -type f 2>/dev/null | \
        grep -v -E "/(obj|bin)/" | sort
}

# Find all non-test projects
find_non_test_projects() {
    find_all_projects | while read -r proj; do
        # Skip test projects
        if [[ "$proj" =~ [Tt]est ]]; then
            continue
        fi
        
        # Check if it contains test SDK reference
        if grep -qE "Microsoft\.NET\.Test\.Sdk|xunit|nunit|mstest" "$proj" 2>/dev/null; then
            continue
        fi
        
        echo "$proj"
    done
}

# Find the main executable project (entry point)
find_main_project() {
    # Priority 1: Look for projects with OutputType=Exe (executable)
    local exe_project
    exe_project="$(find_non_test_projects | while read -r proj; do
        if grep -q "<OutputType>Exe</OutputType>" "$proj" 2>/dev/null; then
            echo "$proj"
            break
        fi
    done | head -n 1)"
    
    if [[ -n "$exe_project" && -f "$exe_project" ]]; then
        echo "$exe_project"
        return 0
    fi
    
    # Priority 2: Look for projects with PackAsTool=true (dotnet tool)
    local tool_project
    tool_project="$(find_non_test_projects | while read -r proj; do
        if grep -q "<PackAsTool>true</PackAsTool>" "$proj" 2>/dev/null; then
            echo "$proj"
            break
        fi
    done | head -n 1)"
    
    if [[ -n "$tool_project" && -f "$tool_project" ]]; then
        echo "$tool_project"
        return 0
    fi
    
    # Priority 3: Look for projects in common directories (Cli, App, Console, etc.)
    local common_dirs=("Cli" "App" "Console" "Application" "Main" "Host")
    for dir in "${common_dirs[@]}"; do
        local dir_project
        dir_project="$(find "$PROJECT_ROOT" -maxdepth 3 -path "*/$dir/*.csproj" -type f 2>/dev/null | \
            grep -v -E "/[Tt]est" | grep -v -E "/(obj|bin)/" | head -n 1)"
        if [[ -n "$dir_project" && -f "$dir_project" ]]; then
            echo "$dir_project"
            return 0
        fi
    done
    
    # Fallback: first non-test .csproj found
    find_non_test_projects | head -n 1
}

# Find library projects (not executable, not test)
find_library_projects() {
    find_non_test_projects | while read -r proj; do
        # Skip if it's an executable or tool
        if grep -q "<OutputType>Exe</OutputType>" "$proj" 2>/dev/null || \
           grep -q "<PackAsTool>true</PackAsTool>" "$proj" 2>/dev/null; then
            continue
        fi
        
        # It's a library
        echo "$proj"
    done
}

# Find all test projects
find_test_projects() {
    find_all_projects | while read -r proj; do
        local basename_proj
        basename_proj="$(basename "$proj" .csproj)"
        local dirname_proj
        dirname_proj="$(dirname "$proj")"
        
        # Check if it's a test project by name or directory
        if [[ "$basename_proj" =~ [Tt]est ]] || \
           [[ "$dirname_proj" =~ /[Tt]est ]] || \
           [[ "$dirname_proj" =~ /[Tt]esting ]]; then
            echo "$proj"
        # Also check for test SDK reference
        elif grep -qE "Microsoft\.NET\.Test\.Sdk|xunit|nunit|mstest" "$proj" 2>/dev/null; then
            echo "$proj"
        fi
    done
}

# Detect project type (Executable, Tool, Library, Test)
detect_project_type() {
    local project="$1"
    if [[ ! -f "$project" ]]; then
        echo "Unknown"
        return 1
    fi
    
    # Check for test project first
    if [[ "$project" =~ [Tt]est ]] || \
       grep -qE "Microsoft\.NET\.Test\.Sdk|xunit|nunit|mstest" "$project" 2>/dev/null; then
        echo "Test"
        return 0
    fi
    
    # Check for executable
    if grep -q "<OutputType>Exe</OutputType>" "$project" 2>/dev/null; then
        echo "Executable"
        return 0
    fi
    
    # Check for dotnet tool
    if grep -q "<PackAsTool>true</PackAsTool>" "$project" 2>/dev/null; then
        echo "Tool"
        return 0
    fi
    
    # Default to library
    echo "Library"
}

# =============================================================================
# Project Information Extraction
# =============================================================================

# Get project name from .csproj file
get_project_name() {
    local project="$1"
    if [[ -f "$project" ]]; then
        basename "$project" .csproj
    else
        echo "Unknown"
    fi
}

# Get target framework from project file
get_target_framework() {
    local project="$1"
    if [[ -f "$project" ]]; then
        # Try TargetFramework first (single)
        local fw
        fw="$(grep -Eo '<TargetFramework>([^<]+)</TargetFramework>' "$project" 2>/dev/null | \
              sed 's/<TargetFramework>\(.*\)<\/TargetFramework>/\1/' | head -n 1)"
        
        if [[ -n "$fw" ]]; then
            echo "$fw"
            return 0
        fi
        
        # Try TargetFrameworks (multiple, get first)
        fw="$(grep -Eo '<TargetFrameworks>([^<]+)</TargetFrameworks>' "$project" 2>/dev/null | \
              sed 's/<TargetFrameworks>\(.*\)<\/TargetFrameworks>/\1/' | cut -d';' -f1 | head -n 1)"
        
        if [[ -n "$fw" ]]; then
            echo "$fw"
            return 0
        fi
    fi
    
    # Default fallback
    echo "net10.0"
}

# Get assembly name from project file (or default to project name)
get_assembly_name() {
    local project="$1"
    if [[ -f "$project" ]]; then
        local assembly_name
        assembly_name="$(grep -Eo '<AssemblyName>([^<]+)</AssemblyName>' "$project" 2>/dev/null | \
                        sed 's/<AssemblyName>\(.*\)<\/AssemblyName>/\1/' | head -n 1)"
        
        if [[ -n "$assembly_name" ]]; then
            echo "$assembly_name"
        else
            get_project_name "$project"
        fi
    else
        echo "Unknown"
    fi
}

# Get runtime identifier for current platform or specified platform
get_runtime_id() {
    local platform="${1:-auto}"
    
    case "$platform" in
        linux|Linux)
            echo "linux-x64"
            ;;
        windows|Windows|win)
            echo "win-x64"
            ;;
        macos|MacOS|osx|darwin|Darwin)
            # Auto-detect macOS architecture
            local arch
            arch="$(uname -m 2>/dev/null || echo "x86_64")"
            if [[ "$arch" == "arm64" ]] || [[ "$arch" == "aarch64" ]]; then
                echo "osx-arm64"
            else
                echo "osx-x64"
            fi
            ;;
        auto|Auto|AUTO)
            # Auto-detect current platform
            local os
            os="$(uname -s 2>/dev/null || echo "Linux")"
            case "$os" in
                Linux)
                    echo "linux-x64"
                    ;;
                Darwin)
                    get_runtime_id "macos"
                    ;;
                MINGW*|MSYS*|CYGWIN*)
                    echo "win-x64"
                    ;;
                *)
                    echo "linux-x64"
                    ;;
            esac
            ;;
        *)
            # Return as-is if it's already a RID
            echo "$platform"
            ;;
    esac
}

# Get platform-specific project (pass-through unless platform-specific projects exist)
get_platform_project() {
    local project="$1"
    local platform="$2"

    # Return the project as-is; platform-specific projects would be handled here
    echo "$project"
}

# Detect current platform (linux, windows, macos)
detect_platform() {
    local os
    os="$(uname -s 2>/dev/null || echo "Linux")"
    case "$os" in
        Linux)   echo "linux" ;;
        Darwin)  echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)       echo "linux" ;;
    esac
}

# Find all .csproj files in the project (including test projects)
find_csproj_files() {
    find "$PROJECT_ROOT" -maxdepth 4 -name "*.csproj" -type f 2>/dev/null | \
        grep -v -E "/(obj|bin)/" | sort
}

# =============================================================================
# Build & Test Functions
# =============================================================================

# Run restore for solution or project
run_restore() {
    local target="${1:-}"
    
    if [[ -z "$target" ]]; then
        # Try to find solution file first
        target="$(get_solution_file 2>/dev/null || echo "")"
    fi
    
    if [[ -z "$target" || ! -f "$target" ]]; then
        # Restore all projects
        info "Restoring all projects in repository..."
        dotnet restore "$PROJECT_ROOT" --verbosity minimal
    else
        info "Restoring $(basename "$target")..."
        dotnet restore "$target" --verbosity minimal
    fi
}

# Build solution or project
run_build() {
    local target="${1:-}"
    local configuration="${2:-Release}"
    local extra_args="${3:-}"
    
    if [[ -z "$target" ]]; then
        # Try to find solution file first
        target="$(get_solution_file 2>/dev/null || echo "")"
    fi
    
    if [[ -z "$target" || ! -f "$target" ]]; then
        # Build all projects
        info "Building all projects in repository..."
        # shellcheck disable=SC2086
        dotnet build "$PROJECT_ROOT" \
            --configuration "$configuration" \
            --verbosity minimal \
            $extra_args
    else
        info "Building $(basename "$target")..."
        # shellcheck disable=SC2086
        dotnet build "$target" \
            --configuration "$configuration" \
            --verbosity minimal \
            $extra_args
    fi
}

# Run all tests in solution
run_tests() {
    # Check if tests should be skipped
    if [[ "${SKIP_TESTS:-false}" == "true" ]]; then
        warning "Skipping tests (SKIP_TESTS=true)"
        return 0
    fi
    
    local test_projects=()
    while IFS= read -r test_proj; do
        if [[ -n "$test_proj" && -f "$test_proj" ]]; then
            test_projects+=("$test_proj")
        fi
    done < <(find_test_projects)
    
    if (( ${#test_projects[@]} == 0 )); then
        info "No test projects found - skipping tests"
        return 0
    fi
    
    info "Found ${#test_projects[@]} test project(s)"
    for test_proj in "${test_projects[@]}"; do
        info "  - $(basename "$test_proj")"
    done
    
    step "Running tests..."
    
    local failed_tests=()
    for test_proj in "${test_projects[@]}"; do
        local test_name
        test_name="$(basename "$test_proj" .csproj)"
        info "Running tests: $test_name"
        
        if ! dotnet test "$test_proj" --configuration Release --verbosity minimal --no-build; then
            error "Tests failed in: $test_name"
            failed_tests+=("$test_name")
        else
            success "Tests passed: $test_name"
        fi
    done
    
    if (( ${#failed_tests[@]} > 0 )); then
        error "Tests failed in ${#failed_tests[@]} project(s): ${failed_tests[*]}"
        return 1
    fi
    
    success "All tests passed"
    return 0
}

# Run unit tests (builds before testing)
run_unit_tests() {
    # Check if tests should be skipped
    if [[ "${SKIP_TESTS:-false}" == "true" ]]; then
        warning "Skipping unit tests (SKIP_TESTS=true)"
        return 0
    fi

    local test_projects=()
    while IFS= read -r test_proj; do
        if [[ -n "$test_proj" && -f "$test_proj" ]]; then
            test_projects+=("$test_proj")
        fi
    done < <(find_test_projects)

    if (( ${#test_projects[@]} == 0 )); then
        info "No unit test projects found - skipping tests"
        return 0
    fi

    info "Found ${#test_projects[@]} test project(s)"
    for test_proj in "${test_projects[@]}"; do
        info "  - $(basename "$test_proj")"
    done

    step "Building and running unit tests..."

    local failed_tests=()
    for test_proj in "${test_projects[@]}"; do
        local test_name
        test_name="$(basename "$test_proj" .csproj)"
        info "Running tests in: $test_name"

        if ! dotnet test "$test_proj" --configuration Release --verbosity minimal; then
            failed_tests+=("$test_name")
        else
            success "Tests passed: $test_name"
        fi
    done

    if (( ${#failed_tests[@]} > 0 )); then
        error "Unit tests failed in ${#failed_tests[@]} project(s): ${failed_tests[*]}"
        return 1
    fi

    success "All unit tests passed"
    return 0
}

# Publish project
run_publish() {
    local project="$1"
    local output_dir="$2"
    local configuration="${3:-Release}"
    local runtime_id="${4:-}"
    local self_contained="${5:-true}"
    local extra_args="${6:-}"
    
    info "Publishing $(basename "$project")..."
    
    local publish_args="--configuration $configuration --output $output_dir --verbosity minimal"
    
    if [[ -n "$runtime_id" ]]; then
        publish_args="$publish_args --runtime $runtime_id"
    fi
    
    if [[ "$self_contained" == "true" ]]; then
        publish_args="$publish_args --self-contained true"
    else
        publish_args="$publish_args --self-contained false"
    fi
    
    # shellcheck disable=SC2086
    dotnet publish "$project" $publish_args $extra_args
}

# =============================================================================
# Validation Functions
# =============================================================================

# Check if .NET SDK is installed and meets minimum version requirement
check_dotnet() {
    if ! command -v dotnet &> /dev/null; then
        error ".NET SDK is not installed. Please install .NET ${DOTNET_VERSION_MIN}.0 SDK or later."
    fi
    
    local dotnet_version
    dotnet_version=$(dotnet --version)
    info "Using .NET SDK version: $dotnet_version"
    
    # Check if version meets minimum requirement
    local major_version
    major_version=$(echo "$dotnet_version" | cut -d. -f1)
    if [[ "$major_version" -lt "$DOTNET_VERSION_MIN" ]]; then
        error ".NET SDK ${DOTNET_VERSION_MIN}.0 or later is required. Current version: $dotnet_version"
    fi
}

# Check if Git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        warning "Git is not installed. Some features may not work."
        return 1
    fi
    return 0
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        warning "Docker is not installed. Docker features will not work."
        return 1
    fi
    return 0
}

# =============================================================================
# Utility Functions
# =============================================================================

# Clean up .bak files from repository
cleanup_bak_files() {
    info "Cleaning up .bak files..."
    
    local bak_files=()
    while IFS= read -r -d '' file; do
        bak_files+=("$file")
    done < <(find "$PROJECT_ROOT" -type f -name "*.bak" -print0 2>/dev/null || true)
    
    if (( ${#bak_files[@]} == 0 )); then
        info "No .bak files found"
        return 0
    fi
    
    info "Found ${#bak_files[@]} .bak file(s) to remove"
    for file in "${bak_files[@]}"; do
        if rm -f "$file" 2>/dev/null; then
            info "  Removed: $(basename "$file")"
        else
            warning "  Failed to remove: $(basename "$file")"
        fi
    done
    
    success "Cleanup completed"
}

# Clean build artifacts (bin, obj, DEPLOYMENT directories)
cleanup_build_artifacts() {
    info "Cleaning build artifacts..."
    
    local cleaned_dirs=0
    
    # Clean obj directories
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir" 2>/dev/null && ((cleaned_dirs++)) || true
        fi
    done < <(find "$PROJECT_ROOT" -type d -name "obj" 2>/dev/null | grep -v "/node_modules/")
    
    # Clean bin directories
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir" 2>/dev/null && ((cleaned_dirs++)) || true
        fi
    done < <(find "$PROJECT_ROOT" -type d -name "bin" 2>/dev/null | grep -v "/node_modules/")
    
    # Clean DEPLOYMENT directory
    if [[ -d "$PROJECT_ROOT/DEPLOYMENT" ]]; then
        rm -rf "$PROJECT_ROOT/DEPLOYMENT" 2>/dev/null && ((cleaned_dirs++)) || true
    fi
    
    success "Removed $cleaned_dirs build artifact director(y|ies)"
}

# Display project summary
show_project_summary() {
    log_header "Project Summary"
    
    info "Project Root: $PROJECT_ROOT"
    
    # Solution info
    local sln_file
    sln_file="$(get_solution_file 2>/dev/null || echo "")"
    if [[ -n "$sln_file" ]]; then
        info "Solution: $(basename "$sln_file")"
    else
        info "Solution: <no .sln file found>"
    fi
    
    # Main project
    local main_proj
    main_proj="$(find_main_project)"
    if [[ -n "$main_proj" ]]; then
        info "Main Project: $(basename "$main_proj") [$(detect_project_type "$main_proj")]"
    fi
    
    # Count projects by type
    local all_projects
    all_projects=$(find_all_projects | wc -l | tr -d ' ')
    local test_projects
    test_projects=$(find_test_projects | wc -l | tr -d ' ')
    local lib_projects
    lib_projects=$(find_library_projects | wc -l | tr -d ' ')
    
    info "Projects: $all_projects total ($lib_projects libraries, $test_projects tests)"
    
    echo ""
}

# Export all functions for use in other scripts
export -f error info success warning step log_header timestamp
export -f is_dotnet_project find_solution_files get_solution_file get_solution_name
export -f find_all_projects find_non_test_projects find_main_project find_library_projects find_test_projects
export -f detect_project_type get_project_name get_target_framework get_assembly_name get_runtime_id
export -f detect_platform find_csproj_files
export -f get_platform_project run_restore run_build run_tests run_unit_tests run_publish
export -f check_dotnet check_git check_docker
export -f cleanup_bak_files cleanup_build_artifacts show_project_summary

