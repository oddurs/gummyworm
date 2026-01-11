# bash completion for gummyworm                            -*- shell-script -*-
# ============================================================================
# gummyworm bash completion
# ============================================================================
# Installation:
#   Option 1: Source directly in ~/.bashrc:
#     source /path/to/gummyworm/completions/gummyworm.bash
#
#   Option 2: Copy to system completions directory:
#     sudo cp gummyworm.bash /etc/bash_completion.d/gummyworm
#
#   Option 3: Homebrew (automatic):
#     Completions are installed to $(brew --prefix)/etc/bash_completion.d/
# ============================================================================

_gummyworm_completions() {
    local cur prev words cword
    _init_completion || return

    # All options
    local opts="
        -w --width
        -h --height
        -p --palette
        -c --color
        --truecolor --no-truecolor
        -i --invert
        --brightness --contrast --gamma
        -f --format
        -o --output
        -d --output-dir
        --background --padding
        -a --animate --no-animate
        --frame-delay --max-frames --loops
        -r --recursive
        -l --list-palettes
        -q --quiet
        --continue-on-error --no-aspect
        --help --version
    "

    # Built-in palettes
    local palettes="standard detailed simple blocks binary shades retro matrix emoji dots stars hearts waves"

    # Output formats
    local formats="text ansi html svg png gif"

    case "$prev" in
        -w|--width|-h|--height|--frame-delay|--max-frames|--loops|--padding)
            # Numeric argument - no completion
            return
            ;;
        --brightness|--contrast)
            # Numeric range - suggest common values
            COMPREPLY=($(compgen -W "-50 -25 0 25 50" -- "$cur"))
            return
            ;;
        --gamma)
            # Gamma values
            COMPREPLY=($(compgen -W "0.5 0.7 1.0 1.2 1.5 2.0 2.2" -- "$cur"))
            return
            ;;
        -p|--palette)
            # Complete palette names
            # Also check for custom palettes in palettes/ directory
            local custom_palettes=""
            if [[ -d "${GUMMYWORM_ROOT:-}/palettes" ]]; then
                custom_palettes=$(find "${GUMMYWORM_ROOT}/palettes" -name "*.palette" -exec basename {} .palette \; 2>/dev/null | grep -v "^_")
            fi
            COMPREPLY=($(compgen -W "$palettes $custom_palettes" -- "$cur"))
            return
            ;;
        -f|--format)
            COMPREPLY=($(compgen -W "$formats" -- "$cur"))
            return
            ;;
        -o|--output)
            # File completion
            _filedir
            return
            ;;
        -d|--output-dir)
            # Directory completion
            _filedir -d
            return
            ;;
        --background)
            # Common background colors
            COMPREPLY=($(compgen -W "#000000 #1e1e1e #ffffff #282c34 transparent" -- "$cur"))
            return
            ;;
    esac

    # If current word starts with -, complete options
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
        return
    fi

    # Default: complete image files and directories
    _filedir '@(jpg|jpeg|png|gif|bmp|tiff|tif|webp|JPG|JPEG|PNG|GIF|BMP|TIFF|TIF|WEBP)'
}

# Register the completion function
complete -F _gummyworm_completions gummyworm
