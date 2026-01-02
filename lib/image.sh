#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/image.sh - Image processing functions
# ============================================================================
# Handles image validation, dimension calculation, and pixel extraction.
# Requires: lib/config.sh, lib/utils.sh
# ============================================================================

# Guard against multiple inclusion
[[ -n "${_GUMMYWORM_IMAGE_LOADED:-}" ]] && return 0
readonly _GUMMYWORM_IMAGE_LOADED=1

# ============================================================================
# Dependencies
# ============================================================================

# ImageMagick command wrappers - set by image_check_deps()
# These allow transparent use of both ImageMagick 6 and 7
_MAGICK_CONVERT=""
_MAGICK_IDENTIFY=""

# Check for required image processing tools
# Supports both ImageMagick 6 (convert/identify) and ImageMagick 7 (magick)
image_check_deps() {
    # Check for ImageMagick 7 first (magick command)
    if command_exists magick; then
        _MAGICK_CONVERT="magick"
        _MAGICK_IDENTIFY="magick identify"
        return 0
    fi
    
    # Check for ImageMagick 6 (convert/identify commands)
    if command_exists convert; then
        _MAGICK_CONVERT="convert"
    else
        die "ImageMagick is required but not installed.
  Install with:
    - macOS:   brew install imagemagick
    - Ubuntu:  sudo apt install imagemagick
    - Fedora:  sudo dnf install ImageMagick
    - Arch:    sudo pacman -S imagemagick
    - FreeBSD: pkg install ImageMagick7"
    fi
    
    if command_exists identify; then
        _MAGICK_IDENTIFY="identify"
    else
        die "ImageMagick 'identify' command not found.
  Your ImageMagick installation may be incomplete.
  Try reinstalling ImageMagick for your platform."
    fi
}

# ============================================================================
# URL & Stdin Helpers
# ============================================================================

# Check if a string is a URL
# Usage: is_url <string>
is_url() {
    [[ "$1" =~ $RE_URL ]]
}

# Download image from URL to temp file
# Usage: download_image <url>
# Output: path to temp file
download_image() {
    local url="$1"
    local temp_file
    temp_file=$(mktemp "${TMPDIR:-/tmp}/gummyworm_download.XXXXXX")
    
    # Try curl first, then wget
    if command_exists curl; then
        if ! curl -fsSL --max-time 30 -o "$temp_file" "$url" 2>/dev/null; then
            rm -f "$temp_file"
            return 1
        fi
    elif command_exists wget; then
        if ! wget -q --timeout=30 -O "$temp_file" "$url" 2>/dev/null; then
            rm -f "$temp_file"
            return 1
        fi
    else
        rm -f "$temp_file"
        die "Either curl or wget is required to download URLs"
    fi
    
    echo "$temp_file"
}

# Save stdin to temp file for processing
# Usage: image_from_stdin
# Output: path to temp file
image_from_stdin() {
    local temp_file
    temp_file=$(mktemp "${TMPDIR:-/tmp}/gummyworm_stdin.XXXXXX")
    
    # Read all stdin to temp file
    cat > "$temp_file"
    
    # Verify it's a valid image
    if ! $_MAGICK_IDENTIFY "$temp_file" &>/dev/null; then
        rm -f "$temp_file"
        die "Stdin does not contain valid image data"
    fi
    
    echo "$temp_file"
}

# ============================================================================
# Image Validation
# ============================================================================

# Check if a file is a valid readable image (non-fatal)
# Usage: image_is_valid <filepath>
# Returns: 0 if valid, 1 if not
image_is_valid() {
    local image="$1"
    
    [[ -f "$image" ]] || return 1
    [[ -r "$image" ]] || return 1
    $_MAGICK_IDENTIFY "$image" &>/dev/null || return 1
    return 0
}

# Validate that a file is a readable image (fatal on error)
# Usage: image_validate <filepath>
image_validate() {
    local image="$1"
    
    if [[ ! -f "$image" ]]; then
        die "File not found: $image"
    fi
    
    if [[ ! -r "$image" ]]; then
        die "Cannot read file: $image"
    fi
    
    if ! $_MAGICK_IDENTIFY "$image" &> /dev/null; then
        die "Not a valid image file: $image"
    fi
}

# ============================================================================
# Image Information
# ============================================================================

# Get image dimensions
# Usage: image_dimensions <filepath>
# Output: "width height" (space-separated)
image_dimensions() {
    local image="$1"
    $_MAGICK_IDENTIFY -format "%w %h" "$image" 2>/dev/null
}

# Get image width
# Usage: image_width <filepath>
image_width() {
    local image="$1"
    $_MAGICK_IDENTIFY -format "%w" "$image" 2>/dev/null
}

# Get image height  
# Usage: image_height <filepath>
image_height() {
    local image="$1"
    $_MAGICK_IDENTIFY -format "%h" "$image" 2>/dev/null
}

# ============================================================================
# Dimension Calculation
# ============================================================================

# Calculate output dimensions preserving aspect ratio
# Usage: calc_dimensions <orig_width> <orig_height> <target_width> <target_height> <preserve_aspect>
# Output: "width height" (space-separated)
calc_dimensions() {
    local orig_w="$1"
    local orig_h="$2"
    local target_w="$3"
    local target_h="$4"
    local preserve_aspect="${5:-true}"
    
    local out_w="$target_w"
    local out_h="$target_h"
    
    if [[ "$target_h" -eq 0 ]]; then
        if [[ "$preserve_aspect" == "true" ]]; then
            # Terminal chars are ~2:1 (height:width), compensate
            out_h=$(( (target_w * orig_h * 10) / (orig_w * 22) ))
            [[ "$out_h" -lt 1 ]] && out_h=1
        else
            out_h=$((target_w / 2))
        fi
    fi
    
    echo "$out_w $out_h"
}

# ============================================================================
# Pixel Extraction
# ============================================================================

# Extract pixel data from image
# Usage: image_extract_pixels <filepath> <width> <height> <output_file>
# Writes ImageMagick txt format to output_file
image_extract_pixels() {
    local image="$1"
    local width="$2"
    local height="$3"
    local output="$4"
    
    $_MAGICK_CONVERT "$image" \
        -resize "${width}x${height}!" \
        -depth 8 \
        -colorspace sRGB \
        txt:- 2>/dev/null | tail -n +2 > "$output"
}

# Calculate luminance/brightness from RGB
# Usage: calc_brightness <r> <g> <b>
# Output: brightness value 0-255
calc_brightness() {
    local r="$1"
    local g="$2"
    local b="$3"
    
    # Standard luminance formula
    echo $(( (r * 299 + g * 587 + b * 114) / 1000 ))
}
