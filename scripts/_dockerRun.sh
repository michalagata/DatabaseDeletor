#!/usr/bin/env zsh
# Docker run script for DatabaseDeletor application

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
IMAGE_NAME="${IMAGE_NAME:-database-deletor}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-database-deletor-container}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$PROJECT_ROOT/workspace}"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/output}"
CONFIG_DIR="${CONFIG_DIR:-$PROJECT_ROOT/config}"

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
DatabaseDeletor Docker Run Script

Usage: $0 [OPTIONS] [DELETOR_ARGS...]

OPTIONS:
    -n, --name NAME           Container name [default: database-deletor-container]
    -i, --image IMAGE         Docker image [default: database-deletor:latest]
    -w, --workspace DIR       Workspace directory [default: ./workspace]
    -o, --output DIR          Output directory [default: ./output]
    -c, --config DIR          Config directory [default: ./config]
    -d, --detach              Run in background
    --rm                      Remove container after exit
    --interactive             Run in interactive mode
    -h, --help                Show this help message

DELETOR_ARGS:
    Any arguments passed after options will be forwarded to DatabaseDeletor CLI

EXAMPLES:
    $0 --help                                    # Show DatabaseDeletor help
    $0 --workspace /path/to/project --usedefaults # Version a project
    $0 -d --workspace /path/to/project            # Run in background
    $0 --interactive                              # Interactive mode

ENVIRONMENT VARIABLES:
    IMAGE_NAME      Docker image name (overrides -i)
    IMAGE_TAG       Docker image tag (overrides -i)
    CONTAINER_NAME  Container name (overrides -n)
    WORKSPACE_DIR   Workspace directory (overrides -w)
    OUTPUT_DIR      Output directory (overrides -o)
    CONFIG_DIR      Config directory (overrides -c)
EOF
}

# Parse command line arguments
parse_args() {
    DETACH=false
    REMOVE=false
    INTERACTIVE=false
    DELETOR_ARGS=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            -i|--image)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -w|--workspace)
                WORKSPACE_DIR="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_DIR="$2"
                shift 2
                ;;
            -d|--detach)
                DETACH=true
                shift
                ;;
            --rm)
                REMOVE=true
                shift
                ;;
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                DELETOR_ARGS+=("$1")
                shift
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
    
    # Check if image exists
    if ! docker image inspect "$IMAGE_NAME:$IMAGE_TAG" &> /dev/null; then
        log_error "Docker image $IMAGE_NAME:$IMAGE_TAG not found"
        log_info "Please build the image first using: $0 --build"
        exit 1
    fi
    
    # Create directories if they don't exist
    mkdir -p "$WORKSPACE_DIR" "$OUTPUT_DIR" "$CONFIG_DIR"
    
    log_success "Environment validation passed"
}

# Build image if requested
build_image() {
    if [[ "$1" == "--build" ]]; then
        log_info "Building Docker image..."
        "$SCRIPT_DIR/_performBuildDocker.sh" --name "$IMAGE_NAME" --tag "$IMAGE_TAG"
        if [[ $? -eq 0 ]]; then
            log_success "Image built successfully"
        else
            log_error "Failed to build image"
            exit 1
        fi
    fi
}

# Stop existing container
stop_existing_container() {
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log_info "Stopping existing container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME"
    fi
    
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        log_info "Removing existing container: $CONTAINER_NAME"
        docker rm "$CONTAINER_NAME"
    fi
}

# Run container
run_container() {
    log_info "Running DatabaseDeletor container..."
    log_info "Container: $CONTAINER_NAME"
    log_info "Image: $IMAGE_NAME:$IMAGE_TAG"
    log_info "Workspace: $WORKSPACE_DIR"
    log_info "Output: $OUTPUT_DIR"
    log_info "Config: $CONFIG_DIR"
    
    # Prepare docker run command
    local docker_cmd=(
        docker run
        --name "$CONTAINER_NAME"
        --platform linux/amd64
    )
    
    # Add volume mounts
    docker_cmd+=(
        -v "$WORKSPACE_DIR:/workspace:rw"
        -v "$OUTPUT_DIR:/output:rw"
        -v "$CONFIG_DIR:/app/config:ro"
    )
    
    # Add environment variables
    docker_cmd+=(
        -e "DOTNET_ENVIRONMENT=Production"
        -e "LOG_LEVEL=Information"
    )
    
    # Add working directory
    docker_cmd+=(
        -w /workspace
    )
    
    # Add detach flag if requested
    if [[ "$DETACH" == "true" ]]; then
        docker_cmd+=(-d)
    fi
    
    # Add remove flag if requested
    if [[ "$REMOVE" == "true" ]]; then
        docker_cmd+=(--rm)
    fi
    
    # Add interactive flag if requested
    if [[ "$INTERACTIVE" == "true" ]]; then
        docker_cmd+=(-it)
    fi
    
    # Add image name
    docker_cmd+=("$IMAGE_NAME:$IMAGE_TAG")
    
    # Add DatabaseDeletor arguments
    if [[ ${#DELETOR_ARGS[@]} -gt 0 ]]; then
        docker_cmd+=("${DELETOR_ARGS[@]}")
    else
        docker_cmd+=(--help)
    fi
    
    # Execute docker run
    log_info "Executing: ${docker_cmd[*]}"
    "${docker_cmd[@]}"
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Container executed successfully"
    else
        log_error "Container exited with code: $exit_code"
    fi
    
    return $exit_code
}

# Show container logs
show_logs() {
    if [[ "$DETACH" == "true" ]]; then
        log_info "Container logs:"
        docker logs "$CONTAINER_NAME"
    fi
}

# Show container status
show_status() {
    log_info "Container status:"
    docker ps -a -f name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Main run process
main() {
    log_info "Starting DatabaseDeletor Docker run process..."
    log_info "Project root: $PROJECT_ROOT"
    log_info "Script directory: $SCRIPT_DIR"
    
    # Parse arguments
    parse_args "$@"
    
    # Build image if requested
    if [[ "${1:-}" == "--build" ]]; then
        build_image "$1"
        shift
        DELETOR_ARGS=("$@")
    fi
    
    # Validate environment
    validate_environment
    
    # Stop existing container
    stop_existing_container
    
    # Run container
    run_container
    local exit_code=$?
    
    # Show logs if detached
    show_logs
    
    # Show status
    show_status
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "DatabaseDeletor Docker run process completed successfully!"
    else
        log_error "DatabaseDeletor Docker run process failed with exit code: $exit_code"
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"
