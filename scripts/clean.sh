#!/usr/bin/env zsh
# =============================================================================
# Clean Script
# =============================================================================
# Wrapper for _clean.sh with user-friendly interface
# Usage: ./clean.sh [OPTIONS]
#
# Examples:
#   ./clean.sh           # Standard cleanup
#   ./clean.sh --deep    # Deep cleanup
#   ./clean.sh --all -y  # Clean everything without prompts
# =============================================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"

"$SCRIPT_DIR/_clean.sh" "$@"
