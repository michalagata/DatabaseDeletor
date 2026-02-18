#!/usr/bin/env zsh
# =============================================================================
# _buildDotnetSolution.sh
# =============================================================================
#
# Universal .NET solution build script
# Automatically detects projects in the repository, builds, tests, and publishes
#
# Features:
# - Auto-detects .sln files or .csproj files
# - Restores dependencies
# - Builds all projects
# - Runs unit, integration, and e2e tests (if present)
# - Publishes artifacts to DEPLOYMENT directory
# - Works within repository boundaries only
#
# Usage:
#   ./_buildDotnetSolution.sh [OPTIONS]
#
# Options:
#   -c, --configuration CONFIG    Build configuration (Debug|Release) [default: Release]
#   -o, --output DIR             Output directory [default: PROJECT_ROOT/DEPLOYMENT]
#   -r, --runtime RID            Runtime identifier (e.g., win-x64, linux-x64, osx-x64)
#   --no-restore                 Skip restore step
#   --no-build                   Skip build step (only restore)
#   --no-test                    Skip test execution
#   --no-publish                 Skip publish step
#   --self-contained             Publish as self-contained deployment
#   --verbosity LEVEL            MSBuild verbosity (quiet|minimal|normal|detailed|diagnostic)
#   -h, --help                   Show this help message
#
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Default configuration
BUILD_CONFIG="${BUILD_CONFIG:-Release}"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/DEPLOYMENT}"
RUNTIME_ID="${RUNTIME_ID:-}"
SKIP_RESTORE="${SKIP_RESTORE:-false}"
SKIP_BUILD="${SKIP_BUILD:-false}"
SKIP_TEST="${SKIP_TEST:-false}"
SKIP_PUBLISH="${SKIP_PUBLISH:-false}"
SELF_CONTAINED="${SELF_CONTAINED:-false}"
VERBOSITY="${VERBOSITY:-minimal}"

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--configuration)
                BUILD_CONFIG="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -r|--runtime)
                RUNTIME_ID="$2"
                shift 2
                ;;
            --no-restore)
                SKIP_RESTORE="true"
                shift
                ;;
            --no-build)
                SKIP_BUILD="true"
                shift
                ;;
            --no-test)
                SKIP_TEST="true"
                shift
                ;;
            --no-publish)
                SKIP_PUBLISH="true"
                shift
                ;;
            --self-contained)
                SELF_CONTAINED="true"
                shift
                ;;
            --verbosity)
                VERBOSITY="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    cat << EOF
Universal .NET Solution Build Script

Usage: $0 [OPTIONS]

Options:
    -c, --configuration CONFIG    Build configuration (Debug|Release) [default: Release]
    -o, --output DIR             Output directory [default: PROJECT_ROOT/DEPLOYMENT]
    -r, --runtime RID            Runtime identifier (e.g., win-x64, linux-x64, osx-x64)
    --no-restore                 Skip restore step
    --no-build                   Skip build step (only restore)
    --no-test                    Skip test execution
    --no-publish                 Skip publish step
    --self-contained             Publish as self-contained deployment
    --verbosity LEVEL            MSBuild verbosity (quiet|minimal|normal|detailed|diagnostic)
    -h, --help                   Show this help message

Examples:
    $0                                    # Build with defaults
    $0 -c Debug                          # Build in Debug configuration
    $0 -o ./output --no-test            # Build without running tests
    $0 -r win-x64 --self-contained       # Build self-contained for Windows

Environment Variables:
    BUILD_CONFIG      Build configuration (overrides -c)
    OUTPUT_DIR        Output directory (overrides -o)
    RUNTIME_ID        Runtime identifier (overrides -r)
    SKIP_RESTORE      Skip restore (overrides --no-restore)
    SKIP_BUILD        Skip build (overrides --no-build)
    SKIP_TEST         Skip tests (overrides --no-test)
    SKIP_PUBLISH      Skip publish (overrides --no-publish)
    SELF_CONTAINED    Self-contained deployment (overrides --self-contained)
    VERBOSITY         MSBuild verbosity (overrides --verbosity)

EOF
}

# Validate environment
validate_environment() {
    step "Validating environment..."
    
    # Check .NET SDK
    check_dotnet
    
    # Check if we're in a .NET project
    if ! is_dotnet_project; then
        error "No .NET project found in project root: $PROJECT_ROOT"
    fi
    
    # Normalize OUTPUT_DIR to absolute path
    if [[ "${OUTPUT_DIR}" == ../* ]]; then
        OUTPUT_DIR="$(cd "$SCRIPT_DIR/.." && cd "${OUTPUT_DIR}" && pwd)"
    elif [[ "${OUTPUT_DIR}" != /* ]]; then
        OUTPUT_DIR="$PROJECT_ROOT/${OUTPUT_DIR}"
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    success "Environment validation passed"
}

# Find solution file or projects
find_solution_or_projects() {
    # Try to find .sln file first
    local sln_file
    sln_file="$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.sln" -type f 2>/dev/null | head -n 1)"
    
    if [[ -n "$sln_file" && -f "$sln_file" ]]; then
        echo "$sln_file"
        return 0
    fi
    
    # If no .sln, return empty (will use individual projects)
    return 1
}

# Restore dependencies
restore_dependencies() {
    if [[ "$SKIP_RESTORE" == "true" ]]; then
        info "Skipping restore (--no-restore specified)"
        return 0
    fi
    
    step "Restoring dependencies..."
    
    local sln_file
    if sln_file="$(find_solution_or_projects)"; then
        # Restore solution
        info "Restoring solution: $(basename "$sln_file")"
        if ! dotnet restore "$sln_file" --verbosity "$VERBOSITY"; then
            error "Failed to restore solution"
        fi
    else
        # Restore individual projects
        local projects=()
        while IFS= read -r proj; do
            [[ -n "$proj" && -f "$proj" ]] && projects+=("$proj")
        done < <(find_csproj_files | grep -v -E "/(obj|bin)/" | head -20)
        
        if (( ${#projects[@]} == 0 )); then
            error "No .csproj files found in repository"
        fi
        
        info "Found ${#projects[@]} project(s) to restore"
        for proj in "${projects[@]}"; do
            info "  Restoring: $(basename "$proj")"
            if ! dotnet restore "$proj" --verbosity "$VERBOSITY"; then
                error "Failed to restore project: $proj"
            fi
        done
    fi
    
    success "Dependencies restored successfully"
}

# Build solution
build_solution() {
    if [[ "$SKIP_BUILD" == "true" ]]; then
        info "Skipping build (--no-build specified)"
        return 0
    fi
    
    step "Building solution..."
    
    local sln_file
    if sln_file="$(find_solution_or_projects)"; then
        # Build solution
        info "Building solution: $(basename "$sln_file")"
        
        local build_cmd=(
            dotnet build
            "$sln_file"
            --configuration "$BUILD_CONFIG"
            --verbosity "$VERBOSITY"
        )
        
        if [[ -n "$RUNTIME_ID" ]]; then
            build_cmd+=(--runtime "$RUNTIME_ID")
        fi
        
        if [[ "$SELF_CONTAINED" == "true" ]]; then
            build_cmd+=(--self-contained true)
        fi
        
        if ! "${build_cmd[@]}"; then
            error "Failed to build solution"
        fi
    else
        # Build individual projects (libraries first, then main project)
        local library_projects=($(find_library_projects))
        local main_project
        main_project="$(find_main_project)"
        
        # Build libraries
        if (( ${#library_projects[@]} > 0 )); then
            info "Building ${#library_projects[@]} library project(s)..."
            for lib_proj in "${library_projects[@]}"; do
                local lib_name
                lib_name="$(get_project_name "$lib_proj")"
                info "  Building library: $lib_name"
                
                local build_cmd=(
                    dotnet build
                    "$lib_proj"
                    --configuration "$BUILD_CONFIG"
                    --verbosity "$VERBOSITY"
                )
                
                if [[ -n "$RUNTIME_ID" ]]; then
                    build_cmd+=(--runtime "$RUNTIME_ID")
                fi
                
                if [[ "$SELF_CONTAINED" == "true" ]]; then
                    build_cmd+=(--self-contained true)
                fi
                
                if ! "${build_cmd[@]}"; then
                    error "Failed to build library: $lib_name"
                fi
            done
        fi
        
        # Build main project
        if [[ -n "$main_project" && -f "$main_project" ]]; then
            local main_name
            main_name="$(get_project_name "$main_project")"
            info "Building main project: $main_name"
            
            local build_cmd=(
                dotnet build
                "$main_project"
                --configuration "$BUILD_CONFIG"
                --verbosity "$VERBOSITY"
            )
            
            if [[ -n "$RUNTIME_ID" ]]; then
                build_cmd+=(--runtime "$RUNTIME_ID")
            fi
            
            if [[ "$SELF_CONTAINED" == "true" ]]; then
                build_cmd+=(--self-contained true)
            fi
            
            if ! "${build_cmd[@]}"; then
                error "Failed to build main project: $main_name"
            fi
        else
            warning "No main executable project found"
        fi
    fi
    
    success "Solution built successfully"
}

# Run tests
run_tests() {
    if [[ "$SKIP_TEST" == "true" ]]; then
        info "Skipping tests (--no-test specified)"
        return 0
    fi
    
    step "Running tests..."
    
    # Use common function to run unit tests
    if ! run_unit_tests; then
        error "Tests failed - cannot proceed"
    fi
    
    success "All tests passed"
}

# Publish artifacts
publish_artifacts() {
    if [[ "$SKIP_PUBLISH" == "true" ]]; then
        info "Skipping publish (--no-publish specified)"
        return 0
    fi
    
    step "Publishing artifacts..."
    
    local main_project
    main_project="$(find_main_project)"
    
    if [[ -z "$main_project" || ! -f "$main_project" ]]; then
        warning "No main executable project found - skipping publish"
        return 0
    fi
    
    local main_name
    main_name="$(get_project_name "$main_project")"
    local publish_dir="$OUTPUT_DIR/$main_name"
    
    info "Publishing main project: $main_name"
    info "Output directory: $publish_dir"
    
    # Clean previous publish
    if [[ -d "$publish_dir" ]]; then
        info "Cleaning previous publish directory..."
        rm -rf "$publish_dir"
    fi
    mkdir -p "$publish_dir"
    
    # Build publish command
    local publish_cmd=(
        dotnet publish
        "$main_project"
        --configuration "$BUILD_CONFIG"
        --output "$publish_dir"
        --verbosity "$VERBOSITY"
    )
    
    if [[ -n "$RUNTIME_ID" ]]; then
        publish_cmd+=(--runtime "$RUNTIME_ID")
    fi
    
    if [[ "$SELF_CONTAINED" == "true" ]]; then
        publish_cmd+=(--self-contained true)
    fi
    
    if ! "${publish_cmd[@]}"; then
        error "Failed to publish project: $main_name"
    fi
    
    # Copy additional files
    info "Copying additional files..."
    for file in README.md LICENSE CHANGELOG.md; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            cp -v "$PROJECT_ROOT/$file" "$publish_dir/"
        fi
    done
    
    # Remove log files
    find "$publish_dir" -type f -name "*.log" -delete 2>/dev/null || true
    
    success "Artifacts published successfully to: $publish_dir"
}

# Main function
main() {
    log_header "🔨 .NET SOLUTION BUILD SCRIPT 🔨"
    echo -e "${WHITE}Project Root: ${CYAN}$PROJECT_ROOT${NC}"
    echo -e "${WHITE}Output Directory: ${CYAN}$OUTPUT_DIR${NC}"
    echo -e "${WHITE}Configuration: ${CYAN}$BUILD_CONFIG${NC}"
    [[ -n "$RUNTIME_ID" ]] && echo -e "${WHITE}Runtime: ${CYAN}$RUNTIME_ID${NC}"
    echo -e "${WHITE}Timestamp: ${CYAN}$(timestamp)${NC}"
    echo ""
    
    # Parse arguments
    parse_arguments "$@"
    
    # Validate environment
    validate_environment
    
    # Step 1: Restore dependencies
    restore_dependencies
    
    # Step 2: Build solution
    build_solution
    
    # Step 3: Run tests
    run_tests
    
    # Step 4: Publish artifacts
    publish_artifacts
    
    # Summary
    log_header "✅ BUILD COMPLETED SUCCESSFULLY!"
    success "Solution built and published to: $OUTPUT_DIR"
    echo ""
    echo -e "${WHITE}Completed steps:${NC}"
    echo -e "${GREEN}  ✓${NC} Dependencies restored"
    echo -e "${GREEN}  ✓${NC} Solution built"
    echo -e "${GREEN}  ✓${NC} Tests executed"
    echo -e "${GREEN}  ✓${NC} Artifacts published"
    echo ""
}

# Run main function
main "$@"

