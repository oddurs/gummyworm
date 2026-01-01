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
    local color_code=""
    case "$color" in
        reset)   color_code="$COLOR_RESET" ;;
        bold)    color_code="$COLOR_BOLD" ;;
        dim)     color_code="$COLOR_DIM" ;;
        red)     color_code="$COLOR_RED" ;;
        green)   color_code="$COLOR_GREEN" ;;
        yellow)  color_code="$COLOR_YELLOW" ;;
        blue)    color_code="$COLOR_BLUE" ;;
        magenta) color_code="$COLOR_MAGENTA" ;;
        cyan)    color_code="$COLOR_CYAN" ;;
        white)   color_code="$COLOR_WHITE" ;;
    esac
    echo -e "${color_code}$*${COLOR_RESET}"
}

# Print error message to stderr
# Usage: log_error <message>
log_error() {
    echo -e "${COLOR_RED}✖ Error:${COLOR_RESET} $*" >&2
}

# Print success message
# Usage: log_success <message>
log_success() {
    echo -e "${COLOR_GREEN}✔${COLOR_RESET} $*"
}

# Print info message
# Usage: log_info <message>
log_info() {
    echo -e "${COLOR_CYAN}ℹ${COLOR_RESET} $*"
}

# Print warning message
# Usage: log_warn <message>
log_warn() {
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $*"
}

# Print debug message (only if DEBUG is set)
# Usage: log_debug <message>
log_debug() {
    [[ -n "${DEBUG:-}" ]] && echo -e "${COLOR_DIM}[DEBUG]${COLOR_RESET} $*" >&2
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
# File & Directory Functions
# ============================================================================

# Common image file extensions
readonly IMAGE_EXTENSIONS="jpg|jpeg|png|gif|bmp|tiff|tif|webp|ico|ppm|pgm|pbm"

# Check if file has an image extension
# Usage: is_image_file <filepath>
is_image_file() {
    local file="$1"
    local ext="${file##*.}"
    [[ "${ext,,}" =~ ^($IMAGE_EXTENSIONS)$ ]]
}

# Find all image files in a directory
# Usage: find_images_in_dir <directory> [recursive]
# Output: null-separated list of image paths (for safe handling of filenames with spaces)
find_images_in_dir() {
    local dir="$1"
    local recursive="${2:-false}"
    
    # Build find command with multiple -iname patterns
    # Using -iname for case-insensitive matching (portable across BSD/GNU find)
    if [[ "$recursive" == "true" ]]; then
        find "$dir" -type f \( \
            -iname "*.jpg" -o \
            -iname "*.jpeg" -o \
            -iname "*.png" -o \
            -iname "*.gif" -o \
            -iname "*.bmp" -o \
            -iname "*.tiff" -o \
            -iname "*.tif" -o \
            -iname "*.webp" -o \
            -iname "*.ico" -o \
            -iname "*.ppm" -o \
            -iname "*.pgm" -o \
            -iname "*.pbm" \
        \) -print0 2>/dev/null | sort -z
    else
        find "$dir" -maxdepth 1 -type f \( \
            -iname "*.jpg" -o \
            -iname "*.jpeg" -o \
            -iname "*.png" -o \
            -iname "*.gif" -o \
            -iname "*.bmp" -o \
            -iname "*.tiff" -o \
            -iname "*.tif" -o \
            -iname "*.webp" -o \
            -iname "*.ico" -o \
            -iname "*.ppm" -o \
            -iname "*.pgm" -o \
            -iname "*.pbm" \
        \) -print0 2>/dev/null | sort -z
    fi
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
