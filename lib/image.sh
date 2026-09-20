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

# Check that ImageMagick can rasterise SVG
#
# The png and gif exports render SVG and hand it to ImageMagick, which cannot
# rasterise SVG by itself — it shells out to a delegate. A plain
# `brew install imagemagick` does not pull one in, so the documented dependency
# alone produces a build where these formats cannot work. Without this check the
# failure surfaces as "Failed to convert SVG to PNG" after all the conversion
# work is done, naming neither the cause nor the fix.
#
# Usage: image_check_raster_deps <format>
# Dies with an actionable message if the format needs a delegate and none exists
image_check_raster_deps() {
    local format="$1"

    case "$format" in
        png|gif) ;;
        *) return 0 ;;
    esac

    # rsvg-convert is what ImageMagick's own svg delegate invokes; Inkscape is
    # the other renderer it will accept.
    if command_exists rsvg-convert || command_exists inkscape; then
        return 0
    fi

    die "Cannot export $format: no SVG renderer installed.
  ImageMagick needs a delegate to rasterise SVG, and neither
  rsvg-convert nor inkscape was found.
  Install with:
    - macOS:   brew install librsvg
    - Ubuntu:  sudo apt install librsvg2-bin
    - Fedora:  sudo dnf install librsvg2-tools
    - Arch:    sudo pacman -S librsvg
    - FreeBSD: pkg install librsvg2
  Or export to svg or html, which need no delegate."
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

# Convert a character aspect ratio ("2.0", "1.67") to hundredths (200, 167)
# so the dimension maths can stay in integers. Rounds to the nearest hundredth.
# Usage: char_aspect_hundredths <ratio>
char_aspect_hundredths() {
    local ratio="${1:-$DEFAULT_CHAR_ASPECT}"
    local h
    h=$(awk -v r="$ratio" 'BEGIN { printf "%.0f", r * 100 }' 2>/dev/null)
    # Guard against a non-numeric or zero ratio reaching the divisor
    [[ "$h" =~ ^[0-9]+$ ]] && [[ "$h" -gt 0 ]] || h=200
    echo "$h"
}

# Calculate output dimensions preserving aspect ratio
#
# A terminal character cell is taller than it is wide, so a grid whose column
# count matches the image's pixel proportions comes out squashed. char_aspect is
# that cell ratio (height:width) and divides the row count to compensate: get it
# wrong and a circle renders as an ellipse. See DEFAULT_CHAR_ASPECT in config.sh.
#
# Usage: calc_dimensions <orig_width> <orig_height> <target_width> <target_height> <preserve_aspect> [char_aspect]
# Output: "width height" (space-separated)
calc_dimensions() {
    local orig_w="$1"
    local orig_h="$2"
    local target_w="$3"
    local target_h="$4"
    local preserve_aspect="${5:-true}"
    local char_aspect="${6:-${CONFIG_CHAR_ASPECT:-$DEFAULT_CHAR_ASPECT}}"

    local out_w="$target_w"
    local out_h="$target_h"

    if [[ "$target_h" -eq 0 ]]; then
        local aspect_x100
        aspect_x100=$(char_aspect_hundredths "$char_aspect")

        local numerator denominator
        if [[ "$preserve_aspect" == "true" ]]; then
            numerator=$(( target_w * orig_h * 100 ))
            denominator=$(( orig_w * aspect_x100 ))
        else
            # No image proportions to honour, but the cell is still not square,
            # so the ratio alone decides the row count.
            numerator=$(( target_w * 100 ))
            denominator="$aspect_x100"
        fi

        # Round half up rather than truncating: truncation silently drops most
        # of a row (800/22 = 36.36 -> 36) and the error is visible in the output.
        out_h=$(( (numerator + denominator / 2) / denominator ))
        [[ "$out_h" -lt 1 ]] && out_h=1
    fi

    echo "$out_w $out_h"
}

# ============================================================================
# Pixel Extraction
# ============================================================================

# Extract pixel data from image with optional preprocessing
# Usage: image_extract_pixels <filepath> <width> <height> <output_file> [brightness] [contrast] [gamma]
# Writes ImageMagick txt format to output_file
image_extract_pixels() {
    local image="$1"
    local width="$2"
    local height="$3"
    local output="$4"
    local brightness="${5:-0}"
    local contrast="${6:-0}"
    local gamma="${7:-1.0}"
    
    # Build preprocessing options string (only add if non-default)
    local preprocess_opts=""
    if [[ "$brightness" != "0" || "$contrast" != "0" ]]; then
        preprocess_opts="-brightness-contrast ${brightness}x${contrast} "
    fi
    if [[ "$gamma" != "1.0" && "$gamma" != "1" ]]; then
        preprocess_opts+="-gamma $gamma "
    fi
    
    # Note: preprocess_opts is intentionally unquoted to allow word splitting
    # shellcheck disable=SC2086
    $_MAGICK_CONVERT "$image" \
        $preprocess_opts \
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

# ============================================================================
# Animation Support
# ============================================================================

# Check if an image is animated (has multiple frames)
# Usage: image_is_animated <filepath>
# Returns: 0 if animated (>1 frame), 1 if static
image_is_animated() {
    local image="$1"
    local frame_count
    frame_count=$(image_frame_count "$image")
    [[ "$frame_count" -gt 1 ]]
}

# Get number of frames in an image
# Usage: image_frame_count <filepath>
# Output: integer frame count
image_frame_count() {
    local image="$1"
    $_MAGICK_IDENTIFY -format "%n\n" "$image" 2>/dev/null | head -1
}

# Get frame delays in centiseconds (1/100th second)
# Usage: image_get_delays <filepath>
# Output: newline-separated delay values (one per frame)
image_get_delays() {
    local image="$1"
    $_MAGICK_IDENTIFY -format "%T\n" "$image" 2>/dev/null
}

# Get loop count for animated image
# Usage: image_get_loop_count <filepath>
# Output: loop count (0 = infinite)
image_get_loop_count() {
    local image="$1"
    local loop
    loop=$($_MAGICK_IDENTIFY -format "%[gif:loop]" "$image[0]" 2>/dev/null)
    # Default to 0 (infinite) if not set
    echo "${loop:-0}"
}

# Extract all frames from an animated image
# Usage: image_extract_frames <filepath> <output_dir> [max_frames]
# Creates frame_000.png, frame_001.png, etc. in output_dir
# Output: prints number of frames extracted
image_extract_frames() {
    local image="$1"
    local output_dir="$2"
    local max_frames="${3:-0}"
    
    # Ensure output directory exists
    mkdir -p "$output_dir"
    
    # Use -coalesce to properly handle GIF disposal methods
    # This flattens each frame to a complete image
    if [[ "$max_frames" -gt 0 ]]; then
        # Limit number of frames
        $_MAGICK_CONVERT "$image" -coalesce \
            -scene 0 \
            "${output_dir}/frame_%03d.png" 2>/dev/null
        
        # Remove frames beyond max
        local count=0
        for f in "$output_dir"/frame_*.png; do
            if [[ $count -ge $max_frames ]]; then
                rm -f "$f"
            fi
            ((count++))
        done
        echo "$((count < max_frames ? count : max_frames))"
    else
        $_MAGICK_CONVERT "$image" -coalesce \
            "${output_dir}/frame_%03d.png" 2>/dev/null
        
        # Count extracted frames
        local count=0
        for _ in "$output_dir"/frame_*.png; do
            ((count++))
        done
        echo "$count"
    fi
}

# Extract a single frame from an animated image
# Usage: image_extract_frame <filepath> <frame_index> <output_file>
image_extract_frame() {
    local image="$1"
    local frame_idx="$2"
    local output="$3"
    
    $_MAGICK_CONVERT "${image}[${frame_idx}]" -coalesce "$output" 2>/dev/null
}
