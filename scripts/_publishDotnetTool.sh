#!/usr/bin/env zsh
set -Eeuo pipefail
IFS=$'\n\t'

# Publish Dotnet Tool Script
# This script compiles, publishes, packages, and releases Versioner as a dotnet tool
# Works on Windows (Git Bash/WSL), Linux, and macOS

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NUPKG_OUTPUT_DIR="$PROJECT_ROOT/DEPLOYMENT/nupkg"

# Load common functions for project detection
source "$SCRIPT_DIR/_common.sh"

# Auto-detect tool project (project with PackAsTool=true or executable project)
CLI_PROJECT=""
if ! is_dotnet_project; then
    error "No .NET project found in project root"
fi

# Try to find tool project
CLI_PROJECT="$(find "$PROJECT_ROOT" -maxdepth 4 -name "*.csproj" -type f 2>/dev/null | while read -r proj; do
    # Skip test projects and obj/bin directories
    if [[ "$proj" =~ /(Test|Tests|test|tests|obj|bin)/ ]]; then
        continue
    fi
    # Check if it's a tool project
    if grep -q "<PackAsTool>true</PackAsTool>" "$proj" 2>/dev/null; then
        echo "$proj"
        break
    fi
done | head -n 1)"

# If no tool project found, try to find executable project
if [[ -z "$CLI_PROJECT" || ! -f "$CLI_PROJECT" ]]; then
    CLI_PROJECT="$(find_main_project)"
fi

if [[ -z "$CLI_PROJECT" || ! -f "$CLI_PROJECT" ]]; then
    error "No suitable project found for dotnet tool packaging. Please ensure you have a project with PackAsTool=true or an executable project."
fi

# Default NuGet feed (public nuget.org)
DEFAULT_FEED="https://api.nuget.org/v3/index.json"
DEFAULT_FEED_NAME="nuget.org"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Error handling
error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
    exit 1
}

info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

step() {
    echo -e "${CYAN}>>>${NC} $1"
}

# Check if .NET SDK is installed
check_dotnet() {
    if ! command -v dotnet &> /dev/null; then
        error ".NET SDK is not installed. Please install .NET 8.0 SDK or later."
    fi
    
    local dotnet_version=$(dotnet --version)
    info "Using .NET SDK version: $dotnet_version"
    
    # Check if version is 8.0 or later
    local major_version=$(echo "$dotnet_version" | cut -d. -f1)
    if [ "$major_version" -lt 8 ]; then
        error ".NET SDK 8.0 or later is required. Current version: $dotnet_version"
    fi
}

# Parse command line arguments
BUILD_CONFIG="Release"
FEED_URL=""
FEED_NAME=""
API_KEY=""
SKIP_PUBLISH=false
CLEAN_BUILD=false
SKIP_RESTORE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            BUILD_CONFIG="$2"
            shift 2
            ;;
        -f|--feed)
            FEED_URL="$2"
            shift 2
            ;;
        -k|--api-key)
            API_KEY="$2"
            shift 2
            ;;
        --skip-publish)
            SKIP_PUBLISH=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --skip-restore)
            SKIP_RESTORE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "This script performs the complete dotnet tool release process:"
            echo "  1. Compiles the application"
            echo "  2. Publishes the application"
            echo "  3. Packages as dotnet tool (.nupkg)"
            echo "  4. Publishes to NuGet feed"
            echo ""
            echo "Options:"
            echo "  -c, --config CONFIG     Build configuration (Debug|Release) [default: Release]"
            echo "  -f, --feed URL          NuGet feed URL [default: $DEFAULT_FEED]"
            echo "  -k, --api-key KEY      API key for NuGet feed authentication"
            echo "  --skip-publish          Skip publishing to feed (only build and pack)"
            echo "  --clean                 Clean build directories before building"
            echo "  --skip-restore          Skip dotnet restore"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  NUGET_API_KEY           API key for NuGet feed (alternative to --api-key)"
            echo ""
            echo "Examples:"
            echo "  # Build and publish to nuget.org (requires NUGET_API_KEY env var)"
            echo "  $0"
            echo ""
            echo "  # Build and publish to custom feed"
            echo "  $0 --feed https://api.example.com/v3/index.json --api-key YOUR_KEY"
            echo ""
            echo "  # Build and pack only (skip publishing)"
            echo "  $0 --skip-publish"
            echo ""
            echo "  # Build Debug configuration"
            echo "  $0 -c Debug --skip-publish"
            exit 0
            ;;
        *)
            error "Unknown option: $1. Use -h or --help for usage information."
            ;;
    esac
done

echo "========================================"
echo "Publish Dotnet Tool Script"
echo "========================================"
echo "Project Root: $PROJECT_ROOT"
echo "CLI Project: $CLI_PROJECT"
echo "Build Configuration: $BUILD_CONFIG"
echo "Output Directory: $NUPKG_OUTPUT_DIR"
if [ -n "$FEED_URL" ]; then
    echo "Feed URL: $FEED_URL"
else
    echo "Feed URL: $DEFAULT_FEED (default)"
fi
echo "Skip Publish: $SKIP_PUBLISH"
echo "========================================"

# Check prerequisites
check_dotnet

# Verify project file exists
if [ ! -f "$CLI_PROJECT" ]; then
    error "CLI project file not found: $CLI_PROJECT"
fi

# Set default feed if not specified
if [ -z "$FEED_URL" ]; then
    FEED_URL="$DEFAULT_FEED"
    FEED_NAME="$DEFAULT_FEED_NAME"
else
    # Extract feed name from URL for display
    FEED_NAME=$(echo "$FEED_URL" | sed -E 's|https?://([^/]+).*|\1|' | sed 's|api\.||' | sed 's|\.org||' | sed 's|\.com||')
fi

# Get API key from environment variable if not provided
if [ -z "$API_KEY" ] && [ -n "${NUGET_API_KEY:-}" ]; then
    API_KEY="$NUGET_API_KEY"
    info "Using API key from NUGET_API_KEY environment variable"
fi

# Clean build directories if requested
if [ "$CLEAN_BUILD" = true ]; then
    step "Cleaning build directories..."
    rm -rf "$NUPKG_OUTPUT_DIR"
    dotnet clean "$CLI_PROJECT" -c "$BUILD_CONFIG" || warning "Clean failed, continuing..."
fi

# Create output directory
mkdir -p "$NUPKG_OUTPUT_DIR"

# Step 1: Restore dependencies
if [ "$SKIP_RESTORE" = false ]; then
    step "Step 1/4: Restoring dependencies..."
    dotnet restore "$CLI_PROJECT" || error "Restore failed"
    success "Dependencies restored"
else
    info "Skipping restore (--skip-restore)"
fi

# Step 2: Build the project
step "Step 2/4: Building project..."
dotnet build "$CLI_PROJECT" \
    -c "$BUILD_CONFIG" \
    --no-restore \
    || error "Build failed"
success "Project built successfully"

# Step 3: Pack as dotnet tool
step "Step 3/4: Packing as dotnet tool..."
dotnet pack "$CLI_PROJECT" \
    -c "$BUILD_CONFIG" \
    --no-build \
    --output "$NUPKG_OUTPUT_DIR" \
    || error "Pack failed"

# Find the generated .nupkg file
NUPKG_FILE=$(find "$NUPKG_OUTPUT_DIR" -name "*.nupkg" -type f | head -n 1)

if [ -z "$NUPKG_FILE" ]; then
    error "NuGet package file not found in $NUPKG_OUTPUT_DIR"
fi

success "Dotnet tool package created successfully!"
info "Package location: $NUPKG_FILE"
info "Package size: $(du -h "$NUPKG_FILE" | cut -f1)"

# Step 4: Publish to NuGet feed
if [ "$SKIP_PUBLISH" = false ]; then
    step "Step 4/4: Publishing to NuGet feed..."
    info "Feed: $FEED_URL"
    
    # Check if API key is required
    if [ -z "$API_KEY" ]; then
        warning "No API key provided. Attempting to publish without authentication..."
        warning "If authentication is required, use --api-key or set NUGET_API_KEY environment variable"
    fi
    
    # Build push command
    PUSH_CMD="dotnet nuget push \"$NUPKG_FILE\" --source \"$FEED_URL\""
    
    if [ -n "$API_KEY" ]; then
        PUSH_CMD="$PUSH_CMD --api-key \"$API_KEY\""
    fi
    
    # Add skip-duplicate flag for nuget.org
    if [ "$FEED_URL" = "$DEFAULT_FEED" ]; then
        PUSH_CMD="$PUSH_CMD --skip-duplicate"
    fi
    
    info "Executing: dotnet nuget push ..."
    
    # Execute push command
    if eval "$PUSH_CMD"; then
        success "Package published successfully to $FEED_NAME!"
    else
        error "Failed to publish package to $FEED_URL"
    fi
else
    info "Skipping publish step (--skip-publish)"
    echo ""
    echo "To publish manually, run:"
    if [ -n "$API_KEY" ]; then
        echo "  dotnet nuget push \"$NUPKG_FILE\" --source \"$FEED_URL\" --api-key \"$API_KEY\""
    else
        echo "  dotnet nuget push \"$NUPKG_FILE\" --source \"$FEED_URL\" --api-key YOUR_API_KEY"
    fi
fi

echo ""
echo "========================================"
echo "Process completed successfully!"
echo "========================================"
if [ "$SKIP_PUBLISH" = false ]; then
    echo "Package published to: $FEED_NAME"
    echo "Feed URL: $FEED_URL"
fi
echo "Package location: $NUPKG_FILE"
echo ""
echo "To install the tool locally, run:"
echo "  dotnet tool install --global --add-source $NUPKG_OUTPUT_DIR Versioner.Cli"
echo ""
echo "Or after publishing to nuget.org:"
echo "  dotnet tool install --global Versioner.Cli"
echo "========================================"

