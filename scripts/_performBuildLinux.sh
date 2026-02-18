#!/usr/bin/env zsh
set -Eeuo pipefail
IFS=$'\n\t'

# Universal Linux Build Script
# Target: Linux x64 (.NET 8.0+)
# Architecture: linux/amd64 only
# Enhanced with configurable output and configuration, publish and packaging

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

echo "========================================"
echo "Universal Linux Build Script"
echo "========================================"

# STEP 0: Remove .bak files from repository (first step)
cleanup_bak_files

# Detect project information
if ! is_dotnet_project; then
    error "No .NET project found in project root"
    exit 1
fi

SOLUTION_NAME="$(get_solution_name)"
MAIN_PROJECT="$(find_main_project)"
LIBRARY_PROJECTS=($(find_library_projects))

if [[ -z "$MAIN_PROJECT" ]]; then
    error "No main executable project found"
    exit 1
fi

# Configuration (overridable via flags)
BUILD_CONFIG="${BUILD_CONFIG:-Release}"
# Convert relative paths to absolute
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ -z "${OUTPUT_DIR:-}" ]]; then
    OUTPUT_DIR="$PROJECT_ROOT/DEPLOYMENT"
elif [[ "${OUTPUT_DIR}" == ../* ]]; then
    OUTPUT_DIR="$(cd "$SCRIPT_DIR/.." && cd "${OUTPUT_DIR}" && pwd)"
elif [[ "${OUTPUT_DIR}" != /* ]]; then
    OUTPUT_DIR="$PROJECT_ROOT/${OUTPUT_DIR}"
fi
BUILD_DIR="$OUTPUT_DIR/net10.0"
OUTPUT_ZIP="$OUTPUT_DIR/${SOLUTION_NAME}.Linux.zip"
PLATFORM="linux"

# Parse args: -c/--config, -o/--output
while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--config)
      BUILD_CONFIG="$2"; shift 2 ;;
    -o|--output)
      OUTPUT_DIR="$2"; BUILD_DIR="$OUTPUT_DIR/net10.0"; OUTPUT_ZIP="$OUTPUT_DIR/${SOLUTION_NAME}.Linux.zip"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [-c Release|Debug] [-o OUTPUT_DIR]"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

echo "Starting Linux build process..."
echo "Solution: $SOLUTION_NAME"
echo "Main Project: $MAIN_PROJECT"
echo "Libraries: ${#LIBRARY_PROJECTS[@]}"
echo "Build directory: $BUILD_DIR"
echo "Output ZIP: $OUTPUT_ZIP"

# Clean old build
echo "Cleaning old build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Get platform-specific projects
MAIN_PROJECT_PLATFORM="$(get_platform_project "$MAIN_PROJECT" "$PLATFORM")"
RUNTIME_ID="$(get_runtime_id "$PLATFORM")"
TARGET_FRAMEWORK="$(get_target_framework "$MAIN_PROJECT_PLATFORM")"

echo "Using platform project: $MAIN_PROJECT_PLATFORM"
echo "Runtime: $RUNTIME_ID"
echo "Target Framework: $TARGET_FRAMEWORK"

# NOTE: Library projects are NOT built separately with runtime identifiers.
# This prevents Windows PE32+ DLLs from appearing in Linux/macOS packages.
# The 'dotnet publish' step below will automatically restore and build
# all dependencies with correct platform-agnostic IL for libraries.

# Run unit tests before publish (if test projects exist)
if ! run_unit_tests; then
    error "Unit tests failed - cannot proceed with publish"
    exit 1
fi

# Publish self-contained executable for main project
echo "Publishing self-contained executable..."
dotnet publish "$MAIN_PROJECT_PLATFORM" \
    --configuration "$BUILD_CONFIG" \
    --runtime "$RUNTIME_ID" \
    --output "$BUILD_DIR" \
    --self-contained true \
    --verbosity minimal
if [[ $? -ne 0 ]]; then
    error "Publish failed"
    exit 1
fi

# Copy additional files
echo "Copying additional files..."
if [[ -f "README.md" ]]; then
    cp -v README.md "$BUILD_DIR/"
fi

if [[ -f "LICENSE" ]]; then
    cp -v LICENSE "$BUILD_DIR/"
fi

if [[ -f "CHANGELOG.md" ]]; then
    cp -v CHANGELOG.md "$BUILD_DIR/"
fi

# Remove log files
echo "Removing log files..."
find "$BUILD_DIR" -name "*.log" -type f -delete

# Ensure output dir exists
mkdir -p "$OUTPUT_DIR"

# Create ZIP archive
echo "Creating ZIP archive..."
# Ensure OUTPUT_DIR exists
mkdir -p "$OUTPUT_DIR"
# Use absolute path for ZIP - create from BUILD_DIR
( cd "$BUILD_DIR" && zip -r "$OUTPUT_ZIP" ./* )

# Clean build directory
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"

echo "========================================"
echo "Linux build completed successfully!"
echo "Solution: $SOLUTION_NAME"
echo "Output: $OUTPUT_ZIP"
echo "========================================"
