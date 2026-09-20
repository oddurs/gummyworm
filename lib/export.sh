#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/export.sh - Multi-format export functions
# ============================================================================
# Provides export capabilities for HTML, SVG, and PNG output formats.
# Requires: lib/config.sh, lib/utils.sh
# ============================================================================

# Guard against multiple inclusion
[[ -n "${_GUMMYWORM_EXPORT_LOADED:-}" ]] && return 0
readonly _GUMMYWORM_EXPORT_LOADED=1

# ============================================================================
# Format Detection
# ============================================================================

# Valid output formats
readonly EXPORT_FORMATS="text ansi html svg png gif"

# Detect output format from file extension
# Usage: export_detect_format <filepath>
# Output: format name (text, ansi, html, svg, png, gif)
export_detect_format() {
    local filepath="$1"
    local ext="${filepath##*.}"
    # Convert to lowercase (bash 3.x compatible)
    ext=$(tr '[:upper:]' '[:lower:]' <<< "$ext")
    
    case "$ext" in
        html|htm) echo "html" ;;
        svg)      echo "svg" ;;
        png)      echo "png" ;;
        gif)      echo "gif" ;;
        ans|ansi) echo "ansi" ;;
        *)        echo "text" ;;
    esac
}

# Validate format string
# Usage: export_validate_format <format>
# Returns: 0 if valid, 1 if invalid
export_validate_format() {
    local format="$1"
    [[ " $EXPORT_FORMATS " == *" $format "* ]]
}

# ============================================================================
# Shared AWK Functions
# ============================================================================

# AWK function to convert ANSI 256 color code to hex RGB
# Used by both HTML and SVG export functions
# Note: Stored as a variable to avoid duplication in AWK scripts
readonly AWK_ANSI256_TO_RGB='
function ansi256_to_rgb(n) {
    if (n < 16) {
        # Standard 16 colors
        colors[0]  = "#000000"; colors[1]  = "#800000"
        colors[2]  = "#008000"; colors[3]  = "#808000"
        colors[4]  = "#000080"; colors[5]  = "#800080"
        colors[6]  = "#008080"; colors[7]  = "#c0c0c0"
        colors[8]  = "#808080"; colors[9]  = "#ff0000"
        colors[10] = "#00ff00"; colors[11] = "#ffff00"
        colors[12] = "#0000ff"; colors[13] = "#ff00ff"
        colors[14] = "#00ffff"; colors[15] = "#ffffff"
        return colors[n]
    } else if (n < 232) {
        # 6x6x6 color cube (colors 16-231)
        n = n - 16
        r = int(n / 36)
        g = int((n % 36) / 6)
        b = n % 6
        r = (r > 0) ? r * 40 + 55 : 0
        g = (g > 0) ? g * 40 + 55 : 0
        b = (b > 0) ? b * 40 + 55 : 0
        return sprintf("#%02x%02x%02x", r, g, b)
    } else {
        # Grayscale (colors 232-255)
        gray = (n - 232) * 10 + 8
        return sprintf("#%02x%02x%02x", gray, gray, gray)
    }
}

# Parse true color code (38;2;r;g;b) and return hex RGB
function truecolor_to_rgb(code) {
    # code is "38;2;r;g;b" - extract r, g, b values
    split(code, parts, ";")
    r = int(parts[3])
    g = int(parts[4])
    b = int(parts[5])
    return sprintf("#%02x%02x%02x", r, g, b)
}
'

# ============================================================================
# Shared Font Metrics
# ============================================================================
# The grid handed to these exporters was built for a character cell of a
# particular shape (see calc_dimensions in image.sh). Painting it at a different
# shape re-introduces exactly the distortion that calculation exists to remove,
# so both exporters derive their metrics here from the same ratio rather than
# restating it. Keeping these numbers in one place is the point.

readonly EXPORT_FONT_SIZE=12
# Courier New — and every font in the stacks below — advances 0.6em per glyph.
readonly EXPORT_CHAR_WIDTH_EM="0.6"

# Character advance in px. Independent of the cell ratio: the ratio scales the
# line height, not the glyph width.
# Usage: export_char_width
export_char_width() {
    awk -v s="$EXPORT_FONT_SIZE" -v em="$EXPORT_CHAR_WIDTH_EM" \
        'BEGIN { printf "%.4g", s * em }'
}

# Line height in px: char width times the cell ratio.
# Usage: export_line_height [char_aspect]
export_line_height() {
    local ratio="${1:-${CONFIG_CHAR_ASPECT:-2.0}}"
    awk -v s="$EXPORT_FONT_SIZE" -v em="$EXPORT_CHAR_WIDTH_EM" -v r="$ratio" \
        'BEGIN { printf "%.4g", s * em * r }'
}

# The same figure as a unitless CSS line-height, which multiplies font-size
# rather than char width — so it is ratio * 0.6, not the ratio itself.
# Usage: export_css_line_height [char_aspect]
export_css_line_height() {
    local ratio="${1:-${CONFIG_CHAR_ASPECT:-2.0}}"
    awk -v em="$EXPORT_CHAR_WIDTH_EM" -v r="$ratio" \
        'BEGIN { printf "%.4g", em * r }'
}

# ============================================================================
# HTML Export
# ============================================================================

# Convert ASCII art to HTML with CSS styling
# Usage: export_html <ascii_content> [background_color] [padding] [title]
# Output: Complete HTML document
export_html() {
    local content="$1"
    local bg_color="${2:-#1e1e1e}"
    local padding="${3:-0}"
    local title="${4:-ASCII Art - gummyworm}"

    local font_size css_line_height
    font_size="$EXPORT_FONT_SIZE"
    css_line_height=$(export_css_line_height)

    # Start HTML document
    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            background-color: ${bg_color};
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: ${padding}px;
        }
        .ascii-art {
            font-family: 'Courier New', Courier, 'Liberation Mono', 'DejaVu Sans Mono', monospace;
            font-size: ${font_size}px;
            /* char_aspect * 0.6em advance — see export_css_line_height */
            line-height: ${css_line_height};
            white-space: pre;
            letter-spacing: 0;
        }
        .ascii-art span {
            display: inline;
        }
        /* For plain text (no color) */
        .ascii-art.plain {
            color: #ffffff;
        }
    </style>
</head>
<body>
    <pre class="ascii-art">
EOF

    # Convert ANSI escape codes to HTML spans
    _ansi_to_html "$content"
    
    # Close HTML
    cat << 'EOF'
</pre>
</body>
</html>
EOF
}

# Convert ANSI color codes to HTML spans
# Usage: _ansi_to_html <content>
_ansi_to_html() {
    local content="$1"
    
    # Process the content character by character, handling escape sequences
    # Using awk for more reliable ANSI parsing
    echo -e "$content" | awk "
    $AWK_ANSI256_TO_RGB
    BEGIN {
        in_span = 0
    }
    {
        line = \$0
        output = \"\"
        i = 1
        while (i <= length(line)) {
            c = substr(line, i, 1)
            if (c == \"\033\" || c == \"\x1b\") {
                # Start of escape sequence
                if (substr(line, i, 2) == \"\033[\" || substr(line, i, 2) == \"\x1b[\") {
                    # Find the end of the escape sequence (letter)
                    j = i + 2
                    code = \"\"
                    while (j <= length(line)) {
                        cc = substr(line, j, 1)
                        if (cc ~ /[a-zA-Z]/) {
                            break
                        }
                        code = code cc
                        j++
                    }
                    
                    if (substr(line, j, 1) == \"m\") {
                        # Color code
                        if (in_span) {
                            output = output \"</span>\"
                            in_span = 0
                        }
                        
                        if (code != \"0\" && code != \"\") {
                            # Parse true color: 38;2;r;g;b (check first)
                            if (code ~ /^38;2;/) {
                                rgb = truecolor_to_rgb(code)
                                output = output \"<span style=\\\"color: \" rgb \"\\\">\"
                                in_span = 1
                            }
                            # Parse 256-color: 38;5;N
                            else if (code ~ /^38;5;/) {
                                color_num = substr(code, 6)
                                rgb = ansi256_to_rgb(int(color_num))
                                output = output \"<span style=\\\"color: \" rgb \"\\\">\"
                                in_span = 1
                            }
                        }
                        i = j + 1
                        continue
                    }
                }
            }
            
            # HTML escape special characters
            if (c == \"<\") output = output \"\\&lt;\"
            else if (c == \">\") output = output \"\\&gt;\"
            else if (c == \"\\&\") output = output \"\\&amp;\"
            else if (c == \"\\\"\") output = output \"\\&quot;\"
            else output = output c
            
            i++
        }
        
        if (in_span) {
            output = output \"</span>\"
            in_span = 0
        }
        
        print output
    }
    "
}

# ============================================================================
# SVG Export
# ============================================================================

# Convert ASCII art to SVG
# Usage: export_svg <ascii_content> [background_color] [padding]
# Output: Complete SVG document
export_svg() {
    local content="$1"
    local bg_color="${2:-#1e1e1e}"
    local padding="${3:-0}"
    
    # Cell metrics, both derived from the shared ratio (defaults: 7.2 x 14.4).
    # Kept as integers scaled by 10 for decimal precision in the y-advance below.
    local char_width line_height
    char_width=$(export_char_width)
    line_height=$(export_line_height)
    local char_width_x10 line_height_x10
    char_width_x10=$(awk -v v="$char_width" 'BEGIN { printf "%.0f", v * 10 }')
    line_height_x10=$(awk -v v="$line_height" 'BEGIN { printf "%.0f", v * 10 }')
    
    # Get content dimensions
    local lines=()
    local max_width=0
    local line_count=0
    
    # Strip ANSI for dimension calculation and store lines
    while IFS= read -r line; do
        local clean_line
        clean_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        lines+=("$line")
        local len=${#clean_line}
        [[ $len -gt $max_width ]] && max_width=$len
        line_count=$((line_count + 1))
    done < <(echo -e "$content")
    
    # Calculate SVG dimensions using awk for floating-point (faster than bc)
    local svg_width svg_height
    svg_width=$(awk -v w="$max_width" -v p="$padding" -v cw="$char_width" 'BEGIN { printf "%.1f", w * cw + p * 2 }')
    svg_height=$(awk -v h="$line_count" -v p="$padding" -v lh="$line_height" 'BEGIN { printf "%.1f", h * lh + p * 2 }')
    
    # Start SVG
    cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" 
     width="${svg_width}" 
     height="${svg_height}"
     viewBox="0 0 ${svg_width} ${svg_height}">
  <defs>
    <style>
      .ascii-text {
        font-family: 'Courier New', Courier, monospace;
        font-size: ${EXPORT_FONT_SIZE}px;
        white-space: pre;
      }
    </style>
  </defs>
  <rect width="100%" height="100%" fill="${bg_color}"/>
  <g class="ascii-text">
EOF

    # Process each line - use awk for y position calculation
    local y_pos_x10=$((padding * 10))  # Start with padding * 10 for precision
    for line in "${lines[@]}"; do
        y_pos_x10=$((y_pos_x10 + line_height_x10))
        # Convert back to decimal for SVG
        local y_pos
        y_pos=$(awk -v y="$y_pos_x10" 'BEGIN { printf "%.1f", y / 10 }')
        _svg_render_line "$line" "$padding" "$y_pos" "$char_width"
    done
    
    # Close SVG
    echo "  </g>"
    echo "</svg>"
}

# Render a single line to SVG with color spans
# Usage: _svg_render_line <line> <x> <y> <char_width>
_svg_render_line() {
    local line="$1"
    local x_start="$2"
    local y="$3"
    local char_width="$4"
    
    # Parse ANSI codes and output SVG text elements
    echo -e "$line" | awk -v x_start="$x_start" -v y="$y" -v cw="$char_width" "
    $AWK_ANSI256_TO_RGB
    BEGIN {
        current_color = \"#ffffff\"  # Default white
        x = x_start
        buffer = \"\"
        buffer_start_x = x
    }
    {
        line = \$0
        i = 1
        while (i <= length(line)) {
            c = substr(line, i, 1)
            
            if (c == \"\033\" || c == \"\x1b\") {
                if (substr(line, i, 2) == \"\033[\" || substr(line, i, 2) == \"\x1b[\") {
                    # Flush buffer before color change
                    if (buffer != \"\") {
                        gsub(/&/, \"\\\\&amp;\", buffer)
                        gsub(/</, \"\\\\&lt;\", buffer)
                        gsub(/>/, \"\\\\&gt;\", buffer)
                        gsub(/\"/, \"\\\\&quot;\", buffer)
                        printf \"    <text x=\\\"%s\\\" y=\\\"%s\\\" fill=\\\"%s\\\">%s</text>\\n\", buffer_start_x, y, current_color, buffer
                        buffer = \"\"
                    }
                    
                    # Parse escape sequence
                    j = i + 2
                    code = \"\"
                    while (j <= length(line)) {
                        cc = substr(line, j, 1)
                        if (cc ~ /[a-zA-Z]/) break
                        code = code cc
                        j++
                    }
                    
                    if (substr(line, j, 1) == \"m\") {
                        if (code == \"0\" || code == \"\") {
                            current_color = \"#ffffff\"
                        } else if (code ~ /^38;2;/) {
                            # True color: 38;2;r;g;b
                            current_color = truecolor_to_rgb(code)
                        } else if (code ~ /^38;5;/) {
                            color_num = substr(code, 6)
                            current_color = ansi256_to_rgb(int(color_num))
                        }
                        buffer_start_x = x
                    }
                    i = j + 1
                    continue
                }
            }
            
            buffer = buffer c
            x = x + cw
            i++
        }
        
        # Flush remaining buffer
        if (buffer != \"\") {
            gsub(/&/, \"\\\\&amp;\", buffer)
            gsub(/</, \"\\\\&lt;\", buffer)
            gsub(/>/, \"\\\\&gt;\", buffer)
            gsub(/\"/, \"\\\\&quot;\", buffer)
            printf \"    <text x=\\\"%s\\\" y=\\\"%s\\\" fill=\\\"%s\\\">%s</text>\\n\", buffer_start_x, y, current_color, buffer
        }
    }
    "
}

# ============================================================================
# PNG Export
# ============================================================================

# Convert ASCII art to PNG using ImageMagick
# Usage: export_png <ascii_content> <output_file> [background_color] [font] [padding]
# Returns: 0 on success, 1 on failure
export_png() {
    local content="$1"
    local output_file="$2"
    local bg_color="${3:-#1e1e1e}"
    local font="${4:-}"
    local padding="${5:-0}"
    
    # Check that ImageMagick was initialized (should be done by image_check_deps)
    if [[ -z "$_MAGICK_CONVERT" ]]; then
        log_error "PNG export requires ImageMagick (not initialized)"
        return 1
    fi
    
    # Strategy: Generate SVG first, then convert to PNG
    # This preserves colors better than direct text rendering
    local tmpsvg
    tmpsvg=$(mktemp -t gummyworm_svg.XXXXXX)
    mv "$tmpsvg" "${tmpsvg}.svg"
    tmpsvg="${tmpsvg}.svg"
    trap "rm -f '$tmpsvg'" RETURN
    
    # Generate SVG
    export_svg "$content" "$bg_color" "$padding" > "$tmpsvg"
    
    # Rasterise. rsvg-convert is tried first and is the path that actually works
    # on a stock install: ImageMagick's built-in SVG renderer resolves the SVG's
    # font-family itself and fails with "unable to read font ''" when it cannot,
    # which it cannot for 'Courier New' on a default macOS ImageMagick. It also
    # will not hand the file to its own rsvg delegate, because it believes it can
    # render SVG natively. Going straight to rsvg-convert sidesteps both.
    local rsvg_err
    rsvg_err=$(mktemp -t gummyworm_rsvg.XXXXXX)
    # shellcheck disable=SC2064
    trap "rm -f '$tmpsvg' '$rsvg_err'" RETURN

    if command_exists rsvg-convert; then
        # Background is already painted into the SVG by export_svg
        if rsvg-convert -o "$output_file" "$tmpsvg" 2>"$rsvg_err"; then
            return 0
        fi
        log_error "Failed to convert SVG to PNG (rsvg-convert)"
        [[ -s "$rsvg_err" ]] && log_debug "rsvg-convert: $(cat "$rsvg_err")"
        return 1
    fi

    # Fall back to ImageMagick. A font must be named here or the built-in
    # renderer trips over the SVG's own font-family.
    local convert_args=(-background "$bg_color")
    if [[ -n "$font" ]]; then
        convert_args+=(-font "$font")
    fi
    convert_args+=("$tmpsvg" "$output_file")

    if $_MAGICK_CONVERT "${convert_args[@]}" 2>/dev/null; then
        return 0
    fi

    log_error "Failed to convert SVG to PNG"
    return 1
}

# ============================================================================
# Animated GIF Export
# ============================================================================

# Convert multiple ASCII frames to an animated GIF
# Usage: export_animated_gif <output_file> <delay_ms> <loops> <bg_color> <padding> <frame1_content> [frame2_content ...]
# Arguments:
#   output_file - Path to output GIF file
#   delay_ms    - Delay between frames in milliseconds
#   loops       - Number of loops (0 = infinite)
#   bg_color    - Background color for frames
#   padding     - Padding in pixels around content
#   frameN      - ASCII content for each frame
# Returns: 0 on success, 1 on failure
export_animated_gif() {
    local output_file="$1"
    local delay_ms="$2"
    local loops="$3"
    local bg_color="$4"
    local padding="$5"
    shift 5
    local frames=("$@")
    
    # Check that ImageMagick was initialized
    if [[ -z "$_MAGICK_CONVERT" ]]; then
        log_error "Animated GIF export requires ImageMagick (not initialized)"
        return 1
    fi
    
    # Validate we have frames
    if [[ ${#frames[@]} -eq 0 ]]; then
        log_error "No frames provided for animated GIF"
        return 1
    fi
    
    # Create temp directory for frame PNGs
    local tmpdir
    tmpdir=$(mktemp -d -t gummyworm_gif.XXXXXX)
    trap "rm -rf '$tmpdir'" RETURN
    
    # Convert delay from milliseconds to centiseconds (ImageMagick uses centiseconds)
    local delay_cs=$(( delay_ms / 10 ))
    [[ $delay_cs -lt 1 ]] && delay_cs=1
    
    # Generate PNG for each frame
    local frame_num=0
    local frame_files=()
    
    for frame_content in "${frames[@]}"; do
        local frame_file="${tmpdir}/frame_$(printf '%04d' $frame_num).png"
        
        # Generate PNG for this frame
        if ! export_png "$frame_content" "$frame_file" "$bg_color" "" "$padding"; then
            log_error "Failed to generate frame $frame_num"
            return 1
        fi
        
        frame_files+=("$frame_file")
        frame_num=$((frame_num + 1))
    done
    
    # Combine frames into animated GIF using ImageMagick
    local convert_args=()
    convert_args+=(-delay "$delay_cs")
    convert_args+=(-loop "$loops")
    convert_args+=(-dispose background)
    convert_args+=("${frame_files[@]}")
    convert_args+=("$output_file")
    
    if $_MAGICK_CONVERT "${convert_args[@]}" 2>/dev/null; then
        return 0
    else
        log_error "Failed to create animated GIF"
        return 1
    fi
}

# Export frames as individual files (for debugging or frame extraction)
# Usage: export_frames <output_dir> <format> <bg_color> <padding> <frame1_content> [frame2_content ...]
# Returns: 0 on success, 1 on failure
export_frames() {
    local output_dir="$1"
    local format="$2"
    local bg_color="$3"
    local padding="$4"
    shift 4
    local frames=("$@")
    
    # Create output directory if needed
    mkdir -p "$output_dir" 2>/dev/null || {
        log_error "Cannot create output directory: $output_dir"
        return 1
    }
    
    local frame_num=0
    local ext
    ext=$(export_get_extension "$format")
    
    for frame_content in "${frames[@]}"; do
        local frame_file="${output_dir}/frame_$(printf '%04d' $frame_num).${ext}"
        
        if ! export_content "$format" "$frame_content" "$frame_file" "$bg_color" "$padding"; then
            log_error "Failed to export frame $frame_num"
            return 1
        fi
        
        frame_num=$((frame_num + 1))
    done
    
    return 0
}

# ============================================================================
# Export Dispatcher
# ============================================================================

# Export ASCII art to the specified format
# Usage: export_content <format> <content> <output_file> [bg_color] [padding]
# Note: For animated GIF, use export_animated_gif() directly with multiple frames
# Returns: 0 on success, 1 on failure
export_content() {
    local format="$1"
    local content="$2"
    local output_file="$3"
    local bg_color="${4:-#1e1e1e}"
    local padding="${5:-0}"
    
    case "$format" in
        text)
            # Plain text - strip ANSI codes
            echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g' > "$output_file"
            ;;
        ansi)
            # ANSI - preserve escape codes
            echo -e "$content" > "$output_file"
            ;;
        html)
            export_html "$content" "$bg_color" "$padding" > "$output_file"
            ;;
        svg)
            export_svg "$content" "$bg_color" "$padding" > "$output_file"
            ;;
        png)
            export_png "$content" "$output_file" "$bg_color" "" "$padding"
            return $?
            ;;
        gif)
            # For single-frame GIF, create a static GIF
            # Use export_animated_gif with single frame for consistency
            export_animated_gif "$output_file" 100 0 "$bg_color" "$padding" "$content"
            return $?
            ;;
        *)
            log_error "Unknown export format: $format"
            return 1
            ;;
    esac
    
    return 0
}

# Get appropriate file extension for format
# Usage: export_get_extension <format>
export_get_extension() {
    local format="$1"
    case "$format" in
        text) echo "txt" ;;
        ansi) echo "ans" ;;
        html) echo "html" ;;
        svg)  echo "svg" ;;
        png)  echo "png" ;;
        gif)  echo "gif" ;;
        *)    echo "txt" ;;
    esac
}
