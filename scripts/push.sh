#!/usr/bin/env zsh
# Git push script for Versioner project

set -Eeuo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-}"
BRANCH="${BRANCH:-}"
REMOTE="${REMOTE:-origin}"
PUSH_TAGS="${PUSH_TAGS:-false}"
FORCE="${FORCE:-false}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Versioner Git Push Script

Usage: $0 [OPTIONS]

OPTIONS:
    -m, --message MESSAGE     Commit message [default: auto-generated]
    -b, --branch BRANCH       Branch to push [default: current branch]
    -r, --remote REMOTE       Remote repository [default: origin]
    -t, --tags                Push tags
    -f, --force               Force push
    -h, --help                Show this help message

EXAMPLES:
    $0                                    # Push current branch with auto message
    $0 -m "Fix versioning bug"            # Push with custom message
    $0 -b main -r upstream                # Push main branch to upstream
    $0 -t                                 # Push current branch and tags

ENVIRONMENT VARIABLES:
    COMMIT_MESSAGE    Commit message (overrides -m)
    BRANCH           Branch to push (overrides -b)
    REMOTE           Remote repository (overrides -r)
    PUSH_TAGS        Push tags flag (overrides -t)
    FORCE            Force push flag (overrides -f)
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--message)
                COMMIT_MESSAGE="$2"
                shift 2
                ;;
            -b|--branch)
                BRANCH="$2"
                shift 2
                ;;
            -r|--remote)
                REMOTE="$2"
                shift 2
                ;;
            -t|--tags)
                PUSH_TAGS="true"
                shift
                ;;
            -f|--force)
                FORCE="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Validate environment
validate_environment() {
    log_info "Validating environment..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed or not in PATH"
        exit 1
    fi
    
    # Get current branch if not specified
    if [[ -z "$BRANCH" ]]; then
        BRANCH=$(git branch --show-current)
        if [[ -z "$BRANCH" ]]; then
            log_error "Could not determine current branch"
            exit 1
        fi
    fi
    
    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        log_error "Branch '$BRANCH' does not exist"
        exit 1
    fi
    
    # Check if remote exists
    if ! git remote get-url "$REMOTE" &> /dev/null; then
        log_error "Remote '$REMOTE' does not exist"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Check git status
check_git_status() {
    log_info "Checking git status..."
    
    # Check if there are any changes
    if git diff --quiet && git diff --cached --quiet; then
        log_warning "No changes to commit"
        return 1
    fi
    
    # Show status
    log_info "Git status:"
    git status --short
    
    return 0
}

# Generate commit message
generate_commit_message() {
    if [[ -n "$COMMIT_MESSAGE" ]]; then
        echo "$COMMIT_MESSAGE"
        return
    fi
    
    # Generate timestamp
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get git hash
    local git_hash
    git_hash=$(git rev-parse --short HEAD)
    
    # Generate message
    echo "Versioner: Update at $timestamp ($git_hash)"
}

# Add and commit changes
commit_changes() {
    local message="$1"
    
    log_info "Adding changes..."
    git add .
    
    log_info "Committing changes..."
    git commit -m "$message"
    
    if [[ $? -eq 0 ]]; then
        log_success "Changes committed successfully"
    else
        log_error "Failed to commit changes"
        exit 1
    fi
}

# Push changes
push_changes() {
    log_info "Pushing changes..."
    log_info "Branch: $BRANCH"
    log_info "Remote: $REMOTE"
    log_info "Force: $FORCE"
    
    # Prepare push command
    local push_cmd=("git" "push")
    
    if [[ "$FORCE" == "true" ]]; then
        push_cmd+=("--force")
    fi
    
    push_cmd+=("$REMOTE" "$BRANCH")
    
    # Execute push
    log_info "Executing: ${push_cmd[*]}"
    "${push_cmd[@]}"
    
    if [[ $? -eq 0 ]]; then
        log_success "Changes pushed successfully"
    else
        log_error "Failed to push changes"
        exit 1
    fi
}

# Push tags
push_tags() {
    if [[ "$PUSH_TAGS" == "true" ]]; then
        log_info "Pushing tags..."
        
        git push "$REMOTE" --tags
        
        if [[ $? -eq 0 ]]; then
            log_success "Tags pushed successfully"
        else
            log_error "Failed to push tags"
            exit 1
        fi
    fi
}

# Show push information
show_push_info() {
    log_info "Push information:"
    echo "  Branch: $BRANCH"
    echo "  Remote: $REMOTE"
    echo "  Remote URL: $(git remote get-url "$REMOTE")"
    echo "  Last commit: $(git log -1 --oneline)"
    
    if [[ "$PUSH_TAGS" == "true" ]]; then
        echo "  Tags: $(git tag --list | tail -5 | tr '\n' ' ')"
    fi
}

# Main push process
main() {
    log_info "Starting Git push process..."
    log_info "Project root: $PROJECT_ROOT"
    log_info "Script directory: $SCRIPT_DIR"
    
    # Parse arguments
    parse_args "$@"
    
    # Validate environment
    validate_environment
    
    # Check git status
    if ! check_git_status; then
        log_info "No changes to push"
        exit 0
    fi
    
    # Generate commit message
    local message
    message=$(generate_commit_message)
    log_info "Commit message: $message"
    
    # Commit changes
    commit_changes "$message"
    
    # Push changes
    push_changes
    
    # Push tags
    push_tags
    
    # Show push info
    show_push_info
    
    log_success "Git push process completed successfully!"
}

# Run main function with all arguments
main "$@"
