#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/cli.sh - Command-line interface
# ============================================================================
# Handles argument parsing, help display, and user interaction.
# Requires: lib/config.sh, lib/utils.sh, lib/palettes.sh
# ============================================================================

# Guard against multiple inclusion
[[ -n "${_GUMMYWORM_CLI_LOADED:-}" ]] && return 0
readonly _GUMMYWORM_CLI_LOADED=1

# ============================================================================
# Banner & Help
# ============================================================================

# Display the ASCII art banner
show_banner() {
    cat << 'EOF'

 ██████╗ ██╗   ██╗███╗   ███╗███╗   ███╗██╗   ██╗██╗    ██╗ ██████╗ ██████╗ ███╗   ███╗
██╔════╝ ██║   ██║████╗ ████║████╗ ████║╚██╗ ██╔╝██║    ██║██╔═══██╗██╔══██╗████╗ ████║
██║  ███╗██║   ██║██╔████╔██║██╔████╔██║ ╚████╔╝ ██║ █╗ ██║██║   ██║██████╔╝██╔████╔██║
██║   ██║██║   ██║██║╚██╔╝██║██║╚██╔╝██║  ╚██╔╝  ██║███╗██║██║   ██║██╔══██╗██║╚██╔╝██║
╚██████╔╝╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║ ╚═╝ ██║
 ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝

    🐛 Transform images into glorious ASCII art! 🐛

EOF
}

# Display help message
show_help() {
    show_banner
    echo -e "${COLOR_BOLD}USAGE:${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME [OPTIONS] <image_file> [image_file2 ...]"
    echo "    $GUMMYWORM_NAME [OPTIONS] < image_data    (stdin)"
    echo "    cat image.png | $GUMMYWORM_NAME [OPTIONS]"
    echo ""
    echo -e "${COLOR_BOLD}OPTIONS:${COLOR_RESET}"
    echo "    -w, --width <N>       Output width in characters (default: $DEFAULT_WIDTH)"
    echo "    -h, --height <N>      Output height in lines (default: auto)"
    echo "    -p, --palette <name>  Character palette to use (default: $DEFAULT_PALETTE)"
    echo "    -c, --color           Enable ANSI color output (256-color)"
    echo "    --truecolor           Enable true color (24-bit RGB) output"
    echo "    --no-truecolor        Disable true color (force 256-color)"
    echo "    -i, --invert          Invert brightness (dark ↔ light)"
    echo "    -f, --format <type>   Output format: text, ansi, html, svg, png, gif (default: text)"
    echo "    -o, --output <FILE>   Save output to file (or append in batch mode)"
    echo "    -d, --output-dir <DIR>  Save each output to directory with auto-naming"
    echo "    --background <color>  Background color for html/svg/png (default: #1e1e1e)"
    echo "    -a, --animate         Enable animation processing for GIFs"
    echo "    --no-animate          Disable animation (extract first frame only)"
    echo "    --frame-delay <N>     Delay between frames in ms for playback (default: $DEFAULT_FRAME_DELAY)"
    echo "    --max-frames <N>      Maximum frames to process (default: 0 = all)"
    echo "    --loops <N>           Loop count for playback/export (default: 0 = infinite)"
    echo "    -r, --recursive       Process directories recursively"
    echo "    -l, --list-palettes   Show available character palettes"
    echo "    -q, --quiet           Suppress info messages"
    echo "    --continue-on-error   Continue processing if one file fails"
    echo "    --no-aspect           Don't preserve aspect ratio"
    echo "    --help                Show this help message"
    echo "    --version             Show version information"
    echo ""
    echo -e "${COLOR_BOLD}EXAMPLES:${COLOR_RESET}"
    echo -e "    ${COLOR_CYAN}# Basic conversion${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME photo.jpg"
    echo ""
    echo -e "    ${COLOR_CYAN}# Colored output, 100 characters wide${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -c -w 100 landscape.png"
    echo ""
    echo -e "    ${COLOR_CYAN}# Use block characters, inverted${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -p blocks -i portrait.jpg"
    echo ""
    echo -e "    ${COLOR_CYAN}# Emoji mode! 🌕${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -p emoji sunset.png"
    echo ""
    echo -e "    ${COLOR_CYAN}# Save to file${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -o art.txt -w 120 image.jpg"
    echo ""
    echo -e "    ${COLOR_CYAN}# Custom palette${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -p \" .oO0@#\" image.jpg"
    echo ""
    echo -e "    ${COLOR_CYAN}# Batch processing - multiple files${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME *.jpg *.png"
    echo ""
    echo -e "    ${COLOR_CYAN}# Batch to directory with auto-naming${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -d output/ photos/*.jpg"
    echo ""
    echo -e "    ${COLOR_CYAN}# Process directory recursively${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -r -d ascii_art/ ./images/"
    echo ""
    echo -e "    ${COLOR_CYAN}# From URL${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME https://example.com/image.jpg"
    echo ""
    echo -e "    ${COLOR_CYAN}# From stdin (pipe)${COLOR_RESET}"
    echo "    curl -s https://example.com/image.jpg | $GUMMYWORM_NAME"
    echo ""
    echo -e "    ${COLOR_CYAN}# Export as HTML (auto-detected from extension)${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -o gallery.html photo.jpg"
    echo ""
    echo -e "    ${COLOR_CYAN}# Export as SVG with custom background${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -f svg --background '#000000' -o art.svg image.png"
    echo ""
    echo -e "    ${COLOR_CYAN}# Export as PNG image${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -f png -o artwork.png photo.jpg"
    echo ""
    echo -e "    ${COLOR_CYAN}# Play animated GIF in terminal${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -c -a animation.gif"
    echo ""
    echo -e "    ${COLOR_CYAN}# Export animated GIF as ASCII GIF${COLOR_RESET}"
    echo "    $GUMMYWORM_NAME -f gif -o ascii.gif animation.gif"
    echo ""
    echo -e "${COLOR_BOLD}INPUT FORMATS:${COLOR_RESET}"
    echo "    JPEG, PNG, GIF, BMP, TIFF, WebP, and any format supported by ImageMagick"
    echo ""
    echo -e "${COLOR_BOLD}OUTPUT FORMATS:${COLOR_RESET}"
    echo "    text     Plain ASCII text (default)"
    echo "    ansi     ANSI colored text for terminal"
    echo "    html     HTML document with CSS styling"
    echo "    svg      Scalable Vector Graphics"
    echo "    png      PNG image (requires ImageMagick)"
    echo "    gif      Animated GIF (for animated inputs)"
    echo ""
    echo -e "${COLOR_BOLD}PRO TIPS:${COLOR_RESET}"
    echo "    🎨 Use --color for terminal display, omit for plain text files"
    echo "    📐 Wider outputs = more detail (try -w 120 or -w 200)"
    echo "    🌙 Use --invert for images with dark backgrounds"
    echo "    🔲 The 'blocks' palette looks great for high-contrast images"
    echo "    🐛 Try 'emoji' palette for fun social media posts!"
    echo ""
}

# Display version
show_version() {
    echo "$GUMMYWORM_NAME version $GUMMYWORM_VERSION"
    echo "A playful image-to-ASCII converter"
}

# Display palette list
show_palettes() {
    show_banner
    echo -e "${COLOR_BOLD}Available Character Palettes:${COLOR_RESET}\n"
    palette_list
    echo ""
    echo -e "${COLOR_BOLD}Custom Palettes:${COLOR_RESET}"
    echo "  You can pass any string of characters as a custom palette:"
    echo -e "  ${COLOR_CYAN}$GUMMYWORM_NAME -p \" .oO0@\" image.jpg${COLOR_RESET}"
    echo ""
    echo "  Or create palette files in: $GUMMYWORM_PALETTES_DIR/"
    echo ""
}

# ============================================================================
# Argument Parsing
# ============================================================================

# Parse command line arguments
# Usage: parse_args "$@"
# Sets global variables: ARG_*
parse_args() {
    # Initialize with defaults
    ARG_WIDTH="$DEFAULT_WIDTH"
    ARG_HEIGHT="$DEFAULT_HEIGHT"
    ARG_PALETTE="$DEFAULT_PALETTE"
    ARG_INVERT="$DEFAULT_INVERT"
    ARG_COLOR="$DEFAULT_COLOR"
    ARG_TRUECOLOR="$DEFAULT_TRUECOLOR"
    ARG_OUTPUT="$DEFAULT_OUTPUT"
    ARG_FORMAT="$DEFAULT_FORMAT"
    ARG_BACKGROUND="$DEFAULT_BACKGROUND"
    ARG_OUTPUT_DIR=""
    ARG_RECURSIVE="false"
    ARG_CONTINUE_ON_ERROR="false"
    ARG_QUIET="$DEFAULT_QUIET"
    ARG_PRESERVE_ASPECT="$DEFAULT_PRESERVE_ASPECT"
    ARG_ANIMATE="$DEFAULT_ANIMATE"
    ARG_FRAME_DELAY="$DEFAULT_FRAME_DELAY"
    ARG_MAX_FRAMES="$DEFAULT_MAX_FRAMES"
    ARG_LOOPS="$DEFAULT_LOOPS"
    ARG_IMAGES=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w|--width)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                is_positive_int "$2" || die_usage "Width must be a positive integer"
                ARG_WIDTH="$2"
                shift 2
                ;;
            -h|--height)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                is_non_negative_int "$2" || die_usage "Height must be a non-negative integer"
                ARG_HEIGHT="$2"
                shift 2
                ;;
            -p|--palette)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                ARG_PALETTE="$2"
                shift 2
                ;;
            -c|--color)
                ARG_COLOR="true"
                shift
                ;;
            --truecolor)
                ARG_TRUECOLOR="true"
                ARG_COLOR="true"  # Implicitly enable color
                shift
                ;;
            --no-truecolor)
                ARG_TRUECOLOR="false"
                shift
                ;;
            -i|--invert)
                ARG_INVERT="true"
                shift
                ;;
            -f|--format)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                # Validate format
                case "$2" in
                    text|ansi|html|svg|png|gif)
                        ARG_FORMAT="$2"
                        ;;
                    *)
                        die_usage "Invalid format: $2 (valid: text, ansi, html, svg, png, gif)"
                        ;;
                esac
                shift 2
                ;;
            --background)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                ARG_BACKGROUND="$2"
                shift 2
                ;;
            -o|--output)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                ARG_OUTPUT="$2"
                shift 2
                ;;
            -d|--output-dir)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                ARG_OUTPUT_DIR="$2"
                shift 2
                ;;
            -r|--recursive)
                ARG_RECURSIVE="true"
                shift
                ;;
            -a|--animate)
                ARG_ANIMATE="true"
                shift
                ;;
            --no-animate)
                ARG_ANIMATE="false"
                shift
                ;;
            --frame-delay)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                is_positive_int "$2" || die_usage "Frame delay must be a positive integer"
                ARG_FRAME_DELAY="$2"
                shift 2
                ;;
            --max-frames)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                is_non_negative_int "$2" || die_usage "Max frames must be a non-negative integer"
                ARG_MAX_FRAMES="$2"
                shift 2
                ;;
            --loops)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                is_non_negative_int "$2" || die_usage "Loops must be a non-negative integer"
                ARG_LOOPS="$2"
                shift 2
                ;;
            --continue-on-error)
                ARG_CONTINUE_ON_ERROR="true"
                shift
                ;;
            -l|--list-palettes)
                show_palettes
                exit 0
                ;;
            -q|--quiet)
                ARG_QUIET="true"
                shift
                ;;
            --no-aspect)
                ARG_PRESERVE_ASPECT="false"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            -*)
                die_usage "Unknown option: $1"
                ;;
            *)
                # Collect raw inputs - will expand after all options parsed
                ARG_IMAGES+=("$1")
                shift
                ;;
        esac
    done
    
    # Now expand directories and handle special inputs
    # Only process if we have inputs (handles empty array in strict mode)
    if [[ ${#ARG_IMAGES[@]} -gt 0 ]]; then
        local raw_inputs=("${ARG_IMAGES[@]}")
        ARG_IMAGES=()
        
        for input in "${raw_inputs[@]}"; do
            if is_url "$input"; then
                ARG_IMAGES+=("$input")
            elif [[ -d "$input" ]]; then
                # Directory input - expand to image files
                local found_images=0
                while IFS= read -r -d '' img; do
                    ARG_IMAGES+=("$img")
                    found_images=$((found_images + 1))
                done < <(find_images_in_dir "$input" "$ARG_RECURSIVE")
                if [[ $found_images -eq 0 ]]; then
                    log_warn "No images found in directory: $input"
                fi
            else
                # Regular file
                ARG_IMAGES+=("$input")
            fi
        done
    fi
    
    # Check for stdin input if no images provided
    if [[ ${#ARG_IMAGES[@]} -eq 0 ]]; then
        if [[ ! -t 0 ]]; then
            # stdin is piped - save to temp file
            ARG_IMAGES+=("$(image_from_stdin)")
            ARG_STDIN_TEMP="${ARG_IMAGES[0]}"
        else
            show_help
            exit 1
        fi
    fi
    
    # Validate output-dir if specified
    if [[ -n "$ARG_OUTPUT_DIR" ]]; then
        mkdir -p "$ARG_OUTPUT_DIR" 2>/dev/null || die "Cannot create output directory: $ARG_OUTPUT_DIR"
    fi
}
