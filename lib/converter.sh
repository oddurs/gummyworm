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

# ============================================================================
# Main Conversion Function
# ============================================================================

# Convert an image to ASCII art
# Usage: convert_to_ascii <image> <width> <height> <palette> <invert> <color> <preserve_aspect>
# Output: ASCII art string (with newlines)
convert_to_ascii() {
    local image="$1"
    local width="$2"
    local height="$3"
    local palette="$4"
    local invert="$5"
    local use_color="$6"
    local preserve_aspect="$7"
    
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
    
    # Extract pixels
    image_extract_pixels "$image" "$out_w" "$out_h" "$tmpfile"
    
    # Parse palette into array (uses global _PALETTE_CHARS)
    palette_to_array "$palette" _PALETTE_CHARS
    local palette_len=${#_PALETTE_CHARS[@]}
    
    log_debug "Palette length: $palette_len"
    
    # Process pixels
    local output=""
    local current_y=-1
    
    # Store regex pattern in variable for Bash 3.2 compatibility
    local pixel_re='^([0-9]+),([0-9]+):.*\(([0-9]+),([0-9]+),([0-9]+)'
    
    while IFS= read -r line; do
        # Parse: "X,Y: (R,G,B...)  #RRGGBB  colorname"
        if [[ "$line" =~ $pixel_re ]]; then
            local x="${BASH_REMATCH[1]}"
            local y="${BASH_REMATCH[2]}"
            local r="${BASH_REMATCH[3]}"
            local g="${BASH_REMATCH[4]}"
            local b="${BASH_REMATCH[5]}"
            
            # Handle new row
            if [[ "$y" -ne "$current_y" ]]; then
                [[ "$current_y" -ge 0 ]] && output+="\n"
                current_y="$y"
                [[ "$use_color" == "true" ]] && output+="\033[0m"
            fi
            
            # Calculate brightness
            local brightness
            brightness=$(calc_brightness "$r" "$g" "$b")
            
            # Apply inversion
            if [[ "$invert" == "true" ]]; then
                brightness=$((255 - brightness))
            fi
            
            # Map brightness to character
            local char_index=$(( (brightness * (palette_len - 1)) / 255 ))
            
            # Bounds check
            [[ $char_index -ge $palette_len ]] && char_index=$((palette_len - 1))
            [[ $char_index -lt 0 ]] && char_index=0
            
            local char="${_PALETTE_CHARS[$char_index]}"
            
            # Add color escape if enabled
            if [[ "$use_color" == "true" ]]; then
                output+="$(rgb_to_ansi "$r" "$g" "$b")$char"
            else
                output+="$char"
            fi
        fi
    done < "$tmpfile"
    
    # Reset color at end
    [[ "$use_color" == "true" ]] && output+="\033[0m"
    
    echo -e "$output"
}

# ============================================================================
# Output Functions
# ============================================================================

# Save ASCII art to file
# Usage: save_to_file <content> <filepath> <strip_ansi>
save_to_file() {
    local content="$1"
    local filepath="$2"
    local strip_ansi="${3:-true}"
    
    if [[ "$strip_ansi" == "true" ]]; then
        echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g' > "$filepath"
    else
        echo -e "$content" > "$filepath"
    fi
}
