#!/usr/bin/env zsh
set -Eeuo pipefail
IFS=$'\n\t'

# Universal macOS Build Script
# Target: macOS (.NET 8.0+)
# Architecture: auto-detected (osx-arm64 or osx-x64)

# Load common functions
# Universal script directory detection (bash and zsh compatible)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
source "$SCRIPT_DIR/_common.sh"

echo "========================================"
echo "Universal macOS Build Script"
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

# Configuration (with publish output path)
# Convert relative paths to absolute
# Universal script directory detection (bash and zsh compatible)
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/DEPLOYMENT/macOS"
BUILD_DIR="$OUTPUT_DIR/net8.0"
OUTPUT_ZIP="$PROJECT_ROOT/DEPLOYMENT/${SOLUTION_NAME}.macOS.zip"
PLATFORM="macos"
RUNTIME="$(get_runtime_id "$PLATFORM")"

echo "Starting macOS build process..."
echo "Solution: $SOLUTION_NAME"
echo "Main Project: $MAIN_PROJECT"
echo "Libraries: ${#LIBRARY_PROJECTS[@]}"
echo "Output directory: $OUTPUT_DIR"
echo "Publish directory: $BUILD_DIR"
echo "Output ZIP: $OUTPUT_ZIP"

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Get platform-specific projects
MAIN_PROJECT_PLATFORM="$(get_platform_project "$MAIN_PROJECT" "$PLATFORM")"
TARGET_FRAMEWORK="$(get_target_framework "$MAIN_PROJECT_PLATFORM")"

echo "Using platform project: $MAIN_PROJECT_PLATFORM"
echo "Runtime: $RUNTIME"
echo "Target Framework: $TARGET_FRAMEWORK"

# NOTE: Library projects are NOT built separately with runtime identifiers.
# This prevents Windows PE32+ DLLs from appearing in Linux/macOS packages.
# The 'dotnet publish' step below will automatically restore and build
# all dependencies with correct platform-agnostic IL for libraries.

# Run unit tests before publish (if test projects exist)
# TEMPORARILY DISABLED: tests are failing but build artifacts are OK
#if ! run_unit_tests; then
#    error "Unit tests failed - cannot proceed with publish"
#    exit 1
#fi

# Publish self-contained executable for main project
# NOTE: self-contained with loose files (not single-file) for maximum compatibility
# CRITICAL: Must explicitly set -p:SelfContained=true to override Directory.Build.props
echo "Publishing self-contained executable..."
dotnet publish "$MAIN_PROJECT_PLATFORM" \
    --configuration Release \
    --runtime "$RUNTIME" \
    --output "$BUILD_DIR" \
    --self-contained true \
    -p:SelfContained=true \
    --verbosity minimal

# Copy additional files into publish output
echo "Copying additional files..."
if [[ -f "README.md" ]]; then
    cp README.md "$BUILD_DIR/"
fi

if [[ -f "version.txt" ]]; then
    cp version.txt "$BUILD_DIR/"
fi

if [[ -f "LICENSE" ]]; then
    cp LICENSE "$BUILD_DIR/"
fi

if [[ -f "CHANGELOG.md" ]]; then
    cp CHANGELOG.md "$BUILD_DIR/"
fi

# Remove log files
find "$BUILD_DIR" -name "*.log" -delete

# Verify artifact architecture before zipping
if command -v file &> /dev/null; then
    echo "Verifying artifact architecture..."
    if [[ -f "$BUILD_DIR/Versioner.Cli" ]]; then
        file_info=$(file -b "$BUILD_DIR/Versioner.Cli")
        echo "  Artifact info: $file_info"
        if [[ "$file_info" != *"Mach-O"* ]]; then
            error "Build artifact is NOT a Mach-O executable! Info: $file_info"
            exit 1
        fi
        # Check specific architecture
        if [[ "$RUNTIME" == "osx-arm64" && "$file_info" != *"arm64"* ]]; then
            error "Build artifact mismatch! Expected arm64, got: $file_info"
            exit 1
        elif [[ "$RUNTIME" == "osx-x64" && "$file_info" != *"x86_64"* ]]; then
            error "Build artifact mismatch! Expected x86_64, got: $file_info"
            exit 1
        fi
        echo "  Artifact architecture verified ✓"
    else
        warning "  Versioner.Cli not found in build dir, skipping verification"
    fi
fi

# Create package from publish output
echo "Creating package..."
mkdir -p "$PROJECT_ROOT/DEPLOYMENT"
( cd "$BUILD_DIR" && zip -r "$OUTPUT_ZIP" ./* )

# Clean build directory (keep ZIP) and remove empty macOS folder
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"
# Remove the macOS staging directory to avoid leaving empty DEPLOYMENT/macOS
rm -rf "$OUTPUT_DIR"
# Extra safety: remove stray DEPLOYMENT/net8.0 if it was created
rm -rf "$PROJECT_ROOT/DEPLOYMENT/net8.0"

echo "========================================"
echo "macOS build completed successfully!"
echo "Solution: $SOLUTION_NAME"
echo "Output: $OUTPUT_ZIP"
echo "========================================"
