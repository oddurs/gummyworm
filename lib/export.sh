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
readonly EXPORT_FORMATS="text ansi html svg png"

# Detect output format from file extension
# Usage: export_detect_format <filepath>
# Output: format name (text, ansi, html, svg, png)
export_detect_format() {
    local filepath="$1"
    local ext="${filepath##*.}"
    # Convert to lowercase (bash 3.x compatible)
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    case "$ext" in
        html|htm) echo "html" ;;
        svg)      echo "svg" ;;
        png)      echo "png" ;;
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
# HTML Export
# ============================================================================

# Convert ASCII art to HTML with CSS styling
# Usage: export_html <ascii_content> [background_color]
# Output: Complete HTML document
export_html() {
    local content="$1"
    local bg_color="${2:-#1e1e1e}"
    local title="${3:-ASCII Art - Gummyworm}"
    
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
            padding: 20px;
        }
        .ascii-art {
            font-family: 'Courier New', Courier, 'Liberation Mono', 'DejaVu Sans Mono', monospace;
            font-size: 12px;
            line-height: 1.2;
            white-space: pre;
            letter-spacing: 0;
        }
        .ascii-art span {
            display: inline;
        }
        /* For plain text (no color) */
        .ascii-art.plain {
            color: #00ff00;
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
    local in_span=false
    local result=""
    
    # Process the content character by character, handling escape sequences
    # Using awk for more reliable ANSI parsing
    echo -e "$content" | awk '
    BEGIN {
        in_span = 0
    }
    {
        line = $0
        output = ""
        i = 1
        while (i <= length(line)) {
            c = substr(line, i, 1)
            if (c == "\033" || c == "\x1b") {
                # Start of escape sequence
                if (substr(line, i, 2) == "\033[" || substr(line, i, 2) == "\x1b[") {
                    # Find the end of the escape sequence (letter)
                    j = i + 2
                    code = ""
                    while (j <= length(line)) {
                        cc = substr(line, j, 1)
                        if (cc ~ /[a-zA-Z]/) {
                            break
                        }
                        code = code cc
                        j++
                    }
                    
                    if (substr(line, j, 1) == "m") {
                        # Color code
                        if (in_span) {
                            output = output "</span>"
                            in_span = 0
                        }
                        
                        if (code != "0" && code != "") {
                            # Parse 256-color: 38;5;N
                            if (code ~ /^38;5;/) {
                                color_num = substr(code, 6)
                                rgb = ansi256_to_rgb(int(color_num))
                                output = output "<span style=\"color: " rgb "\">"
                                in_span = 1
                            }
                        }
                        i = j + 1
                        continue
                    }
                }
            }
            
            # HTML escape special characters
            if (c == "<") output = output "&lt;"
            else if (c == ">") output = output "&gt;"
            else if (c == "&") output = output "&amp;"
            else if (c == "\"") output = output "&quot;"
            else output = output c
            
            i++
        }
        
        if (in_span) {
            output = output "</span>"
            in_span = 0
        }
        
        print output
    }
    
    # Convert ANSI 256 color to RGB
    function ansi256_to_rgb(n) {
        if (n < 16) {
            # Standard colors
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
            # 6x6x6 color cube
            n = n - 16
            r = int(n / 36)
            g = int((n % 36) / 6)
            b = n % 6
            r = (r > 0) ? r * 40 + 55 : 0
            g = (g > 0) ? g * 40 + 55 : 0
            b = (b > 0) ? b * 40 + 55 : 0
            return sprintf("rgb(%d,%d,%d)", r, g, b)
        } else {
            # Grayscale
            gray = (n - 232) * 10 + 8
            return sprintf("rgb(%d,%d,%d)", gray, gray, gray)
        }
    }
    '
}

# ============================================================================
# SVG Export
# ============================================================================

# Convert ASCII art to SVG
# Usage: export_svg <ascii_content> [background_color]
# Output: Complete SVG document
export_svg() {
    local content="$1"
    local bg_color="${2:-#1e1e1e}"
    
    # Calculate dimensions
    local char_width=7.2     # Approximate width of monospace char at 12px
    local line_height=14.4   # Line height at 12px with 1.2 factor
    local padding=20
    
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
    
    # Calculate SVG dimensions
    local svg_width=$(echo "$max_width * $char_width + $padding * 2" | bc)
    local svg_height=$(echo "$line_count * $line_height + $padding * 2" | bc)
    
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
        font-size: 12px;
        white-space: pre;
      }
    </style>
  </defs>
  <rect width="100%" height="100%" fill="${bg_color}"/>
  <g class="ascii-text">
EOF

    # Process each line
    local y_pos=$padding
    for line in "${lines[@]}"; do
        y_pos=$(echo "$y_pos + $line_height" | bc)
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
    echo -e "$line" | awk -v x_start="$x_start" -v y="$y" -v cw="$char_width" '
    BEGIN {
        current_color = "#00ff00"  # Default green
        x = x_start
        buffer = ""
        buffer_start_x = x
    }
    {
        line = $0
        i = 1
        while (i <= length(line)) {
            c = substr(line, i, 1)
            
            if (c == "\033" || c == "\x1b") {
                if (substr(line, i, 2) == "\033[" || substr(line, i, 2) == "\x1b[") {
                    # Flush buffer before color change
                    if (buffer != "") {
                        gsub(/&/, "\\&amp;", buffer)
                        gsub(/</, "\\&lt;", buffer)
                        gsub(/>/, "\\&gt;", buffer)
                        gsub(/"/, "\\&quot;", buffer)
                        printf "    <text x=\"%s\" y=\"%s\" fill=\"%s\">%s</text>\n", buffer_start_x, y, current_color, buffer
                        buffer = ""
                    }
                    
                    # Parse escape sequence
                    j = i + 2
                    code = ""
                    while (j <= length(line)) {
                        cc = substr(line, j, 1)
                        if (cc ~ /[a-zA-Z]/) break
                        code = code cc
                        j++
                    }
                    
                    if (substr(line, j, 1) == "m") {
                        if (code == "0" || code == "") {
                            current_color = "#00ff00"
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
        if (buffer != "") {
            gsub(/&/, "\\&amp;", buffer)
            gsub(/</, "\\&lt;", buffer)
            gsub(/>/, "\\&gt;", buffer)
            gsub(/"/, "\\&quot;", buffer)
            printf "    <text x=\"%s\" y=\"%s\" fill=\"%s\">%s</text>\n", buffer_start_x, y, current_color, buffer
        }
    }
    
    function ansi256_to_rgb(n) {
        if (n < 16) {
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
            n = n - 16
            r = int(n / 36)
            g = int((n % 36) / 6)
            b = n % 6
            r = (r > 0) ? r * 40 + 55 : 0
            g = (g > 0) ? g * 40 + 55 : 0
            b = (b > 0) ? b * 40 + 55 : 0
            return sprintf("#%02x%02x%02x", r, g, b)
        } else {
            gray = (n - 232) * 10 + 8
            return sprintf("#%02x%02x%02x", gray, gray, gray)
        }
    }
    '
}

# ============================================================================
# PNG Export
# ============================================================================

# Convert ASCII art to PNG using ImageMagick
# Usage: export_png <ascii_content> <output_file> [background_color] [font]
# Returns: 0 on success, 1 on failure
export_png() {
    local content="$1"
    local output_file="$2"
    local bg_color="${3:-#1e1e1e}"
    local font="${4:-}"
    
    # Check for ImageMagick
    if ! command -v convert >/dev/null 2>&1; then
        log_error "PNG export requires ImageMagick (convert command not found)"
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
    export_svg "$content" "$bg_color" > "$tmpsvg"
    
    # Convert SVG to PNG
    local convert_args=(-background "$bg_color")
    
    # Add font if specified
    if [[ -n "$font" ]]; then
        convert_args+=(-font "$font")
    fi
    
    convert_args+=("$tmpsvg" "$output_file")
    
    if convert "${convert_args[@]}" 2>/dev/null; then
        return 0
    else
        log_error "Failed to convert SVG to PNG"
        return 1
    fi
}

# Alternative PNG export using direct text rendering (fallback)
# Usage: export_png_text <ascii_content> <output_file> [background_color] [font]
export_png_text() {
    local content="$1"
    local output_file="$2"
    local bg_color="${3:-#1e1e1e}"
    local font="${4:-Courier}"
    local font_size="${5:-12}"
    
    # Check for ImageMagick
    if ! command -v convert >/dev/null 2>&1; then
        log_error "PNG export requires ImageMagick"
        return 1
    fi
    
    # Strip ANSI codes for plain text rendering
    local plain_content
    plain_content=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
    
    # Create temporary file for text
    local tmptext
    tmptext=$(mktemp)
    echo -e "$plain_content" > "$tmptext"
    trap "rm -f '$tmptext'" RETURN
    
    # Convert text to PNG
    convert -background "$bg_color" \
            -fill "#00ff00" \
            -font "$font" \
            -pointsize "$font_size" \
            -interline-spacing 2 \
            label:@"$tmptext" \
            "$output_file"
}

# ============================================================================
# Export Dispatcher
# ============================================================================

# Export ASCII art to the specified format
# Usage: export_content <format> <content> <output_file> [options...]
# Returns: 0 on success, 1 on failure
export_content() {
    local format="$1"
    local content="$2"
    local output_file="$3"
    local bg_color="${4:-#1e1e1e}"
    
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
            export_html "$content" "$bg_color" > "$output_file"
            ;;
        svg)
            export_svg "$content" "$bg_color" > "$output_file"
            ;;
        png)
            export_png "$content" "$output_file" "$bg_color"
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
        *)    echo "txt" ;;
    esac
}
