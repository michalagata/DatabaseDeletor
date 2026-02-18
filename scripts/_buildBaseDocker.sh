#!/usr/bin/env zsh
set -Eeuo pipefail
IFS=$'\n\t'

# Build base Docker image for DatabaseDeletor API
# Base images are rebuilt only when dependencies change

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common functions
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-database-deletor-base}"
BASE_IMAGE_TAG="${BASE_IMAGE_TAG:-10.0}"
PLATFORM="${PLATFORM:-linux/amd64}"

log_header "Building Base Docker Image"

# Enable BuildKit
export DOCKER_BUILDKIT=1

info "Building base image: $BASE_IMAGE_NAME:$BASE_IMAGE_TAG"
info "Platform: $PLATFORM"

cd "$PROJECT_ROOT"

if docker build \
    --platform "$PLATFORM" \
    --tag "$BASE_IMAGE_NAME:$BASE_IMAGE_TAG" \
    --file infra/docker/base/api/Dockerfile.base \
    --progress=plain \
    .; then
    success "Base image built successfully: $BASE_IMAGE_NAME:$BASE_IMAGE_TAG"
else
    error "Failed to build base image"
fi

info "Base image size:"
docker images "$BASE_IMAGE_NAME:$BASE_IMAGE_TAG" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

