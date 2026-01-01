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

# Check for required image processing tools
image_check_deps() {
    if ! command_exists convert; then
        die "ImageMagick is required but not installed.\n  Install with: sudo apt install imagemagick"
    fi
    
    if ! command_exists identify; then
        die "ImageMagick 'identify' command not found.\n  Install with: sudo apt install imagemagick"
    fi
}

# ============================================================================
# Image Validation
# ============================================================================

# Validate that a file is a readable image
# Usage: image_validate <filepath>
image_validate() {
    local image="$1"
    
    if [[ ! -f "$image" ]]; then
        die "File not found: $image"
    fi
    
    if [[ ! -r "$image" ]]; then
        die "Cannot read file: $image"
    fi
    
    if ! identify "$image" &> /dev/null; then
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
    identify -format "%w %h" "$image" 2>/dev/null
}

# Get image width
# Usage: image_width <filepath>
image_width() {
    local image="$1"
    identify -format "%w" "$image" 2>/dev/null
}

# Get image height  
# Usage: image_height <filepath>
image_height() {
    local image="$1"
    identify -format "%h" "$image" 2>/dev/null
}

# Get image format
# Usage: image_format <filepath>
image_format() {
    local image="$1"
    identify -format "%m" "$image" 2>/dev/null
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
    
    convert "$image" \
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
