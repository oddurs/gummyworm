#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/converter.sh - Core ASCII art conversion
# ============================================================================
# The main conversion engine that transforms images into ASCII art.
# Requires: lib/config.sh, lib/utils.sh, lib/palettes.sh, lib/image.sh, lib/coverage.sh (loaded below)
# ============================================================================

# Guard against multiple inclusion
[[ -n "${_GUMMYWORM_CONVERTER_LOADED:-}" ]] && return 0
_GUMMYWORM_CONVERTER_LOADED=1  # plain, not readonly: see config.sh's guard

# Load declared dependencies. Each module is include-guarded, so one that is
# already loaded returns immediately. Sourced here at top level, never from
# inside a function: under zsh a readonly created while sourcing inside a
# function can be local to it, and `declare` is local in every shell.
if [[ -z "${_GUMMYWORM_CONFIG_LOADED:-}" ]]; then
    # Loaded on its own rather than via lib/all.sh: find config.sh beside us.
    if [[ -n "${BASH_VERSION:-}" ]]; then
        _gw_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        # shellcheck disable=SC2296
        _gw_here="$(cd "$(dirname "${(%):-%x}")" && pwd)"
    fi
    # shellcheck source=lib/config.sh
    source "$_gw_here/config.sh"
    unset _gw_here
fi
# shellcheck source=lib/utils.sh
source "${GUMMYWORM_LIB_DIR}/utils.sh"
# shellcheck source=lib/palettes.sh
source "${GUMMYWORM_LIB_DIR}/palettes.sh"
# shellcheck source=lib/image.sh
source "${GUMMYWORM_LIB_DIR}/image.sh"
# shellcheck source=lib/coverage.sh
source "${GUMMYWORM_LIB_DIR}/coverage.sh"

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

# Resolve a hex or named colour to "R G B" (0-255). The result is cached by
# colour, because convert_to_ascii runs once per image and once per animation
# frame and a named colour costs an ImageMagick call to resolve.
# Usage: color_to_rgb <colour>
_COLOR_RGB_KEY=""
_COLOR_RGB_VAL=""
color_to_rgb() {
    local color="$1"
    if [[ "$color" == "$_COLOR_RGB_KEY" && -n "$_COLOR_RGB_VAL" ]]; then
        printf '%s' "$_COLOR_RGB_VAL"
        return 0
    fi

    local hex="${color#\#}" r g b
    if [[ "$color" =~ $RE_HEX_COLOR ]]; then
        if [[ ${#hex} -eq 3 ]]; then
            hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
        fi
        r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))
    else
        # A named colour: ask ImageMagick, which is what the exporters use
        local px
        px=$($_MAGICK_CONVERT -size 1x1 "xc:$color" -depth 8 txt:- 2>/dev/null | tail -n 1)
        px="${px#*\(}"; px="${px%%\)*}"
        IFS=',' read -r r g b _ <<< "$px"
        r="${r//[!0-9]/}"; g="${g//[!0-9]/}"; b="${b//[!0-9]/}"
        # An unresolvable name falls back to the default background
        if [[ -z "$r" || -z "$g" || -z "$b" ]]; then r=30; g=30; b=30; fi
    fi
    _COLOR_RGB_KEY="$color"
    _COLOR_RGB_VAL="$r $g $b"
    printf '%s' "$_COLOR_RGB_VAL"
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
    out_dims=$(calc_dimensions "$orig_w" "$orig_h" "$width" "$height" "$preserve_aspect") || return 1
    read -r out_w out_h <<< "$out_dims"
    
    # Adjust pixel extraction width for wide-char palettes
    # Height stays based on visual width for correct aspect ratio
    if [[ "$char_width" -gt 1 ]]; then
        out_w=$((out_w / char_width))
        log_debug "Wide char palette detected (char_width=$char_width), pixel width adjusted: $width -> $out_w"
    fi
    
    log_debug "Original: ${orig_w}x${orig_h}, Output: ${out_w}x${out_h}"
    
    # Create temp files for pixel, palette and glyph coverage data
    local tmpfile palette_file coverage_file
    tmpfile=$(mktemp)
    palette_file=$(mktemp)
    coverage_file=$(mktemp)
    trap "rm -f '$tmpfile' '$palette_file' '$coverage_file'" RETURN

    # The colour engine and the background it assumes. Both are read from the
    # config globals rather than passed in, for the same reason as enhance: the
    # call has too many positional arguments already.
    local color_engine="${CONFIG_COLOR_ENGINE:-$DEFAULT_COLOR_ENGINE}" bg_r bg_g bg_b
    read -r bg_r bg_g bg_b <<< "$(color_to_rgb "${CONFIG_BACKGROUND:-$DEFAULT_BACKGROUND}")"
    glyph_coverage_table > "$coverage_file"
    
    # Extract pixels with preprocessing
    image_extract_pixels "$image" "$out_w" "$out_h" "$tmpfile" "$brightness" "$contrast" "$gamma"
    
    # Parse palette into an array
    palette_to_array "$palette" _PALETTE_CHARS
    local palette_len=${#_PALETTE_CHARS[@]}
    
    # Hand the palette to awk as a file, one character per line, rather than as
    # a delimiter-joined string passed with -v. Both of the obvious shortcuts
    # corrupt real palettes:
    #
    #   - joining on a separator makes that character ambiguous when the
    #     palette itself contains it, and --palette accepts any string. The
    #     shipped "detailed" palette contains a literal |.
    #   - awk -v processes escape sequences in the value, so a backslash in the
    #     palette is consumed before awk ever sees it. "detailed" has one of
    #     those too.
    #
    # A palette character can never be a newline, so one per line is
    # unambiguous for every possible palette.
    local i
    for ((i=0; i<palette_len; i++)); do
        printf '%s\n' "${_PALETTE_CHARS[$i]}"
    done > "$palette_file"
    
    log_debug "Palette length: $palette_len"
    
    # Process pixels using awk for performance
    # This is 10-100x faster than bash while-read loop
    # Uses portable awk syntax (BSD/GNU compatible)
    awk -v palette_file="$palette_file" \
        -v coverage_file="$coverage_file" \
        -v color_engine="$color_engine" \
        -v bg_r="$bg_r" -v bg_g="$bg_g" -v bg_b="$bg_b" \
        -v declared_len="$palette_len" \
        -v invert="$invert" \
        -v use_color="$use_color" \
        -v use_truecolor="$use_truecolor" \
        '
    # --- colour helpers -------------------------------------------------
    # Linear light to an 8-bit sRGB value
    function enc(x,   y) {
        if (x <= 0) return 0
        if (x >= 1) return 255
        y = (x <= 0.0031308) ? 12.92 * x : 1.055 * (x ^ (1 / 2.4)) - 0.055
        return int(y * 255 + 0.5)
    }
    # A cheap perceptual distance between two sRGB colours ("redmean")
    function rdist(r1, g1, b1, r2, g2, b2,   rm, dr, dg, db) {
        rm = (r1 + r2) / 2; dr = r1 - r2; dg = g1 - g2; db = b1 - b2
        return (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db
    }
    # The nearest xterm-256 colour, from the cube (16-231) or the grey ramp
    # (232-255). Colours 0-15 are skipped because terminals let users theme
    # them. The cube levels are 0,95,135,175,215,255, not evenly spaced.
    function snap256(r, g, b,   ri, gi, bi, avg, gl, gv, d1, d2) {
        ri = (r < 48) ? 0 : (r < 115) ? 1 : (r < 155) ? 2 : (r < 195) ? 3 : (r < 235) ? 4 : 5
        gi = (g < 48) ? 0 : (g < 115) ? 1 : (g < 155) ? 2 : (g < 195) ? 3 : (g < 235) ? 4 : 5
        bi = (b < 48) ? 0 : (b < 115) ? 1 : (b < 155) ? 2 : (b < 195) ? 3 : (b < 235) ? 4 : 5
        avg = int((r + g + b) / 3)
        gl = int((avg - 3) / 10)
        if (gl < 0) gl = 0
        if (gl > 23) gl = 23
        gv = 8 + 10 * gl
        d1 = rdist(r, g, b, cube[ri], cube[gi], cube[bi])
        d2 = rdist(r, g, b, gv, gv, gv)
        return (d2 < d1) ? 232 + gl : 16 + 36 * ri + 6 * gi + bi
    }

    BEGIN {
        # Read the palette back, one character per line. n is the count awk
        # actually has; every index below uses it rather than the count bash
        # reported, so the two can never drift apart mid-render.
        n = 0
        while ((getline pline < palette_file) > 0) {
            n++
            palette_arr[n] = pline
        }
        close(palette_file)
        if (n < 1) {
            print "gummyworm: palette is empty" > "/dev/stderr"
            exit 1
        }
        if (n != declared_len) {
            printf "gummyworm: palette count mismatch (%d vs %d)\n", n, declared_len > "/dev/stderr"
            exit 1
        }
        for (v = 0; v < 256; v++) {
            sv = v / 255
            lin[v] = (sv <= 0.04045) ? sv / 12.92 : ((sv + 0.055) / 1.055) ^ 2.4
        }
        cube[0] = 0; cube[1] = 95; cube[2] = 135; cube[3] = 175; cube[4] = 215; cube[5] = 255

        # The optical colour engine. A glyph inks only part of its cell and the
        # rest shows the background, so a colour reaches the eye as
        #     coverage * foreground + (1 - coverage) * background
        # in linear light. It is used only where it can be exact about that:
        # colour on, a dark background, and a measured coverage for every glyph
        # in the palette. Anything else (--invert, emoji, a light background)
        # falls back to the plain engine.
        optical = 0
        if (color_engine == "optical" && use_color == "true" && invert != "true") {
            while ((getline row < coverage_file) > 0) {
                tab = index(row, "\t")
                if (tab > 0) cov_of[substr(row, 1, tab - 1)] = substr(row, tab + 1) + 0
            }
            close(coverage_file)
            optical = 1
            cmax = 0
            for (i = 1; i <= n; i++) {
                if (!(palette_arr[i] in cov_of)) { optical = 0; break }
                gcov[i] = cov_of[palette_arr[i]]
                if (gcov[i] > cmax) cmax = gcov[i]
            }
            bgr = lin[bg_r + 0]; bgg = lin[bg_g + 0]; bgb = lin[bg_b + 0]
            if (0.2126 * bgr + 0.7152 * bgg + 0.0722 * bgb > 0.5) optical = 0
            if (cmax <= 0.02 || cmax <= bgr || cmax <= bgg || cmax <= bgb) optical = 0
        }
        if (optical) {
            # Glyph indices, least ink first
            for (i = 1; i <= n; i++) order[i] = i
            for (i = 2; i <= n; i++) {
                key = order[i]; j = i - 1
                while (j >= 1 && gcov[order[j]] > gcov[key]) { order[j + 1] = order[j]; j-- }
                order[j + 1] = key
            }
            # The brightest the display can reach is the densest glyph at full
            # foreground: cmax. The source is mapped into [background, cmax]
            # in linear light, so ratios between colours are kept and nothing
            # asks for more light than a glyph can give.
            kr = (cmax - bgr) / (1 - bgr)
            kg = (cmax - bgg) / (1 - bgg)
            kb = (cmax - bgb) / (1 - bgb)
        }
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
        
        if (optical) {
            # Pick the glyph with the least ink that can still carry the
            # colour at full strength, then set the foreground so coverage
            # times foreground, over the background, equals the target.
            tr = lin[r]; tg = lin[g]; tb = lin[b]
            need = tr * kr
            if (tg * kg > need) need = tg * kg
            if (tb * kb > need) need = tb * kb
            # Near-black is background. Below about 8% brightness the eye
            # cannot tell a dim dot from nothing, and the enhance step lifts
            # flat black a little, which would otherwise speckle it with dots.
            if (r <= 20 && g <= 20 && b <= 20) need = 0
            pick = order[n]
            for (oi = 1; oi <= n; oi++) {
                if (gcov[order[oi]] >= need - 0.000001) { pick = order[oi]; break }
            }
            cov = gcov[pick]
            if (cov < 0.000001) {
                fr = bgr; fg = bgg; fb = bgb
            } else {
                fr = bgr + (cmax - bgr) * tr / cov
                fg = bgg + (cmax - bgg) * tg / cov
                fb = bgb + (cmax - bgb) * tb / cov
            }
            out_r = enc(fr); out_g = enc(fg); out_b = enc(fb)
            char = palette_arr[pick]
        } else {
            # Calculate brightness using standard luminance formula
            brightness = int((r * 299 + g * 587 + b * 114) / 1000)

            # Apply inversion
            if (invert == "true") {
                brightness = 255 - brightness
            }

            # Map brightness to character index
            char_index = int((brightness * (n - 1)) / 255) + 1

            # Bounds check
            if (char_index > n) char_index = n
            if (char_index < 1) char_index = 1

            char = palette_arr[char_index]
            out_r = r; out_g = g; out_b = b
        }

        # Output with or without color
        if (use_color == "true") {
            if (use_truecolor == "true") {
                # True color (24-bit RGB)
                printf "\033[38;2;%d;%d;%dm%s", out_r, out_g, out_b, char
            } else {
                # ANSI 256-color: the nearest colour the palette really has
                printf "\033[38;5;%dm%s", snap256(out_r, out_g, out_b), char
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


