#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/config.sh - Configuration and constants
# ============================================================================
# This module defines all default settings, constants, and global configuration
# for gummyworm. Source this first before other modules.
#
# Compatibility: Bash 3.2+, zsh 5.0+ (macOS default), GNU/Linux, BSD
# ============================================================================

# ============================================================================
# Shell Detection & Compatibility Layer
# ============================================================================
# Detect shell type and set up compatibility options BEFORE strict mode.
# This must be done first to ensure arrays and other features work correctly.

# Detect current shell
_GUMMYWORM_SHELL="unknown"
if [[ -n "${BASH_VERSION:-}" ]]; then
    _GUMMYWORM_SHELL="bash"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    _GUMMYWORM_SHELL="zsh"
fi
readonly _GUMMYWORM_SHELL

# Shell detection helpers
_is_bash() { [[ "$_GUMMYWORM_SHELL" == "bash" ]]; }
_is_zsh() { [[ "$_GUMMYWORM_SHELL" == "zsh" ]]; }

# zsh compatibility setup - must happen before any array operations
if _is_zsh; then
    # KSH_ARRAYS: Use 0-indexed arrays like bash (zsh default is 1-indexed)
    setopt KSH_ARRAYS 2>/dev/null || true
    # SH_WORD_SPLIT: Split unquoted variable expansions like bash
    setopt SH_WORD_SPLIT 2>/dev/null || true
    # NO_NOMATCH: Don't error on failed glob patterns (like bash default)
    setopt NO_NOMATCH 2>/dev/null || true
    # POSIX_BUILTINS: More bash-like builtin behavior
    setopt POSIX_BUILTINS 2>/dev/null || true
fi

# Strict mode (portable across bash/zsh)
set -e  # Exit on error
set -u  # Error on undefined variables
# pipefail: bash uses set -o, zsh can use setopt
set -o pipefail 2>/dev/null || { _is_zsh && setopt PIPE_FAIL 2>/dev/null; } || true

# ============================================================================
# Shell Version Validation
# ============================================================================

if _is_bash; then
    # Check for minimum Bash version (3.2)
    if [[ -z "${BASH_VERSINFO:-}" ]] || [[ "${BASH_VERSINFO[0]}" -lt 3 ]] || \
       { [[ "${BASH_VERSINFO[0]}" -eq 3 ]] && [[ "${BASH_VERSINFO[1]}" -lt 2 ]]; }; then
        echo "Error: gummyworm requires Bash 3.2 or later" >&2
        echo "Current Bash version: ${BASH_VERSION:-unknown}" >&2
        exit 1
    fi
elif _is_zsh; then
    # Check for minimum zsh version (5.0)
    # ZSH_VERSION format: "5.8.1" - extract major version
    _zsh_major="${ZSH_VERSION%%.*}"
    if [[ "$_zsh_major" -lt 5 ]]; then
        echo "Error: gummyworm requires zsh 5.0 or later" >&2
        echo "Current zsh version: ${ZSH_VERSION:-unknown}" >&2
        exit 1
    fi
    unset _zsh_major
else
    echo "Error: gummyworm requires Bash 3.2+ or zsh 5.0+" >&2
    echo "Current shell: unknown" >&2
    exit 1
fi

# ============================================================================
# Portable Script Path Detection
# ============================================================================
# Get the directory of the current script, portable across bash and zsh.
# Usage: _script_dir  (call from within the script needing its location)

_script_source() {
    if _is_bash; then
        echo "${BASH_SOURCE[1]:-${BASH_SOURCE[0]:-$0}}"
    elif _is_zsh; then
        # In zsh, use %x parameter expansion for script path
        # shellcheck disable=SC2154
        echo "${(%):-%x}"
    else
        echo "$0"
    fi
}

# Detect platform for OS-specific workarounds
GUMMYWORM_PLATFORM="unknown"
case "$(uname -s)" in
    Darwin*)  GUMMYWORM_PLATFORM="macos" ;;
    Linux*)   GUMMYWORM_PLATFORM="linux" ;;
    FreeBSD*) GUMMYWORM_PLATFORM="freebsd" ;;
    CYGWIN*|MINGW*|MSYS*) GUMMYWORM_PLATFORM="windows" ;;
    *)        GUMMYWORM_PLATFORM="unknown" ;;
esac
export GUMMYWORM_PLATFORM

# Version info
readonly GUMMYWORM_VERSION="2.1.1"
readonly GUMMYWORM_NAME="gummyworm"

# Determine the root directory of the project (portable across bash/zsh)
if [[ -z "${GUMMYWORM_ROOT:-}" ]]; then
    # Use portable script source detection
    _config_script="$(_script_source)"
    GUMMYWORM_ROOT="$(cd "$(dirname "$_config_script")/.." && pwd)"
    unset _config_script
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
readonly DEFAULT_TRUECOLOR=false
readonly DEFAULT_OUTPUT=""
readonly DEFAULT_QUIET=false
readonly DEFAULT_PRESERVE_ASPECT=true
readonly DEFAULT_FORMAT="text"
readonly DEFAULT_BACKGROUND="#1e1e1e"
readonly DEFAULT_PADDING=0

# Image preprocessing defaults (neutral values = no change)
readonly DEFAULT_BRIGHTNESS=0    # Range: -100 to +100
readonly DEFAULT_CONTRAST=0      # Range: -100 to +100
readonly DEFAULT_GAMMA="1.0"     # Range: 0.1 to 10.0 (1.0 = no change)

# Animation defaults
readonly DEFAULT_ANIMATE="auto"  # auto, true, false
readonly DEFAULT_FRAME_DELAY=100  # milliseconds between frames (for playback)
readonly DEFAULT_MAX_FRAMES=0     # 0 = no limit
readonly DEFAULT_LOOPS=0          # 0 = infinite loop for playback

# ============================================================================
# User Configuration File Support
# ============================================================================
# Config files are loaded in order (later files override earlier):
#   1. ~/.config/gummyworm/config  (XDG style)
#   2. ~/.gummywormrc              (home directory)
#   3. ./.gummywormrc              (current directory - project specific)
#
# Format: Simple shell variable assignments (one per line)
#   width=120
#   palette=blocks
#   color=true

# User-configurable settings (can be overridden by config file, then CLI)
CONFIG_WIDTH="$DEFAULT_WIDTH"
CONFIG_HEIGHT="$DEFAULT_HEIGHT"
CONFIG_PALETTE="$DEFAULT_PALETTE"
CONFIG_INVERT="$DEFAULT_INVERT"
CONFIG_COLOR="$DEFAULT_COLOR"
CONFIG_TRUECOLOR="$DEFAULT_TRUECOLOR"
CONFIG_FORMAT="$DEFAULT_FORMAT"
CONFIG_BACKGROUND="$DEFAULT_BACKGROUND"
CONFIG_PADDING="$DEFAULT_PADDING"
CONFIG_BRIGHTNESS="$DEFAULT_BRIGHTNESS"
CONFIG_CONTRAST="$DEFAULT_CONTRAST"
CONFIG_GAMMA="$DEFAULT_GAMMA"
CONFIG_ANIMATE="$DEFAULT_ANIMATE"
CONFIG_FRAME_DELAY="$DEFAULT_FRAME_DELAY"
CONFIG_MAX_FRAMES="$DEFAULT_MAX_FRAMES"
CONFIG_LOOPS="$DEFAULT_LOOPS"
CONFIG_QUIET="$DEFAULT_QUIET"
CONFIG_PRESERVE_ASPECT="$DEFAULT_PRESERVE_ASPECT"

# Load a config file if it exists
# Usage: _load_config_file "/path/to/config"
_load_config_file() {
    local config_file="$1"
    [[ -f "$config_file" ]] || return 0

    local line key value
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Parse key=value (trim whitespace)
        if [[ "$line" =~ ^[[:space:]]*([a-z_]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"

            # Remove surrounding quotes if present
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"

            # Map config keys to CONFIG_* variables
            case "$key" in
                width)           CONFIG_WIDTH="$value" ;;
                height)          CONFIG_HEIGHT="$value" ;;
                palette)         CONFIG_PALETTE="$value" ;;
                invert)          CONFIG_INVERT="$value" ;;
                color)           CONFIG_COLOR="$value" ;;
                truecolor)       CONFIG_TRUECOLOR="$value" ;;
                format)          CONFIG_FORMAT="$value" ;;
                background)      CONFIG_BACKGROUND="$value" ;;
                padding)         CONFIG_PADDING="$value" ;;
                brightness)      CONFIG_BRIGHTNESS="$value" ;;
                contrast)        CONFIG_CONTRAST="$value" ;;
                gamma)           CONFIG_GAMMA="$value" ;;
                animate)         CONFIG_ANIMATE="$value" ;;
                frame_delay)     CONFIG_FRAME_DELAY="$value" ;;
                max_frames)      CONFIG_MAX_FRAMES="$value" ;;
                loops)           CONFIG_LOOPS="$value" ;;
                quiet)           CONFIG_QUIET="$value" ;;
                preserve_aspect) CONFIG_PRESERVE_ASPECT="$value" ;;
            esac
        fi
    done < "$config_file"
}

# Load config files in order (later overrides earlier)
_load_config_file "${XDG_CONFIG_HOME:-$HOME/.config}/gummyworm/config"
_load_config_file "$HOME/.gummywormrc"
_load_config_file ".gummywormrc"

# Export config values for use by other modules
export CONFIG_WIDTH CONFIG_HEIGHT CONFIG_PALETTE CONFIG_INVERT
export CONFIG_COLOR CONFIG_TRUECOLOR CONFIG_FORMAT CONFIG_BACKGROUND
export CONFIG_PADDING CONFIG_BRIGHTNESS CONFIG_CONTRAST CONFIG_GAMMA
export CONFIG_ANIMATE CONFIG_FRAME_DELAY CONFIG_MAX_FRAMES CONFIG_LOOPS
export CONFIG_QUIET CONFIG_PRESERVE_ASPECT

# ============================================================================
# Shared Regex Patterns (Bash 3.2 compatible - stored in variables)
# ============================================================================

# URL pattern for detecting remote resources
readonly RE_URL='^https?://'

# Numeric patterns for argument validation
readonly RE_INTEGER='^[0-9]+$'

# Export format patterns
readonly RE_GRAPHICAL_FORMAT='^(html|svg|png)$'
readonly RE_TEXT_FORMAT='^(text|ansi)$'

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
