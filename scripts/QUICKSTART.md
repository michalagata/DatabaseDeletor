# Quick Start Guide - Universal .NET Build Scripts

## 5-Minute Setup

### 1. Copy Scripts to Your Project

```bash
# Copy the scripts directory to your .NET project
cp -r /path/to/scripts_dotnet /path/to/your-project/scripts

# Make scripts executable
chmod +x /path/to/your-project/scripts/*.sh
```

### 2. Verify Setup

```bash
cd /path/to/your-project

# Test project detection
./scripts/_buildDotnetSolution.sh --help
```

### 3. Build Your Project

```bash
# Standard build (Release, with tests)
./scripts/_buildDotnetSolution.sh

# Quick build without tests
./scripts/_buildDotnetSolution.sh --no-test

# Debug build
./scripts/_buildDotnetSolution.sh -c Debug
```

## Common Tasks

### Build

```bash
# Release build with tests
./scripts/_buildDotnetSolution.sh

# Debug build
./scripts/_buildDotnetSolution.sh -c Debug

# Build for specific platform
./scripts/_buildDotnetSolution.sh -r win-x64
./scripts/_buildDotnetSolution.sh -r linux-x64
./scripts/_buildDotnetSolution.sh -r osx-arm64

# Self-contained deployment
./scripts/_buildDotnetSolution.sh --self-contained
```

### Clean

```bash
# Standard cleanup (bin/, obj/, DEPLOYMENT/)
./scripts/_clean.sh

# Deep clean (+ IDE caches, NuGet cache)
./scripts/_clean.sh --deep

# Clean Docker resources too
./scripts/_clean.sh --docker

# Clean everything without prompts
./scripts/_clean.sh --all -y
```

### Test

```bash
# Run tests (automatically during build)
./scripts/_buildDotnetSolution.sh

# Skip tests
./scripts/_buildDotnetSolution.sh --no-test

# Run tests only (no publish)
./scripts/_buildDotnetSolution.sh --no-publish
```

### Publish Dotnet Tool

```bash
# Publish to nuget.org
export NUGET_API_KEY="your-key-here"
./scripts/_publishDotnetTool.sh

# Pack only (don't publish)
./scripts/_publishDotnetTool.sh --skip-publish
```

### Docker

```bash
# Build Docker image
./scripts/_buildDocker.sh

# Build and push to registry
./scripts/_buildDocker.sh -r registry.example.com --push

# Build for ARM64
./scripts/_buildDocker.sh -p linux/arm64
```

## Project Structure Examples

### Single Project (Console App)

```
MyApp/
├── MyApp.csproj          ← Automatically detected as main project
├── Program.cs
└── scripts/              ← Copy scripts here
```

**Build:**
```bash
cd MyApp
./scripts/_buildDotnetSolution.sh
# Output: ./DEPLOYMENT/MyApp/
```

### Multi-Project Solution

```
MySolution/
├── MySolution.sln        ← Automatically detected
├── src/
│   ├── MyApp/
│   │   └── MyApp.csproj  ← Main executable (OutputType=Exe)
│   ├── MyLib/
│   │   └── MyLib.csproj  ← Library
│   └── MyLib.Core/
│       └── MyLib.Core.csproj  ← Library
├── tests/
│   ├── MyApp.Tests/
│   │   └── MyApp.Tests.csproj  ← Auto-detected as test
│   └── MyLib.Tests/
│       └── MyLib.Tests.csproj  ← Auto-detected as test
└── scripts/
```

**Build:**
```bash
cd MySolution
./scripts/_buildDotnetSolution.sh
# Builds: MyLib.Core → MyLib → MyApp
# Tests: MyApp.Tests, MyLib.Tests
# Output: ./DEPLOYMENT/MyApp/
```

### Dotnet Tool

```
MyTool/
├── MyTool.csproj         ← Contains <PackAsTool>true</PackAsTool>
├── Program.cs
└── scripts/
```

**Build and Publish:**
```bash
cd MyTool
export NUGET_API_KEY="your-key"
./scripts/_publishDotnetTool.sh
# Creates: ./DEPLOYMENT/nupkg/MyTool.1.0.0.nupkg
# Publishes to: nuget.org
```

## Configuration

### Environment Variables

Create a `.env` file in your project root:

```bash
# .env
PROJECT_ROOT=/home/user/myproject
BUILD_CONFIG=Debug
SKIP_TESTS=true
OUTPUT_DIR=./publish
RUNTIME_ID=linux-x64
NUGET_API_KEY=your-key-here
```

Load it before building:

```bash
source .env
./scripts/_buildDotnetSolution.sh
```

### Custom Wrapper Script

Create `build.sh` in your project root:

```bash
#!/usr/bin/env bash
# build.sh - Custom build wrapper

set -e

# Project-specific settings
export BUILD_CONFIG=Release
export SKIP_TESTS=false

# Run universal build
./scripts/_buildDotnetSolution.sh "$@"

# Custom post-build steps
echo "Running custom tasks..."
# Your logic here
```

## Troubleshooting

### "No .NET project found"

**Problem:** Scripts can't find .sln or .csproj files

**Solution:**
```bash
# Verify you're in project root
pwd

# Check for project files
find . -name "*.sln" -o -name "*.csproj"

# Set PROJECT_ROOT explicitly
export PROJECT_ROOT=$(pwd)
./scripts/_buildDotnetSolution.sh
```

### "Permission denied"

**Problem:** Scripts not executable

**Solution:**
```bash
chmod +x ./scripts/*.sh
```

### Tests Fail

**Problem:** Test projects fail during build

**Solution:**
```bash
# Skip tests temporarily
./scripts/_buildDotnetSolution.sh --no-test

# Or fix tests and rebuild
./scripts/_clean.sh
./scripts/_buildDotnetSolution.sh
```

### Docker Issues

**Problem:** Docker build fails

**Solution:**
```bash
# Ensure Docker is running
docker ps

# Check Dockerfile exists
ls -la Dockerfile

# Try building without cache
docker build --no-cache .
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      - run: ./scripts/_buildDotnetSolution.sh
```

### GitLab CI

```yaml
# .gitlab-ci.yml
build:
  image: mcr.microsoft.com/dotnet/sdk:8.0
  script:
    - ./scripts/_buildDotnetSolution.sh
```

### Jenkins

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh './scripts/_buildDotnetSolution.sh'
            }
        }
    }
}
```

## What Gets Auto-Detected?

✅ **Solution Files** (*.sln)
✅ **Project Files** (*.csproj)
✅ **Main Executable** (OutputType=Exe)
✅ **Dotnet Tools** (PackAsTool=true)
✅ **Libraries** (any project without Exe or Test)
✅ **Test Projects** (name contains "Test" or references test SDKs)
✅ **Target Framework** (net8.0, net7.0, etc.)
✅ **Platform** (Linux, macOS x64/ARM64, Windows)

## Next Steps

1. Read the [full README.md](README.md) for complete documentation
2. Customize scripts for your project needs
3. Integrate into your CI/CD pipeline
4. Share with your team!

## Support

For issues or questions:
1. Check [README.md](README.md) Troubleshooting section
2. Review script comments and help output (`--help`)
3. Run with verbose logging: `set -x` before script execution

---

**Last Updated:** January 2026
**Compatible with:** .NET 6.0, 7.0, 8.0+
