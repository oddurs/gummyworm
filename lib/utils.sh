#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/utils.sh - Utility functions
# ============================================================================
# Common utility functions for logging, output formatting, and error handling.
# Requires: lib/config.sh
# ============================================================================

# Guard against multiple inclusion
[[ -n "${_GUMMYWORM_UTILS_LOADED:-}" ]] && return 0
readonly _GUMMYWORM_UTILS_LOADED=1

# ============================================================================
# Logging Functions
# ============================================================================

# Print colored output
# Usage: print_color <color> <message>
print_color() {
    local color="$1"
    shift
    echo -e "${COLORS[$color]:-}$*${COLORS[reset]}"
}

# Print error message to stderr
# Usage: log_error <message>
log_error() {
    echo -e "${COLORS[red]}✖ Error:${COLORS[reset]} $*" >&2
}

# Print success message
# Usage: log_success <message>
log_success() {
    echo -e "${COLORS[green]}✔${COLORS[reset]} $*"
}

# Print info message
# Usage: log_info <message>
log_info() {
    echo -e "${COLORS[cyan]}ℹ${COLORS[reset]} $*"
}

# Print warning message
# Usage: log_warn <message>
log_warn() {
    echo -e "${COLORS[yellow]}⚠${COLORS[reset]} $*"
}

# Print debug message (only if DEBUG is set)
# Usage: log_debug <message>
log_debug() {
    [[ -n "${DEBUG:-}" ]] && echo -e "${COLORS[dim]}[DEBUG]${COLORS[reset]} $*" >&2
}

# ============================================================================
# Validation Functions
# ============================================================================

# Check if a command exists
# Usage: command_exists <command>
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if a file exists and is readable
# Usage: file_readable <filepath>
file_readable() {
    [[ -f "$1" && -r "$1" ]]
}

# Check if a value is a positive integer
# Usage: is_positive_int <value>
is_positive_int() {
    [[ "$1" =~ ^[0-9]+$ && "$1" -gt 0 ]]
}

# Check if a value is a non-negative integer
# Usage: is_non_negative_int <value>
is_non_negative_int() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# ============================================================================
# String Functions
# ============================================================================

# Trim whitespace from a string
# Usage: trim <string>
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# Check if string is empty or whitespace only
# Usage: is_blank <string>
is_blank() {
    [[ -z "$(trim "$1")" ]]
}

# ============================================================================
# Exit Handlers
# ============================================================================

# Die with error message
# Usage: die <message> [exit_code]
die() {
    log_error "$1"
    exit "${2:-1}"
}

# Die with usage hint
# Usage: die_usage <message>
die_usage() {
    log_error "$1"
    echo "Use --help for usage information" >&2
    exit 1
}
