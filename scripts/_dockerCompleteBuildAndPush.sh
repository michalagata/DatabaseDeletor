#!/usr/bin/env zsh
set -Eeuo pipefail
IFS=$'\n\t'

# Universal .NET Complete Docker Workflow
# Builds, tests, and pushes Docker image for any .NET application

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

echo "========================================"
echo "Universal .NET Complete Docker Workflow"
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

echo "Complete workflow for: $FULL_IMAGE_NAME"

# Step 1: Build the image
echo "Step 1: Building Docker image..."
./_performBuildDocker.sh "$IMAGE_NAME" "$TAG" "$REGISTRY"

if [ $? -ne 0 ]; then
    echo "ERROR: Build step failed"
    exit 1
fi

# Step 2: Test the image
echo "Step 2: Testing Docker image..."
./_dockerRun.sh "$FULL_IMAGE_NAME" "$(echo "$SOLUTION_NAME" | tr '[:upper:]' '[:lower:]')-test" "./test-data" "./test-output" "./test-logs"

if [ $? -ne 0 ]; then
    echo "ERROR: Test step failed"
    exit 1
fi

# Clean up test container
echo "Cleaning up test container..."
docker stop "$(echo "$SOLUTION_NAME" | tr '[:upper:]' '[:lower:]')-test" || true
docker rm "$(echo "$SOLUTION_NAME" | tr '[:upper:]' '[:lower:]')-test" || true

# Step 3: Push the image (if registry specified)
if [ -n "$REGISTRY" ]; then
    echo "Step 3: Pushing Docker image..."
    ./_dockerPush.sh "$IMAGE_NAME" "$TAG" "$REGISTRY"
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Push step failed"
        exit 1
    fi
else
    echo "Step 3: Skipping push (no registry specified)"
fi

echo "========================================"
echo "Complete Docker workflow finished successfully!"
echo "Image: $FULL_IMAGE_NAME"
echo "========================================"
