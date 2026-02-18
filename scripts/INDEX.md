# Scripts Documentation Index

Welcome to the Universal .NET Build Scripts documentation!

## 📚 Documentation Files

### 1. [README.md](README.md) - **START HERE** 📖
**Comprehensive reference guide (2000+ lines)**

Complete documentation covering:
- All scripts with detailed options
- Configuration methods
- Environment variables
- Auto-detection algorithms
- 4 real-world examples
- Troubleshooting guide
- CI/CD integration
- Best practices

**Best for:** Understanding all features and capabilities

---

### 2. [QUICKSTART.md](QUICKSTART.md) - **5-Minute Guide** ⚡
**Get started immediately**

Quick reference for:
- Setup in 5 minutes
- Common tasks and commands
- Project structure examples
- Quick troubleshooting
- CI/CD snippets

**Best for:** Getting started quickly

---

### 3. [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - **What Changed** 🔄
**Refactoring overview**

Details about:
- What was refactored
- New features
- Migration guide
- Before/after comparison
- Testing checklist

**Best for:** Understanding the changes made

---

## 🚀 Quick Navigation

### By Task

| Task | Document | Section |
|------|----------|---------|
| **First-time setup** | [QUICKSTART.md](QUICKSTART.md) | 5-Minute Setup |
| **Build my project** | [QUICKSTART.md](QUICKSTART.md) | Common Tasks → Build |
| **Clean build artifacts** | [QUICKSTART.md](QUICKSTART.md) | Common Tasks → Clean |
| **Run tests** | [QUICKSTART.md](QUICKSTART.md) | Common Tasks → Test |
| **Publish dotnet tool** | [QUICKSTART.md](QUICKSTART.md) | Common Tasks → Publish |
| **Docker build** | [QUICKSTART.md](QUICKSTART.md) | Common Tasks → Docker |
| **Configure scripts** | [README.md](README.md) | Configuration |
| **Environment variables** | [README.md](README.md) | Environment Variables |
| **Troubleshooting** | [README.md](README.md) | Troubleshooting |
| **CI/CD integration** | [QUICKSTART.md](QUICKSTART.md) | CI/CD Integration |
| **See what changed** | [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) | Overview |

### By Role

| Role | Start Here |
|------|------------|
| **New User** | [QUICKSTART.md](QUICKSTART.md) → Then [README.md](README.md) |
| **DevOps Engineer** | [README.md](README.md) § CI/CD Integration |
| **Developer** | [QUICKSTART.md](QUICKSTART.md) § Common Tasks |
| **Team Lead** | [README.md](README.md) § Overview → [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) |
| **Contributor** | [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) → [README.md](README.md) |

---

## 📋 Script Reference

### Core Scripts

| Script | Purpose | Documentation |
|--------|---------|---------------|
| `_common.sh` | Shared functions library | [README.md § _common.sh](README.md#commonsh) |
| `_buildDotnetSolution.sh` | Universal solution builder | [README.md § _buildDotnetSolution.sh](README.md#_builddotnetsolutionsh) |
| `_clean.sh` | Cleanup artifacts | [README.md § _clean.sh](README.md#_cleansh) |
| `_publishDotnetTool.sh` | Publish dotnet tool | [README.md § _publishDotnetTool.sh](README.md#_publishdotnettoolsh) |
| `_buildDocker.sh` | Docker image builder | [README.md § _buildDocker.sh](README.md#_builddockersh) |
| `_dockerPush.sh` | Push Docker image | [README.md § _dockerPush.sh](README.md#_dockerpushsh) |
| `_dockerRun.sh` | Run Docker container | [README.md § _dockerRun.sh](README.md#_dockerrunsh) |

### Helper Scripts

| Script | Purpose |
|--------|---------|
| `build.sh` | Simple build wrapper |
| `clean.sh` | Simple clean wrapper |

### Platform-Specific

| Script | Purpose |
|--------|---------|
| `_performBuildLinux.sh` | Build for Linux |
| `_performBuildMacOS.sh` | Build for macOS |
| `_performBuildWindows.sh` | Build for Windows |

---

## 🎯 Common Use Cases

### Use Case 1: Build a .NET Console App
```bash
# Read: QUICKSTART.md § "Single Project (Console App)"
cd MyConsoleApp
./scripts/_buildDotnetSolution.sh
```

### Use Case 2: Build Multi-Project Solution
```bash
# Read: QUICKSTART.md § "Multi-Project Solution"
cd MySolution
./scripts/_buildDotnetSolution.sh
```

### Use Case 3: Publish Dotnet Tool to NuGet
```bash
# Read: README.md § "Publish Dotnet Tool"
export NUGET_API_KEY="your-key"
./scripts/_publishDotnetTool.sh
```

### Use Case 4: Docker Build & Push
```bash
# Read: README.md § "Docker Scripts"
./scripts/_buildDocker.sh -r registry.example.com --push
```

### Use Case 5: CI/CD Integration
```bash
# Read: QUICKSTART.md § "CI/CD Integration"
# See examples for GitHub Actions, GitLab CI, Jenkins
```

---

## 🔍 Finding Information

### How do I...?

| Question | Answer Location |
|----------|----------------|
| **...get started quickly?** | [QUICKSTART.md](QUICKSTART.md) |
| **...build my project?** | [QUICKSTART.md § Common Tasks](QUICKSTART.md#common-tasks) |
| **...configure environment variables?** | [README.md § Environment Variables](README.md#environment-variables) |
| **...understand auto-detection?** | [README.md § How It Works](README.md#how-it-works) |
| **...troubleshoot errors?** | [README.md § Troubleshooting](README.md#troubleshooting) |
| **...integrate with CI/CD?** | [QUICKSTART.md § CI/CD Integration](QUICKSTART.md#cicd-integration) |
| **...see what changed?** | [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) |
| **...understand all options?** | [README.md § Script Reference](README.md#script-reference) |

---

## 🧭 Recommended Reading Path

### For New Users (15 minutes total)

1. **[QUICKSTART.md](QUICKSTART.md)** (5 min)
   - Read: 5-Minute Setup
   - Read: Common Tasks
   - Try: Build your first project

2. **[README.md](README.md)** (10 min)
   - Skim: Quick Start
   - Read: Your relevant use case example
   - Bookmark: Troubleshooting section

### For Team Leads (30 minutes)

1. **[QUICKSTART.md](QUICKSTART.md)** (5 min)
2. **[README.md](README.md)** (15 min)
   - Read: Overview and Features
   - Read: Configuration
   - Read: Examples (all 4)
3. **[REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md)** (10 min)
   - Read: Overview
   - Read: Key Takeaways

### For Contributors (45 minutes)

1. **[REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md)** (15 min) - Understand changes
2. **[README.md](README.md)** (20 min) - Complete reference
3. **Script source code** (10 min) - Review `_common.sh`

---

## 📖 Documentation Structure

```
scripts_dotnet/
├── INDEX.md                          ← You are here
├── README.md                         ← Complete reference
├── QUICKSTART.md                     ← Quick start guide
├── REFACTORING_SUMMARY.md           ← What changed
│
├── _common.sh                        ← Shared functions (inline docs)
├── _buildDotnetSolution.sh          ← Main build script (inline docs)
├── _clean.sh                         ← Cleanup script (inline docs)
│
└── [Other scripts with inline help]
```

---

## 💡 Tips

### Getting Help

Every script has built-in help:
```bash
./scripts/_buildDotnetSolution.sh --help
./scripts/_clean.sh --help
./scripts/_publishDotnetTool.sh --help
```

### Quick Reference

Keep [QUICKSTART.md](QUICKSTART.md) handy for:
- Command syntax
- Common options
- Quick troubleshooting

### Deep Dive

Use [README.md](README.md) when you need:
- Complete option list
- Detailed examples
- Configuration details
- Troubleshooting steps

---

## 🔗 External Resources

- [.NET Documentation](https://docs.microsoft.com/en-us/dotnet/)
- [Docker Documentation](https://docs.docker.com/)
- [NuGet Documentation](https://docs.microsoft.com/en-us/nuget/)
- [Runtime Identifier Catalog](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog)

---

## ✨ Summary

This documentation set provides everything you need to use the Universal .NET Build Scripts:

- **QUICKSTART.md** - Fast setup and common tasks
- **README.md** - Complete reference and examples
- **REFACTORING_SUMMARY.md** - Change overview
- **INDEX.md** - This navigation guide

All scripts are:
- ✅ Universal (work with any .NET project)
- ✅ Automatic (zero configuration)
- ✅ Cross-platform (Linux, macOS, Windows)
- ✅ Well-documented (inline help + guides)

**Start with [QUICKSTART.md](QUICKSTART.md) if you're new!**

---

**Last Updated:** January 19, 2026  
**Scripts Version:** 2.0.0  
**Minimum .NET:** 8.0
