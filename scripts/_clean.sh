#!/usr/bin/env zsh
# =============================================================================
# Universal .NET Cleanup Script
# =============================================================================
# Automatically detects and cleans build artifacts, temporary files, and
# Docker resources for any .NET project.
#
# Features:
# - Cleans obj/ and bin/ directories
# - Removes .bak files
# - Cleans DEPLOYMENT directory
# - Optional Docker cleanup
# - Optional deep clean (NuGet cache, .vs, etc.)
#
# Usage: ./clean.sh [OPTIONS]
#
# Options:
#   --deep            Deep clean including NuGet cache and IDE folders
#   --docker          Clean Docker images and containers
#   --all             Clean everything (deep + docker)
#   -y, --yes         Skip confirmation prompts
#   -h, --help        Show this help message
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Configuration
DEEP_CLEAN=false
DOCKER_CLEAN=false
AUTO_YES=false

# Statistics
CLEANED_FILES=0
CLEANED_DIRS=0
CLEANED_DOCKER=0

# =============================================================================
# Help and Options
# =============================================================================

show_help() {
    cat << EOF
Universal .NET Cleanup Script

Usage: $0 [OPTIONS]

OPTIONS:
    --deep              Deep clean including NuGet cache and IDE folders
    --docker            Clean Docker images and containers for this project
    --all               Clean everything (equivalent to --deep --docker)
    -y, --yes           Skip confirmation prompts
    -h, --help          Show this help message

WHAT GETS CLEANED:

Standard Clean (default):
  • obj/ directories (build intermediates)
  • bin/ directories (build outputs)
  • .bak files (backup files)
  • DEPLOYMENT/ directory (published artifacts)

Deep Clean (--deep):
  • Everything in standard clean, plus:
  • .vs/ directories (Visual Studio cache)
  • .vscode/ directories (VS Code cache)
  • .idea/ directories (JetBrains IDE cache)
  • .DS_Store files (macOS metadata)
  • *.user files (user-specific settings)
  • TestResults/ directories
  • Global NuGet cache (~/.nuget/packages)

Docker Clean (--docker):
  • Docker containers related to project
  • Docker images related to project
  • Dangling Docker images

EXAMPLES:
    $0                      # Standard cleanup
    $0 --deep               # Deep cleanup
    $0 --docker -y          # Docker cleanup without prompts
    $0 --all                # Clean everything

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --deep)
                DEEP_CLEAN=true
                shift
                ;;
            --docker)
                DOCKER_CLEAN=true
                shift
                ;;
            --all)
                DEEP_CLEAN=true
                DOCKER_CLEAN=true
                shift
                ;;
            -y|--yes)
                AUTO_YES=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# =============================================================================
# Confirmation
# =============================================================================

confirm_cleanup() {
    if [[ "$AUTO_YES" == "true" ]]; then
        return 0
    fi
    
    echo ""
    warning "This will delete build artifacts and temporary files."
    if [[ "$DEEP_CLEAN" == "true" ]]; then
        warning "DEEP CLEAN: Will also remove IDE caches and NuGet cache!"
    fi
    if [[ "$DOCKER_CLEAN" == "true" ]]; then
        warning "DOCKER CLEAN: Will remove Docker containers and images!"
    fi
    echo ""
    
    read -r -p "$(echo -e "${YELLOW}Continue? [y/N]${NC} ")" response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            info "Cleanup cancelled"
            exit 0
            ;;
    esac
}

# =============================================================================
# Cleanup Functions
# =============================================================================

# Clean .bak files
clean_bak_files() {
    step "Cleaning .bak files..."
    
    local count=0
    while IFS= read -r -d '' file; do
        if rm -f "$file" 2>/dev/null; then
            ((count++))
        fi
    done < <(find "$PROJECT_ROOT" -type f -name "*.bak" -print0 2>/dev/null || true)
    
    if [[ $count -gt 0 ]]; then
        CLEANED_FILES=$((CLEANED_FILES + count))
        success "Removed $count .bak file(s)"
    else
        info "No .bak files found"
    fi
}

# Clean obj directories
clean_obj_directories() {
    step "Cleaning obj/ directories..."
    
    local count=0
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            if rm -rf "$dir" 2>/dev/null; then
                ((count++))
            fi
        fi
    done < <(find "$PROJECT_ROOT" -type d -name "obj" 2>/dev/null | grep -v "/node_modules/")
    
    if [[ $count -gt 0 ]]; then
        CLEANED_DIRS=$((CLEANED_DIRS + count))
        success "Removed $count obj/ director(y|ies)"
    else
        info "No obj/ directories found"
    fi
}

# Clean bin directories
clean_bin_directories() {
    step "Cleaning bin/ directories..."
    
    local count=0
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            if rm -rf "$dir" 2>/dev/null; then
                ((count++))
            fi
        fi
    done < <(find "$PROJECT_ROOT" -type d -name "bin" 2>/dev/null | grep -v "/node_modules/")
    
    if [[ $count -gt 0 ]]; then
        CLEANED_DIRS=$((CLEANED_DIRS + count))
        success "Removed $count bin/ director(y|ies)"
    else
        info "No bin/ directories found"
    fi
}

# Clean DEPLOYMENT directory
clean_deployment_directory() {
    step "Cleaning DEPLOYMENT/ directory..."
    
    if [[ -d "$PROJECT_ROOT/DEPLOYMENT" ]]; then
        if rm -rf "$PROJECT_ROOT/DEPLOYMENT" 2>/dev/null; then
            CLEANED_DIRS=$((CLEANED_DIRS + 1))
            success "Removed DEPLOYMENT/ directory"
        else
            warning "Failed to remove DEPLOYMENT/ directory"
        fi
    else
        info "No DEPLOYMENT/ directory found"
    fi
}

# Clean TestResults directories
clean_test_results() {
    step "Cleaning TestResults/ directories..."
    
    local count=0
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            if rm -rf "$dir" 2>/dev/null; then
                ((count++))
            fi
        fi
    done < <(find "$PROJECT_ROOT" -type d -name "TestResults" 2>/dev/null)
    
    if [[ $count -gt 0 ]]; then
        CLEANED_DIRS=$((CLEANED_DIRS + count))
        success "Removed $count TestResults/ director(y|ies)"
    else
        info "No TestResults/ directories found"
    fi
}

# Deep clean - IDE folders
clean_ide_folders() {
    if [[ "$DEEP_CLEAN" != "true" ]]; then
        return 0
    fi
    
    step "Deep cleaning IDE folders..."
    
    local cleaned=0
    
    # Clean .vs directories (Visual Studio)
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            if rm -rf "$dir" 2>/dev/null; then
                ((cleaned++))
                info "  Removed: $(basename "$(dirname "$dir")")/.vs"
            fi
        fi
    done < <(find "$PROJECT_ROOT" -type d -name ".vs" 2>/dev/null)
    
    # Clean .vscode directories (except root-level - might contain settings)
    while IFS= read -r dir; do
        # Skip root-level .vscode
        if [[ "$dir" != "$PROJECT_ROOT/.vscode" ]]; then
            if [[ -d "$dir" ]]; then
                if rm -rf "$dir" 2>/dev/null; then
                    ((cleaned++))
                    info "  Removed: $(basename "$(dirname "$dir")")/.vscode"
                fi
            fi
        fi
    done < <(find "$PROJECT_ROOT" -type d -name ".vscode" 2>/dev/null)
    
    # Clean .idea directories (JetBrains IDEs)
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            if rm -rf "$dir" 2>/dev/null; then
                ((cleaned++))
                info "  Removed: $(basename "$(dirname "$dir")")/.idea"
            fi
        fi
    done < <(find "$PROJECT_ROOT" -type d -name ".idea" 2>/dev/null)
    
    if [[ $cleaned -gt 0 ]]; then
        CLEANED_DIRS=$((CLEANED_DIRS + cleaned))
        success "Removed $cleaned IDE cache director(y|ies)"
    else
        info "No IDE cache directories found"
    fi
}

# Deep clean - macOS files
clean_macos_files() {
    if [[ "$DEEP_CLEAN" != "true" ]]; then
        return 0
    fi
    
    step "Deep cleaning macOS metadata files..."
    
    local count=0
    
    # Clean .DS_Store files
    while IFS= read -r -d '' file; do
        if rm -f "$file" 2>/dev/null; then
            ((count++))
        fi
    done < <(find "$PROJECT_ROOT" -type f -name ".DS_Store" -print0 2>/dev/null || true)
    
    if [[ $count -gt 0 ]]; then
        CLEANED_FILES=$((CLEANED_FILES + count))
        success "Removed $count .DS_Store file(s)"
    else
        info "No .DS_Store files found"
    fi
}

# Deep clean - user files
clean_user_files() {
    if [[ "$DEEP_CLEAN" != "true" ]]; then
        return 0
    fi
    
    step "Deep cleaning user-specific files..."
    
    local count=0
    
    # Clean *.user files
    while IFS= read -r -d '' file; do
        if rm -f "$file" 2>/dev/null; then
            ((count++))
        fi
    done < <(find "$PROJECT_ROOT" -type f -name "*.user" -print0 2>/dev/null || true)
    
    if [[ $count -gt 0 ]]; then
        CLEANED_FILES=$((CLEANED_FILES + count))
        success "Removed $count *.user file(s)"
    else
        info "No *.user files found"
    fi
}

# Deep clean - NuGet cache
clean_nuget_cache() {
    if [[ "$DEEP_CLEAN" != "true" ]]; then
        return 0
    fi
    
    step "Deep cleaning NuGet cache..."
    
    if command -v dotnet &> /dev/null; then
        info "Clearing global NuGet cache..."
        if dotnet nuget locals all --clear &> /dev/null; then
            success "NuGet cache cleared"
        else
            warning "Failed to clear NuGet cache"
        fi
    else
        warning ".NET SDK not found - skipping NuGet cache cleanup"
    fi
}

# Docker cleanup
clean_docker_resources() {
    if [[ "$DOCKER_CLEAN" != "true" ]]; then
        return 0
    fi
    
    if ! check_docker; then
        warning "Docker not installed - skipping Docker cleanup"
        return 0
    fi
    
    step "Cleaning Docker resources..."
    
    local solution_name
    solution_name="$(get_solution_name | tr '[:upper:]' '[:lower:]')"
    
    # Stop and remove containers
    info "Stopping and removing containers related to: $solution_name"
    local containers
    containers=$(docker ps -a --filter "name=$solution_name" --format "{{.Names}}" 2>/dev/null || echo "")
    
    if [[ -n "$containers" ]]; then
        while IFS= read -r container; do
            if [[ -n "$container" ]]; then
                info "  Stopping container: $container"
                docker stop "$container" &> /dev/null || true
                info "  Removing container: $container"
                docker rm "$container" &> /dev/null || true
                ((CLEANED_DOCKER++))
            fi
        done <<< "$containers"
        success "Removed Docker containers"
    else
        info "No Docker containers found for: $solution_name"
    fi
    
    # Remove images
    info "Removing images related to: $solution_name"
    local images
    images=$(docker images --filter "reference=*$solution_name*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || echo "")
    
    if [[ -n "$images" ]]; then
        while IFS= read -r image; do
            if [[ -n "$image" ]] && [[ "$image" != ":<none>" ]]; then
                info "  Removing image: $image"
                docker rmi "$image" &> /dev/null || true
                ((CLEANED_DOCKER++))
            fi
        done <<< "$images"
        success "Removed Docker images"
    else
        info "No Docker images found for: $solution_name"
    fi
    
    # Remove dangling images
    info "Removing dangling Docker images..."
    local dangling
    dangling=$(docker images -f "dangling=true" -q 2>/dev/null || echo "")
    
    if [[ -n "$dangling" ]]; then
        docker rmi $(echo "$dangling") &> /dev/null || true
        success "Removed dangling images"
    else
        info "No dangling images found"
    fi
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    log_header "🧹 UNIVERSAL .NET CLEANUP SCRIPT 🧹"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Show configuration
    info "Project Root: $PROJECT_ROOT"
    info "Deep Clean: $([ "$DEEP_CLEAN" == "true" ] && echo "YES" || echo "NO")"
    info "Docker Clean: $([ "$DOCKER_CLEAN" == "true" ] && echo "YES" || echo "NO")"
    echo ""
    
    # Confirm cleanup
    confirm_cleanup
    
    log_header "Starting Cleanup"
    
    # Standard cleanup
    clean_bak_files
    clean_obj_directories
    clean_bin_directories
    clean_deployment_directory
    clean_test_results
    
    # Deep cleanup
    if [[ "$DEEP_CLEAN" == "true" ]]; then
        log_header "Deep Cleanup"
        clean_ide_folders
        clean_macos_files
        clean_user_files
        clean_nuget_cache
    fi
    
    # Docker cleanup
    if [[ "$DOCKER_CLEAN" == "true" ]]; then
        log_header "Docker Cleanup"
        clean_docker_resources
    fi
    
    # Summary
    log_header "✅ CLEANUP COMPLETED"
    success "Removed $CLEANED_FILES file(s)"
    success "Removed $CLEANED_DIRS director(y|ies)"
    if [[ "$DOCKER_CLEAN" == "true" ]]; then
        success "Cleaned $CLEANED_DOCKER Docker resource(s)"
    fi
    echo ""
    info "Project is now clean and ready for a fresh build"
}

# Run main function
main "$@"
