#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/converter.sh - Core ASCII art conversion
# ============================================================================
# The main conversion engine that transforms images into ASCII art.
# Requires: lib/config.sh, lib/utils.sh, lib/palettes.sh, lib/image.sh
# ============================================================================

# Guard against multiple inclusion
[[ -n "${_GUMMYWORM_CONVERTER_LOADED:-}" ]] && return 0
readonly _GUMMYWORM_CONVERTER_LOADED=1

# ============================================================================
# Color Functions
# ============================================================================

# Convert RGB to ANSI 256-color code
# Usage: rgb_to_ansi <r> <g> <b>
# Output: ANSI escape sequence
rgb_to_ansi() {
    local r="$1" g="$2" b="$3"
    
    # Map to 6x6x6 color cube (colors 16-231)
    local r_idx=$(( (r * 5) / 255 ))
    local g_idx=$(( (g * 5) / 255 ))
    local b_idx=$(( (b * 5) / 255 ))
    
    local color_code=$(( 16 + (r_idx * 36) + (g_idx * 6) + b_idx ))
    
    echo -n "\033[38;5;${color_code}m"
}

# Convert RGB to true color (24-bit) ANSI sequence
# Usage: rgb_to_truecolor <r> <g> <b>
# Output: ANSI escape sequence
rgb_to_truecolor() {
    local r="$1" g="$2" b="$3"
    echo -n "\033[38;2;${r};${g};${b}m"
}

# Detect if terminal supports true color
# Returns: 0 if supported, 1 if not
# Check $COLORTERM for 'truecolor' or '24bit'
detect_truecolor_support() {
    case "${COLORTERM:-}" in
        truecolor|24bit) return 0 ;;
    esac
    # Also check for common terminals known to support true color
    case "${TERM:-}" in
        *-truecolor|*-24bit) return 0 ;;
    esac
    return 1
}

# ============================================================================
# Main Conversion Function
# ============================================================================

# Convert an image to ASCII art
# Usage: convert_to_ascii <image> <width> <height> <palette> <invert> <color> <preserve_aspect> [truecolor] [brightness] [contrast] [gamma]
# Output: ASCII art string (with newlines)
convert_to_ascii() {
    local image="$1"
    local width="$2"
    local height="$3"
    local palette="$4"
    local invert="$5"
    local use_color="$6"
    local preserve_aspect="$7"
    local use_truecolor="${8:-false}"
    local brightness="${9:-0}"
    local contrast="${10:-0}"
    local gamma="${11:-1.0}"
    
    # Get original dimensions
    local orig_dims orig_w orig_h
    orig_dims=$(image_dimensions "$image")
    read -r orig_w orig_h <<< "$orig_dims"
    
    # Check for wide-character palettes (emojis take 2 columns)
    local char_width
    char_width=$(palette_char_width "$palette")
    
    # Calculate output dimensions using visual width (for correct aspect ratio)
    local out_dims out_w out_h
    out_dims=$(calc_dimensions "$orig_w" "$orig_h" "$width" "$height" "$preserve_aspect")
    read -r out_w out_h <<< "$out_dims"
    
    # Adjust pixel extraction width for wide-char palettes
    # Height stays based on visual width for correct aspect ratio
    if [[ "$char_width" -gt 1 ]]; then
        out_w=$((out_w / char_width))
        log_debug "Wide char palette detected (char_width=$char_width), pixel width adjusted: $width -> $out_w"
    fi
    
    log_debug "Original: ${orig_w}x${orig_h}, Output: ${out_w}x${out_h}"
    
    # Create temp file for pixel data
    local tmpfile
    tmpfile=$(mktemp)
    trap "rm -f '$tmpfile'" RETURN
    
    # Extract pixels with preprocessing
    image_extract_pixels "$image" "$out_w" "$out_h" "$tmpfile" "$brightness" "$contrast" "$gamma"
    
    # Parse palette into array for awk
    # Build a comma-separated list of palette characters
    local palette_chars_str=""
    palette_to_array "$palette" _PALETTE_CHARS
    local palette_len=${#_PALETTE_CHARS[@]}
    
    # Build palette string for awk (handle special chars)
    local i
    for ((i=0; i<palette_len; i++)); do
        if [[ $i -gt 0 ]]; then
            palette_chars_str+="|"
        fi
        palette_chars_str+="${_PALETTE_CHARS[$i]}"
    done
    
    log_debug "Palette length: $palette_len"
    
    # Process pixels using awk for performance
    # This is 10-100x faster than bash while-read loop
    # Uses portable awk syntax (BSD/GNU compatible)
    awk -v palette_str="$palette_chars_str" \
        -v palette_len="$palette_len" \
        -v invert="$invert" \
        -v use_color="$use_color" \
        -v use_truecolor="$use_truecolor" \
        '
    BEGIN {
        # Split palette into array
        n = split(palette_str, palette_arr, "|")
        current_y = -1
    }
    
    # Match pixel data lines: "X,Y: (R,G,B...)  #RRGGBB  colorname"
    /^[0-9]+,[0-9]+:.*\(/ {
        # Portable parsing (BSD awk compatible - no regex capture groups)
        # Format: "0,0: (255,0,0)  #FF0000  red"
        
        # Parse X,Y from first field "X,Y:"
        split($1, coords, ",")
        x = coords[1]
        sub(/:.*/, "", coords[2])
        y = coords[2]
        
        # Extract RGB: find the parentheses content
        # $2 is "(R,G,B)" or "(R,G,B,A)" depending on image
        rgb_field = $2
        gsub(/[()]/, "", rgb_field)  # Remove parentheses
        split(rgb_field, rgb, ",")
        r = int(rgb[1])
        g = int(rgb[2])
        b = int(rgb[3])
        
        # Handle new row
        if (y != current_y) {
            if (current_y >= 0) {
                printf "\n"
            }
            current_y = y
            if (use_color == "true") {
                printf "\033[0m"
            }
        }
        
        # Calculate brightness using standard luminance formula
        brightness = int((r * 299 + g * 587 + b * 114) / 1000)
        
        # Apply inversion
        if (invert == "true") {
            brightness = 255 - brightness
        }
        
        # Map brightness to character index
        char_index = int((brightness * (palette_len - 1)) / 255) + 1
        
        # Bounds check
        if (char_index > palette_len) char_index = palette_len
        if (char_index < 1) char_index = 1
        
        char = palette_arr[char_index]
        
        # Output with or without color
        if (use_color == "true") {
            if (use_truecolor == "true") {
                # True color (24-bit RGB)
                printf "\033[38;2;%d;%d;%dm%s", r, g, b, char
            } else {
                # ANSI 256-color: map RGB to 6x6x6 cube
                r_idx = int((r * 5) / 255)
                g_idx = int((g * 5) / 255)
                b_idx = int((b * 5) / 255)
                color_code = 16 + (r_idx * 36) + (g_idx * 6) + b_idx
                printf "\033[38;5;%dm%s", color_code, char
            }
        } else {
            printf "%s", char
        }
    }
    
    END {
        if (use_color == "true") {
            printf "\033[0m"
        }
        printf "\n"
    }
    ' "$tmpfile"
}


