#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/cli.sh - Command-line interface
# ============================================================================
# Handles argument parsing, help display, and user interaction.
# Requires: lib/config.sh, lib/utils.sh, lib/palettes.sh, lib/image.sh (loaded below)
# ============================================================================

# Guard against multiple inclusion
[[ -n "${_GUMMYWORM_CLI_LOADED:-}" ]] && return 0
_GUMMYWORM_CLI_LOADED=1  # plain, not readonly: see config.sh's guard

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

# ============================================================================
# Banner & Help
# ============================================================================

# Display the ASCII art banner
show_banner() {
    # Decoration is for people; piped into a pager, grep or a file it is noise.
    [[ -t 1 ]] || return 0
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
    echo "    $GUMMYWORM_NAME [OPTIONS] [--] <image_file> [image_file2 ...]"
    echo "    $GUMMYWORM_NAME [OPTIONS] - < image_data  (stdin, also read when piped)"
    echo "    cat image.png | $GUMMYWORM_NAME [OPTIONS]"
    echo ""
    echo -e "${COLOR_BOLD}OPTIONS:${COLOR_RESET}"
    echo "    -w, --width <N>       Output width in characters (default: $DEFAULT_WIDTH)"
    echo "    -H, --height <N>      Output height in lines (default: auto)"
    echo "    -p, --palette <name>  Character palette to use (default: $DEFAULT_PALETTE)"
    echo "    -c, --color           Enable ANSI color output (256-color)"
    echo "    --truecolor           Enable true color (24-bit RGB) output"
    echo "    --no-truecolor        Disable true color (force 256-color)"
    echo "    -i, --invert          Invert brightness (dark ↔ light)"
    echo "    --brightness <N>      Adjust brightness (-100 to 100, default: 0)"
    echo "    --contrast <N>        Adjust contrast (-100 to 100, default: 0)"
    echo "    --gamma <N>           Adjust gamma (0.1 to 10.0, default: 1.0)"
    echo "    -f, --format <type>   Output format: text, ansi, html, svg, png, gif (default: text)"
    echo "    -o, --output <FILE>   Save output to file (or append in batch mode)"
    echo "    -d, --output-dir <DIR>  Save each output to directory with auto-naming"
    echo "    --background <color>  Background color for html/svg/png/gif (default: #1e1e1e)"
    echo "    --padding <N>         Padding in pixels for html/svg/png/gif (default: 0)"
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
    echo "    --enhance <mode>      Spread tones across the palette: off, stretch, full"
    echo "                          (default: $DEFAULT_ENHANCE). off keeps the image as it is."
    echo "    --char-aspect <N>     Terminal cell height:width (default: $DEFAULT_CHAR_ASPECT)"
    echo "                          Raise if output looks too tall, lower if too wide."
    echo "                          ~1.67 tight line spacing, 2.0 typical, 2.2+ loose."
    echo "    -h, --help            Show this help message"
    echo "    -V, --version         Show version information"
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
    # Initialize with config values (which default to DEFAULT_* if no config file)
    # Priority: DEFAULT_* < config file < CLI arguments
    ARG_WIDTH="$CONFIG_WIDTH"
    ARG_HEIGHT="$CONFIG_HEIGHT"
    ARG_PALETTE="$CONFIG_PALETTE"
    ARG_INVERT="$CONFIG_INVERT"
    ARG_COLOR="$CONFIG_COLOR"
    ARG_TRUECOLOR="$CONFIG_TRUECOLOR"
    ARG_OUTPUT="$DEFAULT_OUTPUT"  # Output is not configurable via file
    ARG_FORMAT="$CONFIG_FORMAT"
    ARG_BACKGROUND="$CONFIG_BACKGROUND"
    ARG_PADDING="$CONFIG_PADDING"
    ARG_OUTPUT_DIR=""
    ARG_RECURSIVE="false"
    ARG_CONTINUE_ON_ERROR="false"
    ARG_QUIET="$CONFIG_QUIET"
    ARG_PRESERVE_ASPECT="$CONFIG_PRESERVE_ASPECT"
    ARG_CHAR_ASPECT="$CONFIG_CHAR_ASPECT"
    ARG_ENHANCE="$CONFIG_ENHANCE"
    ARG_ANIMATE="$CONFIG_ANIMATE"
    ARG_FRAME_DELAY="$CONFIG_FRAME_DELAY"
    ARG_MAX_FRAMES="$CONFIG_MAX_FRAMES"
    ARG_LOOPS="$CONFIG_LOOPS"
    ARG_BRIGHTNESS="$CONFIG_BRIGHTNESS"
    ARG_CONTRAST="$CONFIG_CONTRAST"
    ARG_GAMMA="$CONFIG_GAMMA"
    ARG_IMAGES=()
    ARG_IMAGE_ROOTS=()
    ARG_STDIN_REQUESTED="false"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -w|--width)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                is_positive_int "$2" || die_usage "Width must be a positive integer"
                ARG_WIDTH="$2"
                shift 2
                ;;
            -h)
                # -h used to mean --height. It means help now, as everywhere
                # else, but '-h 40' keeps working for a while so scripts that
                # wrote it do not break: a bare number after -h is a height.
                if [[ "${2:-}" =~ ^[0-9]+$ ]]; then
                    log_warn "'-h <N>' for height is deprecated and will become help; use -H or --height"
                    is_non_negative_int "$2" || die_usage "Height must be a non-negative integer"
                    ARG_HEIGHT="$2"
                    shift 2
                else
                    show_help
                    exit 0
                fi
                ;;
            -H|--height)
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
            --brightness)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                # Validate range: -100 to 100
                if ! [[ "$2" =~ ^-?[0-9]+$ ]] || [[ "$2" -lt -100 ]] || [[ "$2" -gt 100 ]]; then
                    die_usage "Brightness must be an integer between -100 and 100"
                fi
                ARG_BRIGHTNESS="$2"
                shift 2
                ;;
            --contrast)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                # Validate range: -100 to 100
                if ! [[ "$2" =~ ^-?[0-9]+$ ]] || [[ "$2" -lt -100 ]] || [[ "$2" -gt 100 ]]; then
                    die_usage "Contrast must be an integer between -100 and 100"
                fi
                ARG_CONTRAST="$2"
                shift 2
                ;;
            --gamma)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                # Validate: positive number (0.1 to 10.0)
                if ! [[ "$2" =~ ^[0-9]*\.?[0-9]+$ ]]; then
                    die_usage "Gamma must be a positive number (e.g., 0.5, 1.0, 2.2)"
                fi
                # Check range using awk (bash can't do float comparison easily)
                if ! awk -v g="$2" 'BEGIN { exit !(g >= 0.1 && g <= 10.0) }'; then
                    die_usage "Gamma must be between 0.1 and 10.0"
                fi
                ARG_GAMMA="$2"
                shift 2
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
                is_valid_color "$2" || die_usage "Background must be a hex colour (#RGB or #RRGGBB) or a named colour"
                ARG_BACKGROUND="$2"
                shift 2
                ;;
            --padding)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                if ! [[ "$2" =~ $RE_INTEGER ]]; then
                    die_usage "Padding must be a non-negative integer"
                fi
                ARG_PADDING="$2"
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
            --enhance)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                if ! [[ "$2" =~ $RE_CFG_ENHANCE ]]; then
                    die_usage "Enhance must be one of: off, stretch, full"
                fi
                ARG_ENHANCE="$2"
                shift 2
                ;;
            --char-aspect)
                [[ -z "${2:-}" ]] && die_usage "Option $1 requires an argument"
                if ! [[ "$2" =~ ^[0-9]*\.?[0-9]+$ ]]; then
                    die_usage "Character aspect must be a positive number (e.g., 1.67, 2.0, 2.2)"
                fi
                # Range check in awk; bash cannot compare floats
                if ! awk -v a="$2" 'BEGIN { exit !(a >= 0.5 && a <= 5.0) }'; then
                    die_usage "Character aspect must be between 0.5 and 5.0"
                fi
                ARG_CHAR_ASPECT="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            -V|--version)
                show_version
                exit 0
                ;;
            -)
                # A lone dash means standard input, as in most tools
                ARG_STDIN_REQUESTED="true"
                shift
                ;;
            --)
                # End of options: everything after is an input, even if it
                # starts with a dash (e.g. a file named -cover.png).
                shift
                while [[ $# -gt 0 ]]; do
                    ARG_IMAGES+=("$1")
                    shift
                done
                break
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
    
    # The character aspect is read deep in the dimension maths and again by the
    # exporter, neither of which sees ARG_*. Publish the resolved value (default
    # < config file < CLI) as the config global both already read.
    CONFIG_CHAR_ASPECT="$ARG_CHAR_ASPECT"
    export CONFIG_CHAR_ASPECT

    # Likewise for enhance: image_extract_pixels reads it, not ARG_*.
    CONFIG_ENHANCE="$ARG_ENHANCE"
    export CONFIG_ENHANCE

    # Now expand directories and handle special inputs
    # Only process if we have inputs (handles empty array in strict mode)
    # Whether any input argument was given at all. Stdin is only the source
    # when none was; an explicit directory that yields no images is an error
    # about that directory, not a cue to read stdin.
    local had_input_args="false"
    if [[ ${#ARG_IMAGES[@]} -gt 0 ]]; then
        had_input_args="true"
        local raw_inputs=("${ARG_IMAGES[@]}")
        ARG_IMAGES=()
        # For each image, the directory argument it was expanded from, or "" if
        # it was named directly. Output naming uses this to mirror the input
        # tree, so two files with the same name in different subdirectories do
        # not write to the same output path. Index-aligned with ARG_IMAGES.
        ARG_IMAGE_ROOTS=()

        for input in "${raw_inputs[@]}"; do
            if is_url "$input"; then
                ARG_IMAGES+=("$input")
                ARG_IMAGE_ROOTS+=("")
            elif [[ -d "$input" ]]; then
                # Directory input - expand to image files
                local found_images=0
                # Normalise away a trailing slash so stripping the root later
                # leaves a clean relative path.
                local root="${input%/}"
                while IFS= read -r -d '' img; do
                    ARG_IMAGES+=("$img")
                    ARG_IMAGE_ROOTS+=("$root")
                    found_images=$((found_images + 1))
                done < <(find_images_in_dir "$input" "$ARG_RECURSIVE")
                if [[ $found_images -eq 0 ]]; then
                    log_warn "No images found in directory: $input"
                fi
            else
                # Regular file
                ARG_IMAGES+=("$input")
                ARG_IMAGE_ROOTS+=("")
            fi
        done
    fi
    
    # Inputs were named but none of them produced an image. Each empty
    # directory has already been warned about above.
    if [[ "$had_input_args" == "true" && ${#ARG_IMAGES[@]} -eq 0 ]]; then
        die "No images found in the given input"
    fi

    # Standard input is the source when '-' names it, or when nothing else was
    # given and it is piped. With nothing to read and a terminal on stdin, say
    # how to use the command instead of waiting on a keyboard, and exit 2.
    if [[ "$ARG_STDIN_REQUESTED" == "true" || ${#ARG_IMAGES[@]} -eq 0 ]]; then
        if [[ "$ARG_STDIN_REQUESTED" == "true" || ! -t 0 ]]; then
            ARG_STDIN_TEMP="$(image_from_stdin)" || exit 1
            ARG_IMAGES+=("$ARG_STDIN_TEMP")
            ARG_IMAGE_ROOTS+=("")
        else
            {
                echo "Usage: $GUMMYWORM_NAME [OPTIONS] [--] <image_file>..."
                echo "       $GUMMYWORM_NAME [OPTIONS] - < image_data"
                echo "Try '$GUMMYWORM_NAME --help' for more information."
            } >&2
            exit 2
        fi
    fi

    # An output file has to be writable before any work is done on its behalf.
    # Otherwise the failure surfaces as a raw redirection error from deep in the
    # exporter, with a library line number.
    if [[ -n "$ARG_OUTPUT" ]]; then
        local out_dir
        out_dir="$(dirname -- "$ARG_OUTPUT")"
        [[ -d "$out_dir" ]] || die "Cannot write to $ARG_OUTPUT: directory $out_dir does not exist"
        if [[ -e "$ARG_OUTPUT" && ! -w "$ARG_OUTPUT" ]] || [[ ! -e "$ARG_OUTPUT" && ! -w "$out_dir" ]]; then
            die "Cannot write to $ARG_OUTPUT: permission denied"
        fi
    fi
    
    # Validate output-dir if specified
    if [[ -n "$ARG_OUTPUT_DIR" ]]; then
        mkdir -p "$ARG_OUTPUT_DIR" 2>/dev/null || die "Cannot create output directory: $ARG_OUTPUT_DIR"
    fi
}
