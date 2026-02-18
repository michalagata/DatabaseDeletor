# Universal .NET Build & Deployment Scripts

> **Fully automatic, zero-configuration build scripts for any .NET solution**

This directory contains a comprehensive set of universal bash scripts for building, testing, publishing, and deploying .NET applications. These scripts are designed to work with **any .NET project** without manual configuration.

## 🎯 Key Features

- **Zero Configuration**: Automatically detects projects, solutions, test projects, and entry points
- **Universal**: Works with any .NET solution structure (single project, multi-project, libraries, tools)
- **Cross-Platform**: Compatible with Linux, macOS, and Windows (Git Bash/WSL)
- **Smart Detection**: Identifies executable projects, libraries, tests, and dotnet tools automatically
- **Docker Support**: Complete Docker build, run, and push workflows
- **CI/CD Ready**: Can be integrated into any CI/CD pipeline
- **Versioning**: Automatic versioning with Versioner tool integration

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Script Reference](#script-reference)
- [Configuration](#configuration)
- [How It Works](#how-it-works)
- [Environment Variables](#environment-variables)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

### Prerequisites

- **.NET SDK 8.0+** (auto-detected, minimum version configurable)
- **Bash/Zsh** shell (macOS/Linux native, Git Bash for Windows)
- **Docker** (optional, for containerization)
- **Git** (optional, for versioning features)

### Basic Usage

```bash
# 1. Navigate to your .NET project root directory
cd /path/to/your/dotnet/project

# 2. Copy the scripts_dotnet directory to your project
cp -r /path/to/scripts_dotnet ./scripts

# 3. Build your solution
./scripts/_buildDotnetSolution.sh

# 4. Run tests (automatically discovered)
# Tests are run automatically during build, or:
SKIP_TESTS=false ./scripts/_buildDotnetSolution.sh

# 5. Publish dotnet tool (if applicable)
./scripts/_publishDotnetTool.sh

# 6. Build Docker image (if Dockerfile present)
./scripts/_buildDocker.sh
```

---

## 📖 Script Reference

### Core Build Scripts

#### `_common.sh`
**Shared library of functions used by all scripts**

- Project auto-detection (solutions, projects, test projects)
- Logging and output formatting
- Platform identification (Linux, macOS, Windows)
- Build/test/publish helper functions

**Key Functions:**
- `find_solution_files()` - Finds all .sln files
- `find_main_project()` - Identifies the executable entry point
- `find_test_projects()` - Discovers all test projects
- `find_library_projects()` - Lists all library projects
- `detect_project_type()` - Determines project type (Executable/Tool/Library/Test)
- `run_restore()` - Restores NuGet dependencies
- `run_build()` - Builds solution or project
- `run_tests()` - Executes all test projects
- `run_publish()` - Publishes artifacts

**Usage:**
```bash
source ./scripts/_common.sh
```

---

#### `_buildDotnetSolution.sh`
**Universal solution builder - works with ANY .NET project**

Automatically performs:
1. Environment validation (checks .NET SDK)
2. Project/solution discovery
3. Dependency restoration
4. Solution build
5. Test execution
6. Artifact publishing

**Usage:**
```bash
./scripts/_buildDotnetSolution.sh [OPTIONS]
```

**Options:**
- `-c, --configuration CONFIG` - Build configuration (Debug/Release) [default: Release]
- `-o, --output DIR` - Output directory [default: ./DEPLOYMENT]
- `-r, --runtime RID` - Runtime identifier (win-x64, linux-x64, osx-arm64, etc.)
- `--no-restore` - Skip dependency restoration
- `--no-build` - Skip build step
- `--no-test` - Skip test execution
- `--no-publish` - Skip publishing
- `--self-contained` - Create self-contained deployment
- `--verbosity LEVEL` - MSBuild verbosity (quiet/minimal/normal/detailed/diagnostic)

**Examples:**
```bash
# Build with all default settings
./scripts/_buildDotnetSolution.sh

# Debug build without tests
./scripts/_buildDotnetSolution.sh -c Debug --no-test

# Self-contained Windows executable
./scripts/_buildDotnetSolution.sh -r win-x64 --self-contained

# Custom output directory
./scripts/_buildDotnetSolution.sh -o /tmp/myapp-build
```

---

#### `_clean.sh`
**Automatic cleanup of build artifacts and temporary files**

Cleans:
- `bin/` directories
- `obj/` directories
- `*.bak` files
- `DEPLOYMENT/` directory
- Docker containers/images (optional)

**Usage:**
```bash
./scripts/_clean.sh [OPTIONS]
```

**Options:**
- `--deep` - Deep clean including NuGet cache
- `--docker` - Clean Docker images/containers
- `--all` - Clean everything including node_modules, .vs, etc.

**Examples:**
```bash
# Standard cleanup
./scripts/_clean.sh

# Deep clean with Docker
./scripts/_clean.sh --deep --docker
```

---

### Dotnet Tool Publishing

#### `_publishDotnetTool.sh`
**Publish your project as a dotnet global tool**

Automatically:
1. Detects tool projects (PackAsTool=true) or executable projects
2. Builds and packs as NuGet package
3. Publishes to NuGet feed (configurable)

**Usage:**
```bash
./scripts/_publishDotnetTool.sh [OPTIONS]
```

**Options:**
- `-c, --configuration CONFIG` - Build configuration [default: Release]
- `-f, --feed URL` - NuGet feed URL [default: https://api.nuget.org/v3/index.json]
- `-k, --api-key KEY` - NuGet API key (or use NUGET_API_KEY env var)
- `--skip-publish` - Only pack, don't publish
- `--clean` - Clean build before packing

**Examples:**
```bash
# Publish to nuget.org
export NUGET_API_KEY="your-api-key-here"
./scripts/_publishDotnetTool.sh

# Pack only (don't publish)
./scripts/_publishDotnetTool.sh --skip-publish

# Publish to private feed
./scripts/_publishDotnetTool.sh -f https://my-nuget-feed/v3/index.json -k my-key
```

---

### Docker Scripts

#### `_buildDocker.sh`
**Build Docker image for your .NET application**

Automatically:
1. Detects Dockerfile in project root
2. Builds .NET solution for Linux
3. Creates Docker image
 4. Tags image appropriately
5. Optionally pushes to registry

**Usage:**
```bash
./scripts/_buildDocker.sh [OPTIONS]
```

**Options:**
- `-n, --name NAME` - Image name [default: auto-detected from solution]
- `-t, --tag TAG` - Image tag [default: latest]
- `-r, --registry URL` - Docker registry URL
- `-p, --platform PLATFORM` - Target platform [default: linux/amd64]
- `--push` - Push image after build

**Examples:**
```bash
# Build with auto-detected name
./scripts/_buildDocker.sh

# Build and push to registry
./scripts/_buildDocker.sh -r registry.example.com --push

# Build for ARM64
./scripts/_buildDocker.sh -p linux/arm64 -t arm64-latest
```

---

#### `_dockerPush.sh`
**Push Docker image to registry**

**Usage:**
```bash
./scripts/_dockerPush.sh [IMAGE_NAME] [TAG] [REGISTRY]
```

**Examples:**
```bash
# Push with defaults
./scripts/_dockerPush.sh

# Push specific tag to registry
./scripts/_dockerPush.sh myapp v1.0.0 registry.example.com
```

---

#### `_dockerRun.sh`
**Run Docker container with appropriate configuration**

**Usage:**
```bash
./scripts/_dockerRun.sh [OPTIONS] [COMMAND_ARGS]
```

**Examples:**
```bash
# Run with default settings
./scripts/_dockerRun.sh

# Run with custom command
./scripts/_dockerRun.sh --help

# Mount volume and run
./scripts/_dockerRun.sh -v /host/path:/container/path
```

---

### Platform-Specific Build Scripts

#### `_performBuildLinux.sh`
Build for Linux (x64) runtime.

#### `_performBuildMacOS.sh`
Build for macOS (auto-detects x64/ARM64).

#### `_performBuildWindows.sh`
Build for Windows (x64) runtime.

**Usage:**
```bash
./scripts/_performBuild<Platform>.sh [-c Debug|Release] [-o OUTPUT_DIR]
```

---

### Versioning Scripts

#### `_versionArtifacts.sh`
**Automatic version management using Versioner tool**

Automatically:
1. Detects Versioner installation (or downloads it)
2. Increments version numbers in `.csproj` files
3. Updates version.txt file
4. Cleans up .bak files

**Usage:**
```bash
./scripts/_versionArtifacts.sh [OPTIONS]
```

**Options:**
- `-w, --working-dir DIR` - Working directory [default: current]
- `-l, --log-level LEVEL` - Log level (V/D/I/W/E/F) [default: I]
- `-s, --store-version` - Store version in version.txt
- `-d, --use-defaults` - Use default settings
- `--cleanup-backups` - Clean .bak files after versioning

---

#### `_increaseMajorVersion.sh`
**Increment major version number**

**Usage:**
```bash
./scripts/_increaseMajorVersion.sh
```

---

### Complete Workflow Scripts

#### `_buildAndPublishAndReleaseAll.sh`
**Complete CI/CD workflow: version → build → test → publish → release**

Executes full pipeline:
1. Version artifacts
2. Build for all platforms (Linux, macOS, Windows)
3. Run tests
4. Create Docker images
5. Publish to GitHub releases

**Usage:**
```bash
./scripts/_buildAndPublishAndReleaseAll.sh
```

---

#### `_testCompleteBuildAndRelease.sh`
**Test the entire build and release pipeline**

Validates:
- Tool availability (dotnet, git, docker, gh)
- Script presence
- Build process
- Test execution
- Artifact creation
- Release publishing

**Usage:**
```bash
./scripts/_testCompleteBuildAndRelease.sh
```

---

## ⚙️ Configuration

### Project Auto-Detection Rules

The scripts use intelligent heuristics to detect project structure:

1. **Solution Detection**:
   - Searches for `*.sln` files in project root (max depth: 2)
   - If no solution found, operates on individual projects

2. **Main Project Detection** (Priority Order):
   - Projects with `<OutputType>Exe</OutputType>`
   - Projects with `<PackAsTool>true</PackAsTool>`
   - Projects in common directories: `Cli/`, `App/`, `Console/`, `Application/`, `Main/`, `Host/`
   - First non-test `.csproj` file found

3. **Test Project Detection**:
   - Project name contains "Test" or "Tests" (case-insensitive)
   - Directory name contains "Test", "Tests", or "Testing"
   - Contains test SDK references: `Microsoft.NET.Test.Sdk`, `xunit`, `nunit`, `mstest`

4. **Library Project Detection**:
   - Any `.csproj` that is NOT executable, NOT a tool, NOT a test

---

### Environment Variables

Scripts support configuration via environment variables:

#### Global Variables

```bash
# Project root directory (auto-detected)
export PROJECT_ROOT="/path/to/your/project"

# Minimum .NET version requirement
export DOTNET_VERSION_MIN=8

# Skip test execution
export SKIP_TESTS=true
```

#### Build Configuration

```bash
# Build configuration
export BUILD_CONFIG=Release  # or Debug

# Output directory
export OUTPUT_DIR=./DEPLOYMENT

# Runtime identifier
export RUNTIME_ID=linux-x64

# Self-contained deployment
export SELF_CONTAINED=true

# MSBuild verbosity
export VERBOSITY=minimal
```

#### Docker Configuration

```bash
# Docker image name
export IMAGE_NAME=myapp

# Docker image tag
export IMAGE_TAG=v1.0.0

# Docker registry
export REGISTRY=registry.example.com

# Docker platform
export PLATFORM=linux/amd64

# Auto-push after build
export PUSH=true
```

#### NuGet Configuration

```bash
# NuGet API key
export NUGET_API_KEY=your-api-key

# NuGet feed URL
export NUGET_FEED_URL=https://api.nuget.org/v3/index.json
```

#### Versioner Configuration

```bash
# Versioner installation directory
export VERSIONER_DIR=/path/to/versioner

# Working directory for versioning
export WORKING_DIR=/path/to/project

# Log level (V=Verbose, D=Debug, I=Info, W=Warning, E=Error, F=Fatal)
export LOG_LEVEL=I

# Store version in version.txt
export STORE_VERSION_FILE=true

# Use default versioning settings
export USE_DEFAULTS=true

# Cleanup .bak files after versioning
export CLEANUP_BACKUPS=true
```

---

## 🔍 How It Works

### Automatic Discovery Process

When you run a build script, it follows this process:

```
1. Source _common.sh (loads all detection functions)
   ↓
2. Validate environment (check .NET SDK, Git, Docker)
   ↓
3. Auto-detect project structure:
   - Find .sln file (if exists)
   - Find all .csproj files
   - Classify projects: Executable, Tool, Library, Test
   - Identify main entry point project
   ↓
4. Execute build pipeline:
   - Restore NuGet dependencies
   - Build solution/projects (libraries first, then main)
   - Run discovered tests
   - Publish main project artifacts
   ↓
5. Post-processing:
   - Clean temporary files (.bak)
   - Copy documentation (README, LICENSE)
   - Generate summary report
```

### Project Type Classification

```
┌─────────────────────────────────────────────────────────────┐
│ Project Detection Algorithm                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  IF contains "Test" in name/path                           │
│     OR contains test SDK references                        │
│  → TEST PROJECT                                            │
│                                                             │
│  ELSE IF contains <OutputType>Exe</OutputType>            │
│  → EXECUTABLE PROJECT (Main Entry Point)                  │
│                                                             │
│  ELSE IF contains <PackAsTool>true</PackAsTool>           │
│  → DOTNET TOOL PROJECT                                     │
│                                                             │
│  ELSE                                                      │
│  → LIBRARY PROJECT                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Runtime Identifier Auto-Detection

```bash
# Platform auto-detection
OS=$(uname -s)
ARCH=$(uname -m)

if [[ "$OS" == "Linux" ]]; then
    RID="linux-x64"
elif [[ "$OS" == "Darwin" ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
        RID="osx-arm64"
    else
        RID="osx-x64"
    fi
elif [[ "$OS" == MINGW* ]] || [[ "$OS" == MSYS* ]]; then
    RID="win-x64"
fi
```

---

## 💡 Examples

### Example 1: Simple Console Application

```
MyConsoleApp/
├── MyConsoleApp.sln
├── src/
│   └── MyConsoleApp/
│       └── MyConsoleApp.csproj  (Executable)
├── tests/
│   └── MyConsoleApp.Tests/
│       └── MyConsoleApp.Tests.csproj
└── scripts/  (this directory)
```

**Build command:**
```bash
cd MyConsoleApp
./scripts/_buildDotnetSolution.sh
```

**Result:**
- Detects `MyConsoleApp.sln`
- Restores dependencies
- Builds solution
- Runs `MyConsoleApp.Tests`
- Publishes executable to `./DEPLOYMENT/MyConsoleApp/`

---

### Example 2: Multi-Project Library Solution

```
MyLibrary/
├── src/
│   ├── MyLibrary.Core/
│   │   └── MyLibrary.Core.csproj  (Library)
│   ├── MyLibrary.Extensions/
│   │   └── MyLibrary.Extensions.csproj  (Library)
│   └── MyLibrary.Cli/
│       └── MyLibrary.Cli.csproj  (Tool: PackAsTool=true)
├── tests/
│   ├── MyLibrary.Core.Tests/
│   └── MyLibrary.Extensions.Tests/
└── scripts/
```

**Build and publish as tool:**
```bash
cd MyLibrary
./scripts/_buildDotnetSolution.sh  # Builds all
./scripts/_publishDotnetTool.sh    # Publishes Cli as tool
```

**Result:**
- Builds libraries first (Core, Extensions)
- Builds CLI tool
- Runs all test projects
- Packs and publishes MyLibrary.Cli as NuGet tool

---

### Example 3: Dockerized Web API

```
MyWebApi/
├── Dockerfile
├── src/
│   ├── MyWebApi/
│   │   └── MyWebApi.csproj  (Web API)
│   └── MyWebApi.Domain/
│       └── MyWebApi.Domain.csproj  (Library)
└── scripts/
```

**Build Docker image:**
```bash
cd MyWebApi
./scripts/_buildDocker.sh -n mywebapi -t v1.0.0 -r myregistry.azurecr.io --push
```

**Result:**
- Builds .NET solution for Linux
- Creates Docker image `myregistry.azurecr.io/mywebapi:v1.0.0`
- Pushes to Azure Container Registry

---

### Example 4: CI/CD Pipeline Integration

**.github/workflows/build.yml** (GitHub Actions)

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      
      - name: Build Solution
        run: ./scripts/_buildDotnetSolution.sh
      
      - name: Upload Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: deployment
          path: ./DEPLOYMENT/
```

**GitLab CI** (.gitlab-ci.yml)

```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  image: mcr.microsoft.com/dotnet/sdk:8.0
  script:
    - ./scripts/_buildDotnetSolution.sh
  artifacts:
    paths:
      - DEPLOYMENT/
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. "No .NET project found in project root"

**Cause**: Scripts cannot find `.sln` or `.csproj` files.

**Solution**:
- Ensure you're running scripts from project root
- Check PROJECT_ROOT is set correctly
- Verify `.csproj` files exist and are not in `obj/` or `bin/`

```bash
# Verify detection
source ./scripts/_common.sh
is_dotnet_project && echo "Project found" || echo "Project not found"
find_all_projects
```

---

#### 2. ".NET SDK 8.0 or later is required"

**Cause**: Installed .NET SDK version is too old.

**Solution**:
- Install .NET 8.0+ SDK from https://dotnet.microsoft.com/download
- Or override minimum version:

```bash
export DOTNET_VERSION_MIN=6  # If you need .NET 6
./scripts/_buildDotnetSolution.sh
```

---

#### 3. "Tests failed - cannot proceed"

**Cause**: One or more test projects failed.

**Solution**:
- Fix failing tests
- Or skip tests temporarily:

```bash
./scripts/_buildDotnetSolution.sh --no-test
```

---

#### 4. "Docker image not found locally"

**Cause**: Trying to push Docker image that wasn't built.

**Solution**:
```bash
# Build first, then push
./scripts/_buildDocker.sh
./scripts/_dockerPush.sh
```

---

#### 5. Permission denied when running scripts

**Cause**: Scripts are not executable.

**Solution**:
```bash
chmod +x ./scripts/*.sh
```

---

### Debug Mode

Enable verbose logging:

```bash
# Set bash debug mode
set -x

# Or use verbose .NET logging
export VERBOSITY=detailed
./scripts/_buildDotnetSolution.sh
```

---

### Manual Project Detection

```bash
# Source common functions
source ./scripts/_common.sh

# Show project summary
show_project_summary

# List all projects
echo "All projects:"
find_all_projects

# Find main project
echo "Main project:"
find_main_project

# Find test projects
echo "Test projects:"
find_test_projects

# Find libraries
echo "Library projects:"
find_library_projects
```

---

## 🎓 Best Practices

### 1. Use Environment Variables for CI/CD

```bash
# .env file for local development
PROJECT_ROOT=/home/dev/myproject
BUILD_CONFIG=Debug
SKIP_TESTS=true

# Load in script
if [[ -f .env ]]; then
    source .env
fi
./scripts/_buildDotnetSolution.sh
```

### 2. Keep Scripts Updated

```bash
# Pull latest scripts from template repository
git remote add scripts-template https://github.com/your-org/dotnet-scripts-template
git fetch scripts-template
git checkout scripts-template/main -- scripts/
```

### 3. Customize for Your Project

Create a wrapper script in your project root:

**build.sh**:
```bash
#!/usr/bin/env bash
set -e

# Project-specific configuration
export BUILD_CONFIG=Release
export RUNTIME_ID=linux-x64
export SKIP_TESTS=false

# Run universal build script
./scripts/_buildDotnetSolution.sh "$@"

# Project-specific post-build steps
echo "Running custom post-build steps..."
# Your custom logic here
```

### 4. Document Project-Specific Requirements

Add a **BUILD.md** to your project:

```markdown
# Build Instructions

## Prerequisites
- .NET 8.0 SDK
- Docker (for containerization)

## Quick Build
```bash
./build.sh
```

## Docker Build
```bash
./scripts/_buildDocker.sh --push
```
```

---

## 📚 Additional Resources

- [.NET Documentation](https://docs.microsoft.com/en-us/dotnet/)
- [Docker Documentation](https://docs.docker.com/)
- [Runtime Identifier (RID) Catalog](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog)
- [NuGet Documentation](https://docs.microsoft.com/en-us/nuget/)

---

## 📝 License

These scripts are provided as-is under the MIT License. Feel free to modify and adapt them to your needs.

---

## 🤝 Contributing

Found a bug or have a suggestion? Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## ✅ Script Compatibility Matrix

| Script | Linux | macOS | Windows (Git Bash) | Docker | .NET 6 | .NET 7 | .NET 8 |
|--------|-------|-------|--------------------|--------|--------|--------|--------|
| _common.sh | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | ✅ |
| _buildDotnetSolution.sh | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| _clean.sh | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| _publishDotnetTool.sh | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| _buildDocker.sh | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ✅ |
| _dockerPush.sh | ✅ | ✅ | ⚠️ | ✅ | N/A | N/A | N/A |
| _dockerRun.sh | ✅ | ✅ | ⚠️ | ✅ | N/A | N/A | N/A |
| _versionArtifacts.sh | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |

**Legend:**
- ✅ Fully supported
- ⚠️ Partial support (requires Docker Desktop on Windows/macOS)
- ❌ Not applicable/Not supported

---

**Last Updated**: January 2026
**Script Version**: 2.0.0
**Minimum .NET Version**: 8.0
