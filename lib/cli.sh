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
    echo "    $GUMMYWORM_NAME [OPTIONS] <image_file>"
    echo ""
    echo -e "${COLOR_BOLD}OPTIONS:${COLOR_RESET}"
    echo "    -w, --width <N>       Output width in characters (default: $DEFAULT_WIDTH)"
    echo "    -h, --height <N>      Output height in lines (default: auto)"
    echo "    -p, --palette <name>  Character palette to use (default: $DEFAULT_PALETTE)"
    echo "    -c, --color           Enable ANSI color output"
    echo "    -i, --invert          Invert brightness (dark ↔ light)"
    echo "    -o, --output <FILE>   Save output to file instead of stdout"
    echo "    -l, --list-palettes   Show available character palettes"
    echo "    -q, --quiet           Suppress info messages"
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
    echo -e "${COLOR_BOLD}SUPPORTED FORMATS:${COLOR_RESET}"
    echo "    JPEG, PNG, GIF, BMP, TIFF, WebP, and any format supported by ImageMagick"
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
    ARG_OUTPUT="$DEFAULT_OUTPUT"
    ARG_QUIET="$DEFAULT_QUIET"
    ARG_PRESERVE_ASPECT="$DEFAULT_PRESERVE_ASPECT"
    ARG_IMAGE=""
    
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
            -i|--invert)
                ARG_INVERT="true"
                shift
                ;;
            -o|--output)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                ARG_OUTPUT="$2"
                shift 2
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
                if [[ -z "$ARG_IMAGE" ]]; then
                    ARG_IMAGE="$1"
                else
                    die_usage "Multiple images specified. Process one at a time."
                fi
                shift
                ;;
        esac
    done
    
    # Validate required args
    if [[ -z "$ARG_IMAGE" ]]; then
        show_help
        exit 1
    fi
}
