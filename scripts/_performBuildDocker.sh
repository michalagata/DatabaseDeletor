#!/usr/bin/env zsh
# Docker build script for Versioner application
# Builds solution for Linux first, then builds Docker container

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
IMAGE_NAME="${IMAGE_NAME:-versioner}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY="${REGISTRY:-}"
PLATFORM="${PLATFORM:-linux/amd64}"
PUSH="${PUSH:-false}"

# Docker build configuration
DOCKER_LABELS=()
DOCKER_BUILD_ARGS=()
AUTO_TAG_VERSION="${AUTO_TAG_VERSION:-true}"

# Load common functions for project detection and cleanup
if [[ -f "$SCRIPT_DIR/_common.sh" ]]; then
    source "$SCRIPT_DIR/_common.sh"
fi

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
Versioner Docker Build Script (universal). Use _performBuildDocker.sh name after rename.

Usage: $0 [OPTIONS]

OPTIONS:
    -n, --name NAME           Image name [default: versioner]
    -t, --tag TAG             Image tag [default: latest]
    -r, --registry REGISTRY   Docker registry URL
    -p, --platform PLATFORM  Target platform [default: linux/amd64]
    --push                    Push image to registry after build
    --label KEY=VALUE         Add Docker label (can be used multiple times)
    --build-arg KEY=VALUE     Add Docker build argument (can be used multiple times)
    --no-auto-tag             Disable automatic version tagging from version.txt
    -h, --help                Show this help message

EXAMPLES:
    $0                                    # Build versioner:latest
    $0 -n my-versioner -t v1.0.0         # Build my-versioner:v1.0.0
    $0 -r registry.example.com --push    # Build and push to registry

ENVIRONMENT VARIABLES:
    IMAGE_NAME      Image name (overrides -n)
    IMAGE_TAG       Image tag (overrides -t)
    REGISTRY        Docker registry URL (overrides -r)
    PLATFORM        Target platform (overrides -p)
    PUSH            Push flag (overrides --push)
    AUTO_TAG_VERSION Auto-tag with version from version.txt (overrides --no-auto-tag)
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -t|--tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            -r|--registry)
                REGISTRY="$2"
                shift 2
                ;;
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            --push)
                PUSH="true"
                shift
                ;;
            --label)
                DOCKER_LABELS+=("$2")
                shift 2
                ;;
            --build-arg)
                DOCKER_BUILD_ARGS+=("$2")
                shift 2
                ;;
            --no-auto-tag)
                AUTO_TAG_VERSION="false"
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
    
    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/docker/Dockerfile" ]]; then
        log_error "Dockerfile not found. Please run this script from the project root or scripts directory."
        exit 1
    fi
    
    # Validate platform
    if [[ "$PLATFORM" != "linux/amd64" && "$PLATFORM" != "linux/arm64" ]]; then
        log_warning "Platform $PLATFORM may not be supported. Recommended: linux/amd64"
    fi
    
    log_success "Environment validation passed"
}

# Build solution for Linux first using universal performer
build_solution() {
    log_info "Building solution for Linux first..."
    
    # Check if we have a .NET project
    if ! command -v dotnet &> /dev/null; then
        log_error ".NET SDK is not installed or not in PATH"
        exit 1
    fi
    
    # Prefer universal performer script if present
    if [[ -x "$SCRIPT_DIR/_performBuildLinux.sh" ]]; then
        if ! "$SCRIPT_DIR/_performBuildLinux.sh" -c Release -o "$PROJECT_ROOT/DEPLOYMENT"; then
            log_error "Failed to build solution for Linux"
            exit 1
        fi
    elif [[ -x "$SCRIPT_DIR/build-linux.sh" ]]; then
        if ! "$SCRIPT_DIR/build-linux.sh"; then
            log_error "Failed to build solution for Linux"
            exit 1
        fi
    else
        log_warning "No Linux build script found, skipping Linux build step"
        log_info "Docker build will proceed without pre-building for Linux"
        
        # If no build script, we still need to run tests if they exist
        if [[ -f "$SCRIPT_DIR/_common.sh" ]]; then
            source "$SCRIPT_DIR/_common.sh"
            if ! run_unit_tests; then
                log_error "Unit tests failed - cannot proceed with Docker build"
                exit 1
            fi
        fi
        return 0
    fi
    
    log_success "Solution built successfully for Linux"
}

# Build Docker image
build_docker_image() {
    log_info "Building Docker image..."
    log_info "Image: $IMAGE_NAME:$IMAGE_TAG"
    log_info "Platform: $PLATFORM"
    log_info "Registry: ${REGISTRY:-none}"
    
    # Prepare Docker build command
    local docker_cmd=(
        docker build
        --platform "$PLATFORM"
        --tag "$IMAGE_NAME:$IMAGE_TAG"
        --file "$PROJECT_ROOT/docker/Dockerfile"
    )
    
    # Add labels if specified
    for label in "${DOCKER_LABELS[@]}"; do
        docker_cmd+=(--label "$label")
    done
    
    # Add build args if specified
    for build_arg in "${DOCKER_BUILD_ARGS[@]}"; do
        docker_cmd+=(--build-arg "$build_arg")
    done
    
    # Add context
    docker_cmd+=("$PROJECT_ROOT")
    
    # Execute build command
    log_info "Executing: ${docker_cmd[*]}"
    "${docker_cmd[@]}"
    
    if [[ $? -eq 0 ]]; then
        log_success "Docker image built successfully"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

# Auto-tag with version from version.txt
auto_tag_version() {
    if [[ "$AUTO_TAG_VERSION" == "true" ]]; then
        local version_file="$PROJECT_ROOT/version.txt"
        if [[ -f "$version_file" ]]; then
            local version=$(cat "$version_file" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ -n "$version" && "$version" != "$IMAGE_TAG" ]]; then
                log_info "Auto-tagging with version from version.txt: $version"
                docker tag "$IMAGE_NAME:$IMAGE_TAG" "$IMAGE_NAME:$version"
                
                if [[ $? -eq 0 ]]; then
                    log_success "Image auto-tagged with version: $version"
                else
                    log_warning "Failed to auto-tag with version: $version"
                fi
            fi
        else
            log_info "No version.txt found, skipping auto-tagging"
        fi
    fi
}

# Tag image for registry
tag_for_registry() {
    if [[ -n "$REGISTRY" ]]; then
        local full_image_name="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
        log_info "Tagging image for registry: $full_image_name"
        
        docker tag "$IMAGE_NAME:$IMAGE_TAG" "$full_image_name"
        
        if [[ $? -eq 0 ]]; then
            log_success "Image tagged for registry"
        else
            log_error "Failed to tag image for registry"
            exit 1
        fi
        
        # Also tag version if auto-tagging is enabled
        if [[ "$AUTO_TAG_VERSION" == "true" ]]; then
            local version_file="$PROJECT_ROOT/version.txt"
            if [[ -f "$version_file" ]]; then
                local version=$(cat "$version_file" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                if [[ -n "$version" && "$version" != "$IMAGE_TAG" ]]; then
                    local full_version_name="$REGISTRY/$IMAGE_NAME:$version"
                    log_info "Tagging version for registry: $full_version_name"
                    docker tag "$IMAGE_NAME:$version" "$full_version_name"
                fi
            fi
        fi
    fi
}

# Push image to registry
push_image() {
    if [[ "$PUSH" == "true" ]]; then
        if [[ -n "$REGISTRY" ]]; then
            local full_image_name="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
            log_info "Pushing image to registry: $full_image_name"
            
            docker push "$full_image_name"
            
            if [[ $? -eq 0 ]]; then
                log_success "Image pushed to registry successfully"
            else
                log_error "Failed to push image to registry"
                exit 1
            fi
            
            # Also push version tag if auto-tagging is enabled
            if [[ "$AUTO_TAG_VERSION" == "true" ]]; then
                local version_file="$PROJECT_ROOT/version.txt"
                if [[ -f "$version_file" ]]; then
                    local version=$(cat "$version_file" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    if [[ -n "$version" && "$version" != "$IMAGE_TAG" ]]; then
                        local full_version_name="$REGISTRY/$IMAGE_NAME:$version"
                        log_info "Pushing version to registry: $full_version_name"
                        docker push "$full_version_name"
                        
                        if [[ $? -eq 0 ]]; then
                            log_success "Version image pushed to registry successfully"
                        else
                            log_warning "Failed to push version image to registry"
                        fi
                    fi
                fi
            fi
        else
            log_warning "Push requested but no registry specified"
        fi
    fi
}

# Show image information
show_image_info() {
    log_info "Image information:"
    echo "  Name: $IMAGE_NAME"
    echo "  Tag: $IMAGE_TAG"
    echo "  Platform: $PLATFORM"
    if [[ -n "$REGISTRY" ]]; then
        echo "  Registry: $REGISTRY"
        echo "  Full name: $REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
    fi
    
    # Show image size
    local image_size
    image_size=$(docker images --format "table {{.Size}}" "$IMAGE_NAME:$IMAGE_TAG" | tail -n 1)
    echo "  Size: $image_size"
}

# Clean up old images (optional)
cleanup_old_images() {
    log_info "Cleaning up old images..."
    
    # Remove dangling images
    docker image prune -f
    
    # Remove old versions of the same image (keep last 3)
    docker images "$IMAGE_NAME" --format "table {{.Tag}}\t{{.CreatedAt}}" | \
        grep -v "$IMAGE_TAG" | \
        tail -n +4 | \
        awk '{print $1}' | \
        xargs -r -I {} docker rmi "$IMAGE_NAME:{}" 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# Main build process
main() {
    log_header "🚀 VERSIONER DOCKER BUILD SCRIPT 🚀"
    echo -e "${WHITE}Project Root: ${CYAN}$PROJECT_ROOT${NC}"
    echo -e "${WHITE}Script Directory: ${CYAN}$SCRIPT_DIR${NC}"
    echo -e "${WHITE}Image: ${CYAN}$IMAGE_NAME:$IMAGE_TAG${NC}"
    echo -e "${WHITE}Platform: ${CYAN}$PLATFORM${NC}"
    echo -e "${WHITE}Timestamp: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    
    # Parse arguments
    parse_args "$@"
    
    # STEP 0: Remove .bak files from repository (first step)
    if [[ -f "$SCRIPT_DIR/_common.sh" ]]; then
        source "$SCRIPT_DIR/_common.sh"
        cleanup_bak_files
    else
        log_info "Cleaning up .bak files from repository..."
        find "$PROJECT_ROOT" -type f -name "*.bak" -delete 2>/dev/null || true
        log_success "Cleanup of .bak files completed"
    fi
    
    # Validate environment
    validate_environment
    
    # Build solution for Linux first
    build_solution
    
    # Build Docker image
    build_docker_image
    
    # Auto-tag with version from version.txt
    auto_tag_version
    
    # Tag for registry
    tag_for_registry
    
    # Push image
    push_image
    
    # Show image info
    show_image_info
    
    # Cleanup old images
    cleanup_old_images
    
    log_success "Docker build process completed successfully!"
    echo -e "${WHITE}Image: ${CYAN}$IMAGE_NAME:$IMAGE_TAG${NC}"
    if [[ -n "$REGISTRY" ]]; then
        echo -e "${WHITE}Registry: ${CYAN}$REGISTRY/$IMAGE_NAME:$IMAGE_TAG${NC}"
    fi
}

# Run main function with all arguments
main "$@"
