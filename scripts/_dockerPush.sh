#!/usr/bin/env zsh
set -Eeuo pipefail
IFS=$'\n\t'

# Universal .NET Docker Push Script
# Pushes Docker image to registry for any .NET application

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

echo "========================================"
echo "Universal .NET Docker Push Script"
echo "========================================"

# Detect project information
if ! is_dotnet_project; then
    error "No .NET project found in project root"
    exit 1
fi

SOLUTION_NAME="$(get_solution_name)"
echo "Solution: $SOLUTION_NAME"

# Configuration
IMAGE_NAME="${1:-$(echo "$SOLUTION_NAME" | tr '[:upper:]' '[:lower:]')}"
TAG="${2:-latest}"
REGISTRY="${3:-}"
FULL_IMAGE_NAME="${REGISTRY:+$REGISTRY/}${IMAGE_NAME}:${TAG}"

echo "Pushing Docker image..."
echo "Image: $FULL_IMAGE_NAME"

# Check if image exists locally
if ! docker images "$IMAGE_NAME" --format "{{.Repository}}" | grep -q "^${IMAGE_NAME}$"; then
    echo "ERROR: Image $IMAGE_NAME not found locally"
    echo "Please build the image first using _performBuildDocker.sh"
    exit 1
fi

# Tag the image if registry is specified
if [ -n "$REGISTRY" ]; then
    echo "Tagging image for registry..."
    docker tag "${IMAGE_NAME}:${TAG}" "$FULL_IMAGE_NAME"
fi

# Push the image
echo "Pushing to registry..."
docker push "$FULL_IMAGE_NAME"

if [ $? -ne 0 ]; then
    echo "ERROR: Docker push failed"
    exit 1
fi

echo "========================================"
echo "Docker push completed successfully!"
echo "Image: $FULL_IMAGE_NAME"
echo "========================================"

# Show pushed image information
echo "Pushed image details:"
docker images "$FULL_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
