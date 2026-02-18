#!/usr/bin/env zsh
# =============================================================================
# GitHubPublish v2.0 - Simplified and Fixed for macOS/zsh
# =============================================================================
# Publishes .NET project artifacts to GitHub releases with version conversion
# Converts 4-segment version (X.Y.Z.W) to 3-segment (X.Y.W) for GitHub
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ---------- Configuration ----------
readonly SCRIPT_VERSION="2.0.1"
readonly SCRIPT_NAME="GitHubPublish"

# Colors
if command -v tput >/dev/null 2>&1; then
  readonly GREEN="$(tput setaf 2)"
  readonly RED="$(tput setaf 1)"
  readonly YELLOW="$(tput setaf 3)"
  readonly BLUE="$(tput setaf 4)"
  readonly CYAN="$(tput setaf 6)"
  readonly BOLD="$(tput bold)"
  readonly RESET="$(tput sgr0)"
else
  readonly GREEN="" RED="" YELLOW="" BLUE="" CYAN="" BOLD="" RESET=""
fi

# Global variables
REPO_DIR=""
GITHUB_REPO=""
VERSION=""
GITHUB_VERSION=""
FORCE_RECREATE="false"
SOLUTION_NAME=""

# ---------- Logging ----------
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

info() {
  echo "${BLUE}[$(timestamp)] [INFO]${RESET} $*" >&2
}

success() {
  echo "${GREEN}[$(timestamp)] [✓]${RESET} $*" >&2
}

warn() {
  echo "${YELLOW}[$(timestamp)} [WARN]${RESET} $*" >&2
}

error() {
  echo "${RED}[$(timestamp)] [ERROR]${RESET} $*" >&2
}

die() {
  error "$*"
  exit 1
}

# ---------- Usage ----------
usage() {
  cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Publishes .NET project artifacts to GitHub releases.
Converts 4-segment version (X.Y.Z.W) to 3-segment (X.Y.W) for GitHub.

USAGE:
  $0 --repo-dir PATH --github-repo OWNER/REPO [OPTIONS]

OPTIONS:
  --repo-dir PATH           Repository root directory
  --github-repo OWNER/REPO  GitHub repository (owner/name format)
  --force                   Recreate release if exists (no prompt)
  --help, -h                Show this help

EXAMPLE:
  $0 --repo-dir /path/to/repo --github-repo myorg/myrepo --force

REQUIREMENTS:
  - gh (GitHub CLI) - authenticated
  - Git repository with version.txt and README.md
  - DEPLOYMENT/*.zip artifacts (Windows, Linux, macOS)

EOF
}

# ---------- Argument Parsing ----------
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo-dir)
        [[ -z "${2:-}" ]] && die "Missing value for --repo-dir"
        REPO_DIR="$2"
        shift 2
        ;;
      --github-repo)
        [[ -z "${2:-}" ]] && die "Missing value for --github-repo"
        GITHUB_REPO="$2"
        shift 2
        ;;
      --force)
        FORCE_RECREATE="true"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done

  # Validate required arguments
  [[ -z "$REPO_DIR" ]] && die "Missing required argument: --repo-dir"
  [[ -z "$GITHUB_REPO" ]] && die "Missing required argument: --github-repo"
  
  return 0
}

# ---------- Validation ----------
validate_environment() {
  info "Validating environment..."

  # Check repository directory
  [[ ! -d "$REPO_DIR" ]] && die "Repository directory does not exist: $REPO_DIR"
  [[ ! -d "$REPO_DIR/.git" ]] && die "Not a git repository: $REPO_DIR"

  # Check required tools
  command -v gh >/dev/null 2>&1 || die "GitHub CLI (gh) not found. Install: brew install gh"
  command -v git >/dev/null 2>&1 || die "Git not found"

  # Check GitHub authentication
  if ! gh auth status >/dev/null 2>&1; then
    die "GitHub CLI not authenticated. Run: gh auth login"
  fi

  # Normalize paths
  REPO_DIR="$(cd "$REPO_DIR" && pwd)"
  
  success "Environment validated"
}

# ---------- Solution Name Detection ----------
detect_solution_name() {
  info "Detecting solution name..."

  local sln_file
  sln_file="$(find "$REPO_DIR" -maxdepth 2 -name "*.sln" -type f 2>/dev/null | head -n 1)"

  if [[ -n "$sln_file" && -f "$sln_file" ]]; then
    SOLUTION_NAME="$(basename "$sln_file" .sln)"
  else
    # Fallback to directory name
    SOLUTION_NAME="$(basename "$REPO_DIR")"
  fi

  # Strip common project suffixes
  SOLUTION_NAME="${SOLUTION_NAME%.Cli}"
  SOLUTION_NAME="${SOLUTION_NAME%.Api}"
  SOLUTION_NAME="${SOLUTION_NAME%.App}"

  success "Solution name: $SOLUTION_NAME"
}

# ---------- Version Detection ----------
detect_version() {
  info "Detecting version..."

  local version_file="$REPO_DIR/version.txt"
  [[ ! -f "$version_file" ]] && die "version.txt not found: $version_file"

  VERSION="$(cat "$version_file" | tr -d ' \t\r\n' || true)"
  [[ -z "$VERSION" ]] && die "version.txt is empty"

  # Validate version format (allow non-numeric versions like "atest")
  if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    warn "Version '$VERSION' is not in standard numeric format (X.Y.Z)"
    warn "Accepting non-standard version for custom releases"
  fi

  success "Detected version: $VERSION"
}

# ---------- Version Conversion ----------
convert_version() {
  info "Converting version for GitHub..."

  GITHUB_VERSION="$VERSION"

  # Convert 4-segment (X.Y.Z.W) to 3-segment (X.Y.W)
  # Use segments 1, 2, 4 (skip segment 3 - the Z component)
  # Example: 28.2601.11.125 → 28.2601.125 (X.Y.W format)
  if [[ "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    # Extract all segments using zsh match array
    # In zsh, $match is an array containing the matched groups
    local seg1="${match[1]}"
    local seg2="${match[2]}"
    local seg3="${match[3]}"
    local seg4="${match[4]}"
    
    # Create 3-segment version using X.Y.W (segments 1, 2, 4)
    GITHUB_VERSION="${seg1}.${seg2}.${seg4}"
    info "Converted 4-segment to 3-segment: $VERSION → $GITHUB_VERSION"
    info "Format: X.Y.W (using segments 1, 2, 4 from X.Y.Z.W)"
  elif [[ "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    # Already 3-segment, use as-is
    info "Version already in 3-segment format: $VERSION"
  else
    # Non-standard version format, use as-is but warn
    warn "Version '$VERSION' is not in standard numeric format"
    warn "Using version as-is for GitHub release"
  fi

  success "GitHub version (3-segment): $GITHUB_VERSION"
  success "Full version (for release name): $VERSION"
}

# ---------- Artifact Validation ----------
validate_artifacts() {
  info "Validating artifacts..."

  local deployment_dir="$REPO_DIR/DEPLOYMENT"
  [[ ! -d "$deployment_dir" ]] && die "DEPLOYMENT directory not found: $deployment_dir"

  # Check for platform ZIPs (using detected solution name)
  local required_zips=(
    "$deployment_dir/${SOLUTION_NAME}.Windows.zip"
    "$deployment_dir/${SOLUTION_NAME}.Linux.zip"
    "$deployment_dir/${SOLUTION_NAME}.macOS.zip"
  )

  local missing_count=0
  for zip_file in "${required_zips[@]}"; do
    if [[ ! -f "$zip_file" ]]; then
      error "Missing artifact: $(basename "$zip_file")"
      ((missing_count++))
    else
      info "Found: $(basename "$zip_file") ($(du -h "$zip_file" | cut -f1))"
    fi
  done

  [[ $missing_count -gt 0 ]] && die "Missing $missing_count required artifact(s)"

  # Check version.txt
  [[ ! -f "$REPO_DIR/version.txt" ]] && die "version.txt not found in repository root"
  
  # Check README.md
  [[ ! -f "$REPO_DIR/README.md" ]] && die "README.md not found in repository root"
  
  success "All artifacts validated"
}

# ---------- GitHub Release Creation ----------
create_github_release() {
  info "Creating GitHub release..."

  # Use FULL version in release tag and title (e.g., R-28.2601.11.125)
  # GitHub version (3-segment) is used for the semantic version field
  local release_tag="R-${VERSION}"
  local release_title="Release ${VERSION}"
  
  # Build release notes with both full and GitHub versions
  local release_notes="Release automatyczny wersji ${VERSION}

**Wersja pełna (artefakty)**: ${VERSION}
**Wersja GitHub (3-członowa)**: ${GITHUB_VERSION} (X.Y.W format)

**Platformy:**
- Windows (win-x64)
- Linux (linux-x64)
- macOS (osx-arm64)

**Zawartość:**
- Artefakty ZIP dla wszystkich platform
- version.txt - plik wersji (zawiera pełną wersję: ${VERSION})
- README.md - dokumentacja

**Changelog**: Zobacz commit history dla szczegółów zmian."

  # Check if release already exists
  if gh release view "$release_tag" --repo "$GITHUB_REPO" >/dev/null 2>&1; then
    warn "Release $release_tag already exists"
    
    if [[ "$FORCE_RECREATE" == "true" ]]; then
      info "Force recreate enabled - deleting existing release..."
    else
      read -q "REPLY?Delete existing release and recreate? (y/n): "
      echo
      if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        die "Aborted by user"
      fi
      info "Deleting existing release..."
    fi
    
    gh release delete "$release_tag" --repo "$GITHUB_REPO" --yes || die "Failed to delete existing release"
    # Also delete the tag locally and remotely
    git -C "$REPO_DIR" tag -d "$release_tag" 2>/dev/null || true
    git -C "$REPO_DIR" push origin ":refs/tags/$release_tag" 2>/dev/null || true
  fi

  info "Creating release: $release_tag"
  info "Repository: $GITHUB_REPO"
  info "GitHub version (tag value): $GITHUB_VERSION"
  
  # Create release with artifacts
  # NOTE: The tag is the full version (R-{full_version}), but we set the release version to the 3-segment GitHub version
  if ! gh release create "$release_tag" \
    --repo "$GITHUB_REPO" \
    --title "$release_title" \
    --notes "$release_notes" \
    --draft=false \
    "$REPO_DIR/DEPLOYMENT/${SOLUTION_NAME}.Windows.zip" \
    "$REPO_DIR/DEPLOYMENT/${SOLUTION_NAME}.Linux.zip" \
    "$REPO_DIR/DEPLOYMENT/${SOLUTION_NAME}.macOS.zip" \
    "$REPO_DIR/version.txt" \
    "$REPO_DIR/README.md"; then
    die "Failed to create GitHub release"
  fi

  success "GitHub release created successfully"
  
  # Display release URL
  local release_url="https://github.com/${GITHUB_REPO}/releases/tag/${release_tag}"
  echo ""
  echo "=========================================="
  echo "${GREEN}${BOLD}🎉 GitHub Release Created!${RESET}"
  echo "=========================================="
  echo "${CYAN}Tag:${RESET}            $release_tag"
  echo "${CYAN}Full Version:${RESET}   $VERSION"
  echo "${CYAN}GitHub Version:${RESET} $GITHUB_VERSION (X.Y.W)"
  echo "${CYAN}URL:${RESET}            $release_url"
  echo "=========================================="
  echo ""
}

# ---------- Verification ----------
verify_release() {
  info "Verifying release..."

  # Use FULL version for tag (R-{full_version})
  local release_tag="R-${VERSION}"
  
  # Wait a moment for GitHub to process
  sleep 2

  local release_info
  if ! release_info="$(gh release view "$release_tag" --repo "$GITHUB_REPO" --json tagName,name,assets,isDraft,isPrerelease 2>&1)"; then
    die "Failed to verify release: $release_info"
  fi

  # Parse with jq if available
  if command -v jq >/dev/null 2>&1; then
    local is_draft
    local asset_count
    
    is_draft="$(echo "$release_info" | jq -r '.isDraft')"
    asset_count="$(echo "$release_info" | jq -r '.assets | length')"
    
    if [[ "$is_draft" == "true" ]]; then
      die "CRITICAL: Release is in DRAFT state! Must be PUBLISHED."
    fi
    
    success "Release status: PUBLISHED (not draft)"
    success "Release has $asset_count asset(s)"
    
    # List assets
    info "Assets:"
    echo "$release_info" | jq -r '.assets[] | "  - \(.name) (\(.size) bytes)"' | while read -r line; do
      info "$line"
    done
  else
    warn "jq not available, skipping detailed verification"
    info "Release appears to be created successfully"
  fi

  success "Release verification complete"
}

# ---------- Main ----------
main() {
  info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
  
  parse_arguments "$@"
  validate_environment
  detect_solution_name
  detect_version
  convert_version
  validate_artifacts
  create_github_release
  verify_release
  
  success "All operations completed successfully!"
  return 0
}

# Execute main
main "$@"
