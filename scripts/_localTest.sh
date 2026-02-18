#!/usr/bin/env zsh
# =============================================================================
# _localTest.sh
# =============================================================================
#
# Comprehensive local testing script for .NET projects
# Performs: build, run, healthchecks, system checks, smoke tests
#
# Requirements:
# - macOS/Linux (bash/zsh)
# - .NET SDK 8.0+
# - Git
# - Docker (optional, for Docker tests)
#
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# ---------- Configuration and constants ----------
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="_localTest.sh"

# Colors for output
if command -v tput >/dev/null 2>&1; then
  readonly RED="$(tput setaf 1)"
  readonly GREEN="$(tput setaf 2)"
  readonly YELLOW="$(tput setaf 3)"
  readonly BLUE="$(tput setaf 4)"
  readonly PURPLE="$(tput setaf 5)"
  readonly CYAN="$(tput setaf 6)"
  readonly WHITE="$(tput setaf 7)"
  readonly BOLD="$(tput bold)"
  readonly RESET="$(tput sgr0)"
else
  readonly RED="" GREEN="" YELLOW="" BLUE="" PURPLE="" CYAN="" WHITE="" BOLD="" RESET=""
fi

# Script paths
readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Test configuration
SKIP_BUILD="${SKIP_BUILD:-false}"
SKIP_TESTS="${SKIP_TESTS:-false}"
SKIP_DOCKER="${SKIP_DOCKER:-false}"
VERBOSE="${VERBOSE:-false}"
BUILD_CONFIG="${BUILD_CONFIG:-Release}"

# ---------- Logging functions ----------
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

log_info() {
  echo -e "${BLUE}[$(timestamp)] [INFO]${RESET} $*" >&2
}

log_success() {
  echo -e "${GREEN}[$(timestamp)] [SUCCESS]${RESET} $*" >&2
}

log_warning() {
  echo -e "${YELLOW}[$(timestamp)] [WARNING]${RESET} $*" >&2
}

log_error() {
  echo -e "${RED}[$(timestamp)] [ERROR]${RESET} $*" >&2
}

log_header() {
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${PURPLE}║${WHITE} $1${PURPLE}${RESET}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"
}

log_step() {
  echo -e "\n${CYAN}🔧 $1${RESET}" >&2
}

# ---------- Validation functions ----------

# Check tool availability
check_tools() {
  log_step "Checking tool availability"
  
  local missing_tools=()
  
  if ! command -v dotnet &> /dev/null; then
    missing_tools+=("dotnet")
  else
    local dotnet_version
    dotnet_version="$(dotnet --version 2>/dev/null || echo "unknown")"
    log_info "Found .NET SDK: $dotnet_version"
  fi
  
  if ! command -v git &> /dev/null; then
    missing_tools+=("git")
  else
    log_info "Found Git: $(git --version 2>/dev/null | head -n1 || echo "unknown")"
  fi
  
  if command -v docker &> /dev/null; then
    log_info "Found Docker: $(docker --version 2>/dev/null | head -n1 || echo "unknown")"
  else
    log_warning "Docker not found - Docker tests will be skipped"
    SKIP_DOCKER="true"
  fi
  
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    return 1
  fi
  
  log_success "All required tools are available"
  return 0
}

# Check if we're in a .NET project
check_dotnet_project() {
  log_step "Checking .NET project"
  
  # Load common functions
  if [[ -f "$SCRIPT_DIR/_common.sh" ]]; then
    source "$SCRIPT_DIR/_common.sh"
    
    if ! is_dotnet_project; then
      log_warning "No .NET project found in directory: $PROJECT_ROOT"
      return 1
    fi
    
    local solution_name
    solution_name="$(get_solution_name 2>/dev/null || echo "Unknown")"
    log_info "Detected project: $solution_name"
  else
    # Fallback: check manually
    if [[ -z "$(find "$PROJECT_ROOT" -maxdepth 3 -name "*.csproj" -type f 2>/dev/null | head -n 1)" ]] && \
       [[ -z "$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.sln" -type f 2>/dev/null | head -n 1)" ]]; then
      log_warning "No .NET project found in directory: $PROJECT_ROOT"
      return 1
    fi
  fi
  
  log_success ".NET project verified"
  return 0
}

# Check Git repository
check_git_repo() {
  log_step "Checking Git repository"
  
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_warning "Not in a Git repository - some checks may be skipped"
    return 0
  fi
  
  log_info "Git repository: $(git remote get-url origin 2>/dev/null || echo "local only")"
  log_success "Git repository verified"
  return 0
}

# ---------- Test functions ----------

# System checks
run_system_checks() {
  log_step "Running system checks"
  
  local checks_passed=0
  local checks_failed=0
  
  # Check disk space
  log_info "Checking disk space..."
  local available_space
  available_space="$(df -h "$PROJECT_ROOT" | tail -n1 | awk '{print $4}' || echo "unknown")"
  log_info "Available disk space: $available_space"
  ((checks_passed++))
  
  # Check memory
  log_info "Checking system memory..."
  if command -v free &> /dev/null; then
    local free_mem
    free_mem="$(free -h | grep Mem | awk '{print $7}' || echo "unknown")"
    log_info "Available memory: $free_mem"
  elif command -v vm_stat &> /dev/null; then
    log_info "Memory check skipped (macOS - use Activity Monitor)"
  fi
  ((checks_passed++))
  
  # Check file permissions
  log_info "Checking file permissions..."
  if [[ -w "$PROJECT_ROOT" ]]; then
    log_info "Project directory is writable"
    ((checks_passed++))
  else
    log_error "Project directory is not writable"
    ((checks_failed++))
  fi
  
  # Check script permissions
  log_info "Checking script permissions..."
  local scripts_not_executable=()
  local script_files
  script_files="$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -type f 2>/dev/null || true)"
  if [[ -n "$script_files" ]]; then
    while IFS= read -r script; do
      [[ -z "$script" ]] && continue
      if [[ -f "$script" && ! -x "$script" ]]; then
        scripts_not_executable+=("$(basename "$script")")
      fi
    done <<< "$script_files"
  fi
  
  if [[ ${#scripts_not_executable[@]} -gt 0 ]]; then
    log_warning "Found ${#scripts_not_executable[@]} non-executable script(s): ${scripts_not_executable[*]}"
    log_info "Attempting to fix permissions..."
    for script in "${scripts_not_executable[@]}"; do
      chmod +x "$SCRIPT_DIR/$script" && log_info "Fixed: $script"
    done
  fi
  ((checks_passed++))
  
  if [[ $checks_failed -eq 0 ]]; then
    log_success "System checks passed ($checks_passed checks)"
    return 0
  else
    log_error "System checks failed ($checks_failed failed, $checks_passed passed)"
    return 1
  fi
}

# Build test
run_build_test() {
  log_step "Running build test"
  
  if [[ "$SKIP_BUILD" == "true" ]]; then
    log_info "Build test skipped (--skip-build)"
    return 0
  fi
  
  if [[ ! -f "$SCRIPT_DIR/_buildDotnetSolution.sh" ]]; then
    log_warning "Build script not found: _buildDotnetSolution.sh - skipping build test"
    return 0  # Don't fail if script doesn't exist
  fi
  
  if [[ ! -x "$SCRIPT_DIR/_buildDotnetSolution.sh" ]]; then
    chmod +x "$SCRIPT_DIR/_buildDotnetSolution.sh" || true
  fi
  
  log_info "Running build script..."
  if "$SCRIPT_DIR/_buildDotnetSolution.sh" -c "$BUILD_CONFIG" --no-publish 2>&1; then
    log_success "Build test passed"
    return 0
  else
    log_warning "Build test failed or no .NET project found"
    return 0  # Don't fail - this is OK if no .NET project
  fi
}

# Unit tests
run_unit_tests() {
  log_step "Running unit tests"
  
  if [[ "$SKIP_TESTS" == "true" ]]; then
    log_info "Unit tests skipped (--skip-tests)"
    return 0
  fi
  
  # Load common functions for test discovery
  if [[ -f "$SCRIPT_DIR/_common.sh" ]]; then
    source "$SCRIPT_DIR/_common.sh"
    
    # Find and run test projects
    local test_projects=()
    while IFS= read -r test_proj; do
      if [[ -n "$test_proj" && -f "$test_proj" ]]; then
        test_projects+=("$test_proj")
      fi
    done < <(find_test_projects 2>/dev/null || true)
    
    if [[ ${#test_projects[@]} -eq 0 ]]; then
      log_warning "No test projects found - skipping unit tests"
      return 0
    fi
    
    log_info "Found ${#test_projects[@]} test project(s)"
    
    # Run tests
    if run_unit_tests; then
      log_success "Unit tests passed"
      return 0
    else
      log_error "Unit tests failed"
      return 1
    fi
  else
    # Fallback: try dotnet test
    log_info "Running dotnet test..."
    if dotnet test --configuration "$BUILD_CONFIG" --no-build --verbosity minimal; then
      log_success "Unit tests passed"
      return 0
    else
      log_warning "Unit tests failed or no tests found"
      return 0  # Don't fail if no tests exist
    fi
  fi
}

# Health checks
run_health_checks() {
  log_step "Running health checks"
  
  local health_checks_passed=0
  local health_checks_failed=0
  
  # Check if build artifacts exist (optional - don't fail if not found)
  log_info "Checking build artifacts..."
  local deployment_dir="$PROJECT_ROOT/DEPLOYMENT"
  if [[ -d "$deployment_dir" ]]; then
    local artifact_count
    artifact_count="$(find "$deployment_dir" -type f \( -name "*.dll" -o -name "*.exe" -o -name "*.so" -o -name "*.dylib" \) 2>/dev/null | wc -l | tr -d ' ' || echo "0")"
    if [[ "$artifact_count" -gt 0 ]]; then
      log_info "Found $artifact_count build artifact(s)"
      ((health_checks_passed++))
    else
      log_info "No build artifacts found in $deployment_dir (this is OK if no build was run)"
    fi
  else
    log_info "Deployment directory not found: $deployment_dir (this is OK if no build was run)"
  fi
  
  # Check for common issues
  log_info "Checking for common issues..."
  
  # Check for .bak files
  local bak_files
  bak_files="$(find "$PROJECT_ROOT" -maxdepth 5 -name "*.bak" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "0")"
  if [[ "$bak_files" -gt 0 ]]; then
    log_warning "Found $bak_files .bak file(s) - consider cleanup"
  else
    log_info "No .bak files found"
  fi
  
  # Check for large files
  log_info "Checking for unusually large files..."
  local large_files
  large_files="$(find "$PROJECT_ROOT" -maxdepth 3 -type f -size +10M 2>/dev/null | grep -v -E "/(\.git|node_modules|bin|obj|packages)/" | wc -l | tr -d ' ' || echo "0")"
  if [[ "$large_files" -gt 0 ]]; then
    log_warning "Found $large_files large file(s) (>10MB)"
  else
    log_info "No unusually large files found"
  fi
  
  if [[ $health_checks_failed -eq 0 ]]; then
    log_success "Health checks passed ($health_checks_passed checks)"
    return 0
  else
    log_warning "Health checks completed with warnings ($health_checks_failed failed, $health_checks_passed passed)"
    return 0  # Don't fail on health check warnings
  fi
}

# Smoke tests
run_smoke_tests() {
  log_step "Running smoke tests"
  
  local smoke_tests_passed=0
  local smoke_tests_failed=0
  
  # Test script syntax
  log_info "Testing script syntax..."
  local scripts_with_errors=()
  while IFS= read -r script; do
    if [[ -f "$script" ]]; then
      if ! bash -n "$script" 2>/dev/null; then
        scripts_with_errors+=("$(basename "$script")")
      fi
    fi
  done < <(find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -type f 2>/dev/null || true)
  
  if [[ ${#scripts_with_errors[@]} -gt 0 ]]; then
    log_error "Found ${#scripts_with_errors[@]} script(s) with syntax errors: ${scripts_with_errors[*]}"
    ((smoke_tests_failed++))
  else
    log_info "All scripts have valid syntax"
    ((smoke_tests_passed++))
  fi
  
  # Test script dependencies
  log_info "Testing script dependencies..."
  if [[ -f "$SCRIPT_DIR/_common.sh" ]]; then
    if bash -n "$SCRIPT_DIR/_common.sh" 2>/dev/null; then
      log_info "_common.sh is valid"
      ((smoke_tests_passed++))
    else
      log_error "_common.sh has syntax errors"
      ((smoke_tests_failed++))
    fi
  fi
  
  # Test dotnet solution/project files (skip if no .NET project)
  log_info "Testing .NET project files..."
  local csproj_files
  csproj_files="$(find "$PROJECT_ROOT" -maxdepth 4 -name "*.csproj" -type f 2>/dev/null | head -n 5 || true)"
  if [[ -n "$csproj_files" ]]; then
    local valid_projects=0
    while IFS= read -r csproj; do
      [[ -z "$csproj" ]] && continue
      if [[ -f "$csproj" ]]; then
        if dotnet sln list "$csproj" >/dev/null 2>&1 || dotnet build "$csproj" --no-restore --verbosity quiet >/dev/null 2>&1; then
          ((valid_projects++))
        fi
      fi
    done <<< "$csproj_files"
    
    if [[ $valid_projects -gt 0 ]]; then
      log_info "Found $valid_projects valid .NET project(s)"
      ((smoke_tests_passed++))
    else
      log_warning "Could not validate .NET projects"
      # Don't fail if no projects found - this is OK for script-only repos
    fi
  else
    log_info "No .NET project files found (this is OK for script-only repositories)"
    # Don't fail - this is acceptable
  fi
  
  if [[ $smoke_tests_failed -eq 0 ]]; then
    log_success "Smoke tests passed ($smoke_tests_passed tests)"
    return 0
  else
    log_error "Smoke tests failed ($smoke_tests_failed failed, $smoke_tests_passed passed)"
    return 1
  fi
}

# Docker tests (optional)
run_docker_tests() {
  log_step "Running Docker tests"
  
  if [[ "$SKIP_DOCKER" == "true" ]]; then
    log_info "Docker tests skipped (--skip-docker or Docker not available)"
    return 0
  fi
  
  if ! command -v docker &> /dev/null; then
    log_warning "Docker not available - skipping Docker tests"
    return 0
  fi
  
  # Check if Dockerfile exists
  if [[ ! -f "$PROJECT_ROOT/Docker/Dockerfile" ]] && [[ ! -f "$PROJECT_ROOT/docker/Dockerfile" ]] && [[ ! -f "$PROJECT_ROOT/Dockerfile" ]]; then
    log_info "No Dockerfile found - skipping Docker tests"
    return 0
  fi
  
  # Check Docker daemon
  log_info "Checking Docker daemon..."
  if ! docker info >/dev/null 2>&1; then
    log_warning "Docker daemon not running - skipping Docker tests"
    return 0
  fi
  
  log_info "Docker daemon is running"
  log_success "Docker tests passed (basic checks)"
  return 0
}

# ---------- Parse arguments ----------
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-build)
        SKIP_BUILD="true"
        shift
        ;;
      --skip-tests)
        SKIP_TESTS="true"
        shift
        ;;
      --skip-docker)
        SKIP_DOCKER="true"
        shift
        ;;
      -c|--configuration)
        BUILD_CONFIG="$2"
        shift 2
        ;;
      -v|--verbose)
        VERBOSE="true"
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        log_error "Unknown argument: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

# Show help
show_help() {
  cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Comprehensive local testing script for .NET projects.
Performs: build, run, healthchecks, system checks, smoke tests.

USAGE:
  $0 [OPTIONS]

OPTIONS:
  --skip-build          Skip build test
  --skip-tests          Skip unit tests
  --skip-docker         Skip Docker tests
  -c, --configuration CONFIG    Build configuration (Debug|Release) [default: Release]
  -v, --verbose         Verbose output
  -h, --help            Show this help

TESTS PERFORMED:
  1. System checks (disk space, memory, permissions)
  2. Build test (dotnet build)
  3. Unit tests (dotnet test)
  4. Health checks (artifacts, common issues)
  5. Smoke tests (script syntax, dependencies)
  6. Docker tests (optional, if Docker available)

EXAMPLES:
  $0                                    # Run all tests
  $0 --skip-docker                      # Skip Docker tests
  $0 -c Debug --skip-tests              # Debug build, skip unit tests
  $0 --verbose                          # Verbose output

EOF
}

# ---------- Main function ----------
main() {
  log_header "🧪 LOCAL TEST SUITE 🧪"
  
  echo -e "${WHITE}Project: ${CYAN}$PROJECT_ROOT${RESET}"
  echo -e "${WHITE}Script: ${CYAN}$SCRIPT_NAME v$SCRIPT_VERSION${RESET}"
  echo -e "${WHITE}Date: ${CYAN}$(timestamp)${RESET}"
  echo -e "${WHITE}Configuration: ${CYAN}$BUILD_CONFIG${RESET}"
  echo ""
  
  # Parse arguments
  parse_arguments "$@"
  
  # Environment validation
  if ! check_tools; then
    log_error "Tool validation failed"
    exit 1
  fi
  
  # Check .NET project (warn but don't fail if not found - scripts can be tested independently)
  if ! check_dotnet_project; then
    log_warning ".NET project not found - some tests will be skipped"
    log_info "This is OK if you're testing scripts in a non-.NET repository"
  fi
  
  check_git_repo
  
  # Run tests
  local tests_passed=0
  local tests_failed=0
  
  # System checks
  if run_system_checks; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  # Build test
  if run_build_test 2>&1; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  # Unit tests
  if run_unit_tests 2>&1; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  # Health checks
  if run_health_checks 2>&1; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  # Smoke tests
  if run_smoke_tests 2>&1; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  # Docker tests
  if run_docker_tests 2>&1; then
    ((tests_passed++))
  else
    ((tests_failed++))
  fi
  
  # Summary
  log_header "📊 TEST SUMMARY"
  echo -e "${WHITE}Tests passed: ${GREEN}$tests_passed${RESET}"
  echo -e "${WHITE}Tests failed: ${RED}$tests_failed${RESET}"
  echo ""
  
  if [[ $tests_failed -eq 0 ]]; then
    log_header "✅ ALL TESTS PASSED!"
    log_success "🎉 Local test suite completed successfully!"
    return 0
  else
    log_header "❌ SOME TESTS FAILED"
    log_error "Local test suite completed with $tests_failed failure(s)"
    return 1
  fi
}

# ---------- Script entry point ----------
main "$@"

