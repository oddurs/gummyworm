#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/config.sh - Configuration and constants
# ============================================================================
# This module defines all default settings, constants, and global configuration
# for gummyworm. Source this first before other modules.
# ============================================================================

# Strict mode
set -euo pipefail

# Version info
readonly GUMMYWORM_VERSION="2.0.0"
readonly GUMMYWORM_NAME="gummyworm"

# Determine the root directory of the project
if [[ -z "${GUMMYWORM_ROOT:-}" ]]; then
    GUMMYWORM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
readonly GUMMYWORM_ROOT

# Directory structure
readonly GUMMYWORM_LIB_DIR="${GUMMYWORM_ROOT}/lib"
readonly GUMMYWORM_PALETTES_DIR="${GUMMYWORM_ROOT}/palettes"
readonly GUMMYWORM_BIN_DIR="${GUMMYWORM_ROOT}/bin"

# Default settings
readonly DEFAULT_WIDTH=80
readonly DEFAULT_HEIGHT=0  # 0 = auto-calculate from aspect ratio
readonly DEFAULT_PALETTE="standard"
readonly DEFAULT_INVERT=false
readonly DEFAULT_COLOR=false
readonly DEFAULT_OUTPUT=""
readonly DEFAULT_QUIET=false
readonly DEFAULT_PRESERVE_ASPECT=true

# ANSI color codes - bash 3.x compatible (no associative arrays)
COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_DIM="\033[2m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_CYAN="\033[36m"
COLOR_WHITE="\033[37m"

# Export for subshells
export GUMMYWORM_VERSION GUMMYWORM_NAME GUMMYWORM_ROOT
