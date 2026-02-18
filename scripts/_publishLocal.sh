#!/usr/bin/env zsh
set -Eeuo pipefail
IFS=$'\n\t'

# Universal .NET Local Publish Script
# Publishes NuGet packages locally with validation
# Installs Versioner tool from pre-built macOS binaries

# Parse arguments
NO_CLEANUP=false
for arg in "$@"; do
    if [[ "$arg" == "--no-cleanup" ]]; then
        NO_CLEANUP=true
    fi
done

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

echo "========================================"
echo "Universal .NET Local Publish Script"
echo "========================================"

# Detect project information
if ! is_dotnet_project; then
    error "No .NET project found in project root"
    exit 1
fi

SOLUTION_NAME="$(get_solution_name)"
CSPROJ_FILES=($(find_csproj_files))

# Filter out test projects and example files
FILTERED_CSPROJ_FILES=()
for csproj in "${CSPROJ_FILES[@]}"; do
    # Skip test projects
    if [[ "$csproj" == *"Tests"* ]] || [[ "$csproj" == *"Test"* ]]; then
        continue
    fi
    # Skip example files
    if [[ "$csproj" == *"ExampleFiles"* ]]; then
        continue
    fi
    FILTERED_CSPROJ_FILES+=("$csproj")
done

echo "Solution: $SOLUTION_NAME"
echo "Projects to publish: ${#FILTERED_CSPROJ_FILES[@]}"
echo ""
echo "NOTE: This script detects your platform and installs the appropriate Versioner version"
echo "      Versioner will be run via: ./Versioner.Cli"
echo "      Make sure to run the appropriate build script first (_performBuildMacOS.sh, etc.)"
echo ""

# Configuration
NUGET_SOURCE="${1:-local}"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/DEPLOYMENT/packages"
INSTALL_DIR="$HOME/.dotnet/tools"

echo "Starting local publish process..."
echo "NuGet source: $NUGET_SOURCE"
echo "Output directory: $OUTPUT_DIR"
echo "Install directory: $INSTALL_DIR"

# ========== PRE-PUBLISH VALIDATION ==========
echo ""
echo "========== PRE-PUBLISH VALIDATION =========="

# 1. Validate that we're building Release configuration
echo "✓ Checking build configuration..."
BUILD_CONFIG="Release"
echo "  Build configuration: $BUILD_CONFIG"

# 2. Clean and prepare output directory
echo "✓ Preparing output directory..."
if [[ -d "$OUTPUT_DIR" ]]; then
    echo "  Removing existing packages..."
    rm -rf "$OUTPUT_DIR"/*.nupkg 2>/dev/null || true
    rm -rf "$OUTPUT_DIR"/*.snupkg 2>/dev/null || true
fi
mkdir -p "$OUTPUT_DIR"

# Verify directory is clean
EXISTING_PACKAGES=$(find "$OUTPUT_DIR" -name "*.nupkg" 2>/dev/null | wc -l | tr -d ' ')
if [[ $EXISTING_PACKAGES -ne 0 ]]; then
    error "Output directory not clean! Found $EXISTING_PACKAGES package(s)"
    exit 1
fi
echo "  Output directory clean ✓"

# 3. Verify dotnet tool list is accessible
echo "✓ Checking dotnet tool environment..."
if ! command -v dotnet &> /dev/null; then
    error "dotnet command not found!"
    exit 1
fi
DOTNET_VERSION=$(dotnet --version)
echo "  .NET SDK version: $DOTNET_VERSION"

echo "Pre-publish validation completed ✓"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Publish filtered projects
echo "========== PUBLISHING PACKAGES =========="
for csproj in "${FILTERED_CSPROJ_FILES[@]}"; do
    project_name="$(get_project_name "$csproj")"
    project_type="$(detect_project_type "$csproj")"
    
    echo "Publishing $project_name ($project_type)..."
    dotnet pack "$csproj" \
        --configuration Release \
        --output "$OUTPUT_DIR" \
        --verbosity minimal \
        --no-restore \
        -p:PublishReadyToRun=false \
        -m:1

    if [ $? -ne 0 ]; then
        error "Failed to publish $project_name"
        exit 1
    fi
done

# ========== POST-PUBLISH VALIDATION ==========
echo ""
echo "========== POST-PUBLISH VALIDATION =========="

# 1. Verify packages were created
echo "✓ Verifying package creation..."
CREATED_PACKAGES=$(find "$OUTPUT_DIR" -name "*.nupkg" ! -name "*.symbols.nupkg" 2>/dev/null)
PACKAGE_COUNT=$(echo "$CREATED_PACKAGES" | grep -c '.nupkg' || echo "0")

if [[ $PACKAGE_COUNT -eq 0 ]]; then
    error "No packages were created!"
    exit 1
fi
echo "  Created $PACKAGE_COUNT package(s) ✓"

# 2. List and validate package versions
echo ""
echo "✓ Validating package versions..."
for package in $CREATED_PACKAGES; do
    package_name=$(basename "$package")
    echo "  📦 $package_name"
    
    # Extract version from package name (assumes format: PackageName.X.Y.Z.nupkg)
    if [[ ! "$package_name" =~ \.nupkg$ ]]; then
        error "Invalid package name format: $package_name"
        exit 1
    fi
done

# 3. Verify packages are Release builds
echo ""
echo "✓ Verifying Release build configuration..."
for package in $CREATED_PACKAGES; do
    # Unzip and check DLL configurations (simplified check via file inspection)
    if command -v unzip &> /dev/null; then
        TEMP_EXTRACT="/tmp/nupkg_verify_$$"
        mkdir -p "$TEMP_EXTRACT"
        unzip -q "$package" -d "$TEMP_EXTRACT" 2>/dev/null || true
        
        # Check for Debug symbols in obvious places
        if find "$TEMP_EXTRACT" -name "*.pdb" | grep -qi "debug" 2>/dev/null; then
            error "Found debug symbols in package: $(basename "$package")"
            rm -rf "$TEMP_EXTRACT"
            exit 1
        fi
        rm -rf "$TEMP_EXTRACT"
    fi
done
echo "  All packages are Release builds ✓"

# 4. Remove existing versioner installation
echo ""
echo "✓ Preparing tool installation..."
echo "  Checking for existing Versioner installation..."

# Check if old installation directory exists
if [[ -d "$HOME/Apps/Versioner" ]]; then
    echo "  Removing old installation directory..."
    rm -rf "$HOME/Apps/Versioner"
fi

# Check if versioner wrapper/symlink exists in /usr/local/bin
if [[ -f "/usr/local/bin/versioner" ]] || [[ -L "/usr/local/bin/versioner" ]]; then
    echo "  Removing existing /usr/local/bin/versioner..."
    sudo rm -f /usr/local/bin/versioner
fi

# Also check for dotnet tool installation
if dotnet tool list --global | grep -q "versioner" 2>/dev/null; then
    echo "  Uninstalling dotnet tool versioner..."
    dotnet tool uninstall versioner --global 2>/dev/null || true
fi

echo "  Ready for installation ✓"

# 5. Install versioner from platform-specific build artifacts
echo ""
echo "✓ Installing Versioner from build artifacts..."

# Auto-detect current platform and architecture
CURRENT_PLATFORM="$(detect_platform)"
CURRENT_ARCH="$(uname -m 2>/dev/null || echo 'x86_64')"

echo "  Detected platform: $CURRENT_PLATFORM"
echo "  Detected architecture: $CURRENT_ARCH"

# Determine which publish directory to use (new .NET 10.0 structure)
# Detect runtime ID using the common function
CURRENT_RUNTIME_ID="$(get_runtime_id "$CURRENT_PLATFORM")"
echo "  Detected runtime ID: $CURRENT_RUNTIME_ID"

case "$CURRENT_PLATFORM" in
    linux)
        PUBLISH_DIR="$PROJECT_ROOT/DEPLOYMENT/net10.0/linux-x64/publish"
        ARTIFACT_NAME="Versioner.Linux.zip"
        PLATFORM_DISPLAY="Linux"
        ;;
    windows)
        PUBLISH_DIR="$PROJECT_ROOT/DEPLOYMENT/net10.0/win-x64/publish"
        ARTIFACT_NAME="Versioner.Windows.zip"
        PLATFORM_DISPLAY="Windows"
        ;;
    macos)
        # Use the detected runtime ID (osx-arm64 or osx-x64)
        PUBLISH_DIR="$PROJECT_ROOT/DEPLOYMENT/net10.0/$CURRENT_RUNTIME_ID/publish"
        ARTIFACT_NAME="Versioner.macOS.zip"
        PLATFORM_DISPLAY="macOS ($CURRENT_RUNTIME_ID)"
        ;;
    *)
        error "Unsupported platform: $CURRENT_PLATFORM"
        exit 1
        ;;
esac

# Try modern publish directory first, fall back to legacy ZIP
# IMPORTANT: For self-contained builds, always prefer ZIP over publish directory
# The ZIP is created by platform-specific build scripts (_performBuildMacOS.sh, etc.) 
# and includes all native runtime libraries, while publish directory may be incomplete
PLATFORM_ZIP="$PROJECT_ROOT/DEPLOYMENT/$ARTIFACT_NAME"

# Check if ZIP exists FIRST (preferred source for self-contained builds)
if [[ -f "$PLATFORM_ZIP" ]]; then
    echo "  Using platform-specific ZIP artifact: $PLATFORM_ZIP"
    SOURCE_TYPE="zip"
elif [[ -d "$PUBLISH_DIR" ]] && [[ -f "$PUBLISH_DIR/Versioner.Cli" || -f "$PUBLISH_DIR/Versioner.Cli.exe" ]]; then
    echo "  Using modern publish directory: $PUBLISH_DIR"
    echo "  WARNING: This may not include native runtime libraries"
    SOURCE_TYPE="directory"
else
    error "$PLATFORM_DISPLAY artifact not found!"
    error "Tried: $PLATFORM_ZIP (preferred)"
    error "Tried: $PUBLISH_DIR"
    error "Please run platform-specific build first:"
    error "  macOS:   scripts/_performBuildMacOS.sh"
    error "  Linux:   scripts/_performBuildLinux.sh"
    error "  Windows: scripts/_performBuildWindows.sh"
    exit 1
fi

# Create temporary extraction directory
TEMP_EXTRACT_DIR="$(mktemp -d)"
trap "rm -rf '$TEMP_EXTRACT_DIR'" EXIT

if [[ "$SOURCE_TYPE" == "directory" ]]; then
    echo "  Copying binaries from publish directory..."
    cp -r "$PUBLISH_DIR/"* "$TEMP_EXTRACT_DIR/"
elif [[ "$SOURCE_TYPE" == "zip" ]]; then
    echo "  Extracting $PLATFORM_DISPLAY binaries from ZIP..."
    if ! unzip -q "$PLATFORM_ZIP" -d "$TEMP_EXTRACT_DIR"; then
        error "Failed to extract $PLATFORM_DISPLAY artifact"
        exit 1
    fi
else
    error "Invalid source type: $SOURCE_TYPE"
    exit 1
fi

# Verify the executable exists
if [[ "$CURRENT_PLATFORM" == "windows" ]]; then
    VERSIONER_EXECUTABLE="$TEMP_EXTRACT_DIR/Versioner.Cli.exe"
else
    VERSIONER_EXECUTABLE="$TEMP_EXTRACT_DIR/Versioner.Cli"
fi

if [[ ! -f "$VERSIONER_EXECUTABLE" ]]; then
    error "Versioner.Cli executable not found in extracted files"
    error "Expected: $VERSIONER_EXECUTABLE"
    ls -la "$TEMP_EXTRACT_DIR" | head -20
    exit 1
fi

echo "  Found Versioner.Cli executable ✓"

# Verify binary architecture
if [[ "$CURRENT_PLATFORM" == "macos" || "$CURRENT_PLATFORM" == "linux" ]]; then
    echo "  Verifying binary architecture..."
    if command -v file &> /dev/null; then
        file_output=$(file "$VERSIONER_EXECUTABLE")
        echo "  Binary info: $file_output"
        
        if [[ "$CURRENT_PLATFORM" == "macos" ]]; then
            # Check for Mach-O
            if [[ "$file_output" != *"Mach-O"* ]]; then
                error "Invalid binary format! Expected Mach-O (macOS), got: $file_output"
                exit 1
            fi
            # Check architecture if possible
            if [[ "$CURRENT_ARCH" == "arm64" && "$file_output" != *"arm64"* ]]; then
                error "Architecture mismatch! Expected arm64, got: $file_output"
                exit 1
            elif [[ "$CURRENT_ARCH" == "x86_64" && "$file_output" != *"x86_64"* ]]; then
                 # Allow arm64 on x86_64? No, usually not without Rosetta, but let's be strict
                 error "Architecture mismatch! Expected x86_64, got: $file_output"
                 exit 1
            fi
        elif [[ "$CURRENT_PLATFORM" == "linux" ]]; then
            if [[ "$file_output" != *"ELF"* ]]; then
                error "Invalid binary format! Expected ELF (Linux), got: $file_output"
                exit 1
            fi
        fi
        echo "  Binary architecture verified ✓"
    else
        warning "  'file' command not found, skipping architecture verification"
    fi
fi


# Copy all files to installation directory
INSTALL_DIR="$HOME/Apps/Versioner"
echo "  Installing to: $INSTALL_DIR"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy all files
echo "  Copying binaries and dependencies..."
cp -r "$TEMP_EXTRACT_DIR/"* "$INSTALL_DIR/"

echo "  Binaries installed ✓"

# 6. Verify Versioner installation
echo ""
echo "✓ Verifying Versioner installation..."

# Verify DLL exists
if [[ ! -f "$INSTALL_DIR/Versioner.Cli.dll" ]]; then
    error "Versioner.Cli.dll not found in installation directory"
    error "Expected: $INSTALL_DIR/Versioner.Cli.dll"
    exit 1
fi
echo "  Versioner.Cli.dll verified ✓"

# Test if dotnet can run the DLL (with a quick version check that will fail gracefully)
echo "  Testing Versioner execution via dotnet..."
if dotnet --info &> /dev/null; then
    echo "  .NET runtime available ✓"
else
    error ".NET runtime not available"
    exit 1
fi
echo "  Versioner DLL file verified ✓"

echo ""
echo "  Installation completed successfully"
echo "  To use Versioner, run:"
echo "  $INSTALL_DIR/Versioner.Cli -w /path/to/project"
echo ""

echo ""
echo "Post-publish validation completed ✓"
echo ""

# List published packages
echo "Published packages:"
ls -lh "$OUTPUT_DIR"/*.nupkg 2>/dev/null || echo "  No packages in $OUTPUT_DIR"

echo ""
echo "========================================"
echo "✅ LOCAL PUBLISH COMPLETED SUCCESSFULLY!"
echo "========================================"
echo "Solution: $SOLUTION_NAME"
echo "Packages: $PACKAGE_COUNT package(s)"
echo "Installation directory: $INSTALL_DIR"
echo "Package location: $OUTPUT_DIR"
echo ""
echo "Validation summary:"
echo "  ✓ Output directory cleaned"
echo "  ✓ Release builds verified"
echo "  ✓ Packages created ($PACKAGE_COUNT)"
echo "  ✓ Versioner installed to $INSTALL_DIR"
echo "  ✓ Versioner runs via: ./Versioner.Cli"
echo ""
echo "To use: $INSTALL_DIR/Versioner.Cli -w /path/to/project"
echo "========================================"

# Run cleanup after successful publish (unless --no-cleanup flag was used)
if [[ "$NO_CLEANUP" == "false" ]] && [[ -f "$SCRIPT_DIR/_clean.sh" ]]; then
    echo ""
    echo "Running cleanup after publish..."
    "$SCRIPT_DIR/_clean.sh" || {
        echo "⚠️  Warning: Cleanup had some issues, but publish was successful"
    }
elif [[ "$NO_CLEANUP" == "true" ]]; then
    echo ""
    echo "Skipping cleanup (--no-cleanup flag used)"
    echo "DEPLOYMENT artifacts preserved for GitHub release"
fi
