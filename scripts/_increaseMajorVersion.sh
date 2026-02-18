#!/usr/bin/env zsh
# =============================================================================
# _increaseMajorVersion.sh
# =============================================================================
#
# Script to increase Major Version in project files.
# Works on macOS and supports:
# - ProjectOverride.json (if exists - only this file is modified)
# - *.csproj and *.props files (if ProjectOverride.json does not exist)
#
# Logic:
# 1. If ProjectOverride.json exists:
#    - Gets Major from this file
#    - Increases by 1
#    - Updates only ProjectOverride.json
# 2. If ProjectOverride.json does not exist:
#    - Finds all *.csproj and *.props files
#    - Gets the highest Major from these files
#    - Increases by 1
#    - Updates all *.csproj and *.props files
#
# =============================================================================

set -Euo pipefail
IFS=$'\n\t'

# Colors for output
if command -v tput >/dev/null 2>&1; then
  readonly RED="$(tput setaf 1)"
  readonly GREEN="$(tput setaf 2)"
  readonly YELLOW="$(tput setaf 3)"
  readonly BLUE="$(tput setaf 4)"
  readonly CYAN="$(tput setaf 6)"
  readonly WHITE="$(tput setaf 7)"
  readonly BOLD="$(tput bold)"
  readonly RESET="$(tput sgr0)"
else
  readonly RED="" GREEN="" YELLOW="" BLUE="" CYAN="" WHITE="" BOLD="" RESET=""
fi

# Paths
readonly SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly PROJECT_OVERRIDE_FILE="$PROJECT_ROOT/ProjectOverride.json"

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${RESET} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${RESET} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${RESET} $*" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${RESET} $*" >&2
}

log_step() {
  echo -e "\n${CYAN}🔧 $1${RESET}"
}

# Check if jq is available (for JSON parsing)
check_jq() {
  if command -v jq &> /dev/null; then
    return 0
  else
    log_warning "jq is not installed - using alternative JSON parsing method"
    return 1
  fi
}

# Pobierz Major z ProjectOverride.json
get_major_from_override() {
  local override_file="$1"
  
  if ! [[ -f "$override_file" ]]; then
    return 1
  fi
  
  if check_jq; then
    # Use jq to parse JSON
    local major
    major="$(jq -r '.Major // empty' "$override_file" 2>/dev/null || echo "")"
    if [[ -n "$major" && "$major" != "null" ]]; then
      echo "$major"
      return 0
    fi
  else
    # Alternative method without jq - use grep and sed
    local major
    major="$(grep -oE '"Major"[[:space:]]*:[[:space:]]*[0-9]+' "$override_file" 2>/dev/null | sed -E 's/.*:[[:space:]]*([0-9]+)/\1/' | head -n1 || echo "")"
    if [[ -n "$major" ]]; then
      echo "$major"
      return 0
    fi
  fi
  
  return 1
}

# Update Major in ProjectOverride.json
update_major_in_override() {
  local override_file="$1"
  local new_major="$2"
  
  if check_jq; then
    # Use jq to update JSON
    local temp_file
    temp_file="$(mktemp)"
    jq --arg major "$new_major" '.Major = ($major | tonumber)' "$override_file" > "$temp_file" 2>/dev/null
    if [[ $? -eq 0 ]]; then
      mv "$temp_file" "$override_file"
      return 0
    else
      rm -f "$temp_file"
      return 1
    fi
  else
    # Alternative method without jq - use sed
    # Format: "Major": number
    if sed -i.bak "s/\"Major\"[[:space:]]*:[[:space:]]*[0-9]\+/\"Major\": $new_major/g" "$override_file" 2>/dev/null; then
      # Remove .bak file if it was created
      rm -f "${override_file}.bak" 2>/dev/null || true
      return 0
    else
      return 1
    fi
  fi
}

# Get Major from XML file (.csproj or .props)
get_major_from_xml() {
  local xml_file="$1"
  
  if ! [[ -f "$xml_file" ]]; then
    return 1
  fi
  
  # Search for <Version>X.Y.Z...</Version> tag
  local version_line
  version_line="$(grep -E '<Version>[^<]+</Version>' "$xml_file" 2>/dev/null | head -n1 || echo "")"
  
  if [[ -z "$version_line" ]]; then
    return 1
  fi
  
  # Extract version (format: X.Y.Z.W or X.Y.Z+build)
  local version
  version="$(echo "$version_line" | sed -E 's/.*<Version>([^<]+)<\/Version>.*/\1/' | sed 's/+.*$//' | head -n1)"
  
  if [[ -z "$version" ]]; then
    return 1
  fi
  
  # Extract Major (first number before dot)
  local major
  major="$(echo "$version" | cut -d'.' -f1 | grep -oE '^[0-9]+' || echo "")"
  
  if [[ -n "$major" ]]; then
    echo "$major"
    return 0
  fi
  
  return 1
}

# Update Major in XML file (.csproj or .props)
update_major_in_xml() {
  local xml_file="$1"
  local new_major="$2"
  
  # Find all lines with <Version> and update Major
  # Format: <Version>X.Y.Z...</Version> -> <Version>NEW_MAJOR.Y.Z...</Version>
  local temp_file
  temp_file="$(mktemp)"
  
  # Use sed to replace Major in <Version> tags
  # Check if file contains <Version> tag
  if ! grep -qE '<Version>[^<]+</Version>' "$xml_file" 2>/dev/null; then
    rm -f "$temp_file"
    return 1
  fi
  
  # Perform replacement
  if sed -E "s/(<Version>)([0-9]+)(\.[0-9]+\.[0-9]+[^<]*)(<\/Version>)/\1${new_major}\3\4/g" "$xml_file" > "$temp_file" 2>/dev/null; then
    # Check if replacement was performed (compare number of lines with <Version>)
    local original_count
    local new_count
    original_count="$(grep -cE '<Version>[^<]+</Version>' "$xml_file" 2>/dev/null || echo "0")"
    new_count="$(grep -cE '<Version>[^<]+</Version>' "$temp_file" 2>/dev/null || echo "0")"
    
    if [[ "$original_count" -eq "$new_count" ]] && [[ "$original_count" -gt 0 ]]; then
      mv "$temp_file" "$xml_file"
      return 0
    else
      rm -f "$temp_file"
      return 1
    fi
  else
    rm -f "$temp_file"
    return 1
  fi
}

# Find highest Major in XML files
find_highest_major_in_xml_files() {
  local highest_major=0
  local files_found=false
  
  # Find all .csproj and .props files (exclude obj/ and bin/)
  local xml_files=()
  while IFS= read -r -d '' file; do
    # Pomiń pliki w katalogach obj/ i bin/
    if [[ "$file" =~ /(obj|bin)/ ]]; then
      continue
    fi
    xml_files+=("$file")
  done < <(find "$PROJECT_ROOT" -type f \( -name "*.csproj" -o -name "*.props" \) -print0 2>/dev/null || true)
  
  if (( ${#xml_files[@]} == 0 )); then
    log_error "No *.csproj or *.props files found in repository" >&2
    return 1
  fi
  
  log_info "Found ${#xml_files[@]} XML file(s) to analyze" >&2
  
  # Review each file and find highest Major
  for xml_file in "${xml_files[@]}"; do
    local major
    if major="$(get_major_from_xml "$xml_file" 2>/dev/null)"; then
      files_found=true
      log_info "  File: $(basename "$xml_file") - Major: $major" >&2
      if (( major > highest_major )); then
        highest_major=$major
      fi
    fi
  done
  
  if [[ "$files_found" == "false" ]]; then
    log_error "No version found in any XML files" >&2
    return 1
  fi
  
  # Return only the number (without logging)
  echo "$highest_major"
  return 0
}

# Main function
main() {
  log_step "Increasing Major Version"
  log_info "Project directory: $PROJECT_ROOT"
  
  local current_major=0
  local new_major=0
  
  # Check if ProjectOverride.json exists
  if [[ -f "$PROJECT_OVERRIDE_FILE" ]]; then
    log_info "Found ProjectOverride.json file"
    
    # Get Major from ProjectOverride.json
    if ! current_major="$(get_major_from_override "$PROJECT_OVERRIDE_FILE")"; then
      log_error "Cannot read Major from ProjectOverride.json"
      exit 1
    fi
    
    log_info "Current Major in ProjectOverride.json: $current_major"
    
    # Increase Major by 1
    new_major=$((current_major + 1))
    log_info "New Major: $new_major"
    
    # Update only ProjectOverride.json
    if ! update_major_in_override "$PROJECT_OVERRIDE_FILE" "$new_major"; then
      log_error "Cannot update Major in ProjectOverride.json"
      exit 1
    fi
    
    log_success "Updated Major in ProjectOverride.json: $current_major -> $new_major"
    
    # Finish - do not modify other files
    log_info "ProjectOverride.json exists - changes made only in this file"
    return 0
  else
    log_info "ProjectOverride.json file does not exist - searching in *.csproj and *.props files"
    
    # Find highest Major in XML files
    if ! current_major="$(find_highest_major_in_xml_files)"; then
      log_error "Cannot find Major in XML files"
      exit 1
    fi
    
    log_info "Highest Major in XML files: $current_major"
    
    # Increase Major by 1
    new_major=$((current_major + 1))
    log_info "New Major: $new_major"
    
    # Find all .csproj and .props files to update (exclude obj/ and bin/)
    local xml_files=()
    while IFS= read -r -d '' file; do
      # Skip files in obj/ and bin/ directories
      if [[ "$file" =~ /(obj|bin)/ ]]; then
        continue
      fi
      xml_files+=("$file")
    done < <(find "$PROJECT_ROOT" -type f \( -name "*.csproj" -o -name "*.props" \) -print0 2>/dev/null || true)
    
    if (( ${#xml_files[@]} == 0 )); then
      log_error "No *.csproj or *.props files found to update"
      exit 1
    fi
    
    log_info "Updating ${#xml_files[@]} XML file(s)..."
    
    # Update each file
    local updated_count=0
    local failed_count=0
    for xml_file in "${xml_files[@]}"; do
      # Check if file has <Version> tag
      if ! grep -qE '<Version>[^<]+</Version>' "$xml_file" 2>/dev/null; then
        log_info "  ⊘ Skipped (no <Version>): $(basename "$xml_file")"
        continue
      fi
      
      if update_major_in_xml "$xml_file" "$new_major"; then
        log_info "  ✓ Updated: $(basename "$xml_file")"
        ((updated_count++))
      else
        log_warning "  ✗ Cannot update: $(basename "$xml_file")"
        ((failed_count++))
      fi
    done
    
    if (( updated_count == 0 )); then
      log_error "Failed to update any file"
      exit 1
    fi
    
    log_success "Updated Major in $updated_count file(s): $current_major -> $new_major"
  fi
  
  # Save NewMajorNumber to variable (for compatibility with requirements)
  readonly NewMajorNumber="$new_major"
  
  log_success "Major Version increased: $current_major -> $new_major"
  log_info "NewMajorNumber = $NewMajorNumber"
  
  return 0
}

# Run main function
main "$@"

