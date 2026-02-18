#!/usr/bin/env zsh
# Local publish script for macOS - Build, Clean, Deploy Versioner
# Based on _publishLocal.sh with enhanced reporting

set -Eeuo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="${TARGET_DIR:-/Users/anubis/Apps/Versioner}"
BUILD_DIR="$PROJECT_ROOT/DEPLOYMENT/net8.0"
PACKAGE_NAME="Versioner.macOS.zip"
PACKAGE_PATH="$PROJECT_ROOT/DEPLOYMENT/$PACKAGE_NAME"

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

log_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE} $1${PURPLE}${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

log_step() {
    echo -e "\n${BLUE}🔧 $1${NC}"
}

# Help function
show_help() {
    cat << EOF
Versioner Local Publish Script

Usage: $0 [OPTIONS]

OPTIONS:
    -t, --target DIR          Target directory [default: /Users/anubis/Apps/Versioner]
    -f, --force               Force installation (overwrite existing)
    -b, --build               Build before publishing
    -h, --help                Show this help message

EXAMPLES:
    $0                                    # Publish to default directory
    $0 -t /custom/path                    # Publish to custom directory
    $0 -f -b                              # Force publish with build

ENVIRONMENT VARIABLES:
    TARGET_DIR       Target directory (overrides -t)
EOF
}

# Parse command line arguments
parse_args() {
    FORCE=false
    BUILD=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--target)
                TARGET_DIR="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--build)
                BUILD=true
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
    
    # Check if we're in the right directory (check for project file or prop file instead of sln)
    if [[ ! -f "$PROJECT_ROOT/Directory.Build.props" && ! -d "$PROJECT_ROOT/Cli" ]]; then
        log_error "Project root not detected. Please run this script from the project root or scripts directory."
        exit 1
    fi
    
    # Check if unzip is available
    if ! command -v unzip &> /dev/null; then
        log_error "unzip is not installed or not in PATH"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Build Versioner if needed
build_versioner() {
    if [[ "$BUILD" == "true" ]]; then
        log_step "Building Versioner..."
        "$SCRIPT_DIR/_performBuildMacOS.sh"
        if [[ $? -eq 0 ]]; then
            log_success "Build completed successfully"
        else
            log_error "Build failed"
            exit 1
        fi
    fi
}

# Check if package exists
check_package() {
    log_step "Checking for build package..."
    
    if [[ -f "$PACKAGE_PATH" ]]; then
        local package_size
        package_size=$(du -sh "$PACKAGE_PATH" | cut -f1)
        log_success "Package found: $PACKAGE_NAME ($package_size)"
    else
        log_warning "Package not found: $PACKAGE_PATH"
        log_info "Building now..."
        "$SCRIPT_DIR/_performBuildMacOS.sh"
        
        if [[ -f "$PACKAGE_PATH" ]]; then
            local package_size
            package_size=$(du -sh "$PACKAGE_PATH" | cut -f1)
            log_success "Package created: $PACKAGE_NAME ($package_size)"
        else
            log_error "Failed to create package"
            exit 1
        fi
    fi
}

# Check target directory
check_target_directory() {
    log_step "Checking target directory..."
    
    if [[ -d "$TARGET_DIR" ]]; then
        local current_size
        current_size=$(du -sh "$TARGET_DIR" 2>/dev/null | cut -f1 || echo "N/A")
        local file_count
        file_count=$(find "$TARGET_DIR" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        
        log_info "Target directory exists: $TARGET_DIR"
        log_info "Current size: $current_size"
        log_info "File count: $file_count"
        
        if [[ $file_count -gt 0 ]]; then
            if [[ "$FORCE" == "true" ]]; then
                log_warning "Target directory is not empty - will be cleaned"
                
                # Show what will be removed
                echo -e "${YELLOW}Files to be removed:${NC}"
                ls -la "$TARGET_DIR" | head -10
                if [[ $file_count -gt 10 ]]; then
                    echo -e "${YELLOW}... and $((file_count - 10)) more files${NC}"
                fi
                
                # Clean target directory
                log_info "Cleaning target directory..."
                rm -rf "$TARGET_DIR"/*
                log_success "Target directory cleaned"
            else
                log_warning "Target directory is not empty"
                log_info "Use -f/--force to overwrite existing installation"
                exit 1
            fi
        else
            log_success "Target directory is empty"
        fi
    else
        log_info "Target directory does not exist - will be created"
        mkdir -p "$TARGET_DIR"
        log_success "Target directory created: $TARGET_DIR"
    fi
}

# Extract and deploy package
deploy_package() {
    log_step "Extracting and deploying package..."
    
    log_info "Extracting $PACKAGE_NAME to $TARGET_DIR"
    
    if unzip -o "$PACKAGE_PATH" -d "$TARGET_DIR"; then
        log_success "Package extracted successfully"
    else
        log_error "Package extraction failed!"
        exit 1
    fi
}

# Set permissions
set_permissions() {
    log_step "Setting permissions..."
    
    if [[ -f "$TARGET_DIR/Versioner.Cli" ]]; then
        chmod +x "$TARGET_DIR/Versioner.Cli"
        log_success "Executable permissions set for Versioner.Cli"
    else
        log_warning "Versioner.Cli not found - checking for .exe version"
        if [[ -f "$TARGET_DIR/Versioner.Cli.exe" ]]; then
            chmod +x "$TARGET_DIR/Versioner.Cli.exe"
            log_success "Executable permissions set for Versioner.Cli.exe"
        else
            log_warning "No Versioner executable found"
        fi
    fi
}

# Verify deployment
verify_deployment() {
    log_step "Verifying deployment..."
    
    local deployed_size
    deployed_size=$(du -sh "$TARGET_DIR" 2>/dev/null | cut -f1 || echo "N/A")
    local deployed_files
    deployed_files=$(find "$TARGET_DIR" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    
    log_success "Deployment completed successfully!"
    log_info "Deployed size: $deployed_size"
    log_info "Deployed files: $deployed_files"
    
    # Test executable if possible
    # if [[ -f "$TARGET_DIR/Versioner.Cli" ]]; then
    #     log_info "Testing Linux executable..."
    #     if "$TARGET_DIR/Versioner.Cli" --help >/dev/null 2>&1; then
    #         log_success "Versioner.Cli is working correctly"
    #     else
    #         log_warning "Versioner.Cli test failed (this might be normal if dependencies are missing)"
    #     fi
    # elif [[ -f "$TARGET_DIR/Versioner.Cli.exe" ]]; then
    #     log_info "Windows executable detected - cannot test on macOS"
    # else
    #     log_warning "No executable found for testing"
    # fi
    log_info "Skipping binary execution test to avoid hang on macOS"
}

# Generate deployment report
generate_report() {
    log_header "📊 DEPLOYMENT REPORT"
    
    local package_size
    package_size=$(du -sh "$PACKAGE_PATH" 2>/dev/null | cut -f1 || echo "N/A")
    local deployed_size
    deployed_size=$(du -sh "$TARGET_DIR" 2>/dev/null | cut -f1 || echo "N/A")
    local deployed_files
    deployed_files=$(find "$TARGET_DIR" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    
    echo -e "${WHITE}Target Directory: ${CYAN}$TARGET_DIR${NC}"
    echo -e "${WHITE}Package Source: ${CYAN}$PACKAGE_PATH${NC}"
    echo -e "${WHITE}Package Size: ${CYAN}$package_size${NC}"
    echo -e "${WHITE}Deployed Size: ${CYAN}$deployed_size${NC}"
    echo -e "${WHITE}Deployed Files: ${CYAN}$deployed_files${NC}"
    echo -e "${WHITE}Deployment Time: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    
    # Check for key files
    echo -e "\n${WHITE}Key Files Status:${NC}"
    if [[ -f "$TARGET_DIR/Versioner.Cli" ]]; then
        echo -e "${GREEN}  ✅ Versioner.Cli (Linux executable)${NC}"
    elif [[ -f "$TARGET_DIR/Versioner.Cli.exe" ]]; then
        echo -e "${GREEN}  ✅ Versioner.Cli.exe (Windows executable)${NC}"
    else
        echo -e "${RED}  ❌ No executable found${NC}"
    fi
    
    if [[ -f "$TARGET_DIR/README.md" ]]; then
        echo -e "${GREEN}  ✅ README.md${NC}"
    else
        echo -e "${YELLOW}  ⚠️  README.md not found${NC}"
    fi
    
    if [[ -d "$TARGET_DIR/Scripts" ]]; then
        local script_count
        script_count=$(find "$TARGET_DIR/Scripts" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        echo -e "${GREEN}  ✅ Scripts directory ($script_count files)${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Scripts directory not found${NC}"
    fi
}

# Main publish process
main() {
    log_header "🚀 VERSIONER LOCAL PUBLISH SCRIPT FOR MACOS 🚀"
    echo -e "${WHITE}Project Root: ${CYAN}$PROJECT_ROOT${NC}"
    echo -e "${WHITE}Script Directory: ${CYAN}$SCRIPT_DIR${NC}"
    echo -e "${WHITE}Target Directory: ${CYAN}$TARGET_DIR${NC}"
    echo -e "${WHITE}Build Directory: ${CYAN}$BUILD_DIR${NC}"
    echo -e "${WHITE}Package Name: ${CYAN}$PACKAGE_NAME${NC}"
    echo -e "${WHITE}Timestamp: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    
    # Parse arguments
    parse_args "$@"
    
    # Validate environment
    validate_environment
    
    # Build if requested
    build_versioner
    
    # Check if package exists
    check_package
    
    # Check target directory
    check_target_directory
    
    # Deploy package
    deploy_package
    
    # Set permissions
    set_permissions
    
    # Verify deployment
    verify_deployment
    
    # Generate report
    generate_report
    
    log_success "Local publish completed successfully!"
    echo -e "${WHITE}Versioner is now available at: ${CYAN}$TARGET_DIR${NC}"
    echo -e "${WHITE}You can now use the versioning scripts in your projects.${NC}"
    
    # Cleanup suggestion
    log_info "You may want to clean up the build directory:"
    echo -e "${CYAN}  rm -rf $BUILD_DIR${NC}"
    
    log_header "🚀 READY TO USE! 🚀"
}

# Run main function with all arguments
main "$@"
