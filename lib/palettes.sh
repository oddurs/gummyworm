#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/palettes.sh - Character palette management
# ============================================================================
# Handles loading, listing, and managing character palettes for ASCII art.
# Compatible with bash 3.x (no associative arrays)
# Requires: lib/config.sh, lib/utils.sh
# ============================================================================

# Guard against multiple inclusion
[[ -n "${_GUMMYWORM_PALETTES_LOADED:-}" ]] && return 0
readonly _GUMMYWORM_PALETTES_LOADED=1

# ============================================================================
# Built-in Palettes
# ============================================================================
# Using functions instead of associative arrays for bash 3.x compatibility

# Get built-in palette by name
# Note: Wide-char palettes (emoji, hearts) use full-width space (U+3000) for alignment
_get_builtin_palette() {
    case "$1" in
        standard) echo " .:-=+*#%@" ;;
        detailed) echo " .'°\`^\",:;Il!i><~+_-?][}{1)(|\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@\$" ;;
        simple)   echo " .oO@" ;;
        binary)   echo " █" ;;
        matrix)   echo " 01" ;;
        blocks)   echo " ░▒▓█" ;;
        shades)   echo " ░▒▓█▓▒░" ;;
        retro)    echo " .:░▒▓█" ;;
        dots)     echo " ⠁⠃⠇⠿⣿" ;;
        emoji)    echo "　🌑🌒🌓🌔🌕" ;;
        stars)    echo " ·✦★✷✸✹" ;;
        hearts)   echo "　🤍💓💗💖💘" ;;
        *)        return 1 ;;
    esac
}

# Get palette description
_get_palette_description() {
    case "$1" in
        standard) echo "General purpose, good balance" ;;
        detailed) echo "Maximum detail, 72 ASCII chars" ;;
        simple)   echo "Quick previews, minimal chars" ;;
        binary)   echo "Silhouettes, two-tone" ;;
        matrix)   echo "Hacker/Matrix aesthetic" ;;
        blocks)   echo "Unicode blocks, high contrast" ;;
        shades)   echo "Symmetric shading effect" ;;
        retro)    echo "Retro computing style" ;;
        dots)     echo "Braille-style patterns" ;;
        emoji)    echo "Moon phases, fun for social" ;;
        stars)    echo "Dreamy, sparkly effect" ;;
        hearts)   echo "Love-themed art" ;;
        *)        echo "" ;;
    esac
}

# List of all built-in palette names
BUILTIN_PALETTE_NAMES="standard detailed simple binary matrix blocks shades retro dots emoji stars hearts"

# ============================================================================
# Palette Functions
# ============================================================================

# Get a palette by name (built-in or custom file)
# Usage: palette_get <n>
# Returns: palette string via stdout, or empty if not found
palette_get() {
    local name="$1"
    local result
    
    # Check built-in palettes first
    if result=$(_get_builtin_palette "$name" 2>/dev/null); then
        echo "$result"
        return 0
    fi
    
    # Check for custom palette file
    local palette_file="${GUMMYWORM_PALETTES_DIR}/${name}.palette"
    if [[ -f "$palette_file" ]]; then
        # Read first non-comment, non-empty line
        grep -v '^#' "$palette_file" | grep -v '^$' | head -1
        return 0
    fi
    
    # Not found - might be a custom inline palette
    return 1
}

# Check if a palette exists
# Usage: palette_exists <n>
palette_exists() {
    local name="$1"
    _get_builtin_palette "$name" >/dev/null 2>&1 || \
    [[ -f "${GUMMYWORM_PALETTES_DIR}/${name}.palette" ]]
}

# List all available palettes
# Usage: palette_list
palette_list() {
    echo "Built-in palettes:"
    echo ""
    
    # Sort palette names
    local names
    names=$(tr ' ' '\n' <<< "$BUILTIN_PALETTE_NAMES" | sort)
    
    for name in $names; do
        local chars
        chars=$(_get_builtin_palette "$name")
        local desc
        desc=$(_get_palette_description "$name")
        local char_count
        
        # Get visual character count (handles unicode)
        char_count=$(echo -n "$chars" | wc -m | tr -d ' ')
        
        # Calculate terminal display width (accounts for wide chars like emojis)
        local display_width=20
        local visual_len
        visual_len=$(str_display_width "$chars")
        
        # Truncate long palettes and add ellipsis
        local display_chars="$chars"
        if [[ "$visual_len" -gt "$display_width" ]]; then
            # Truncate character by character until we fit
            display_chars=""
            local current_width=0
            local max_width=$((display_width - 1))
            while IFS= read -r char; do
                local char_width
                char_width=$(str_display_width "$char")
                if [[ $((current_width + char_width)) -le $max_width ]]; then
                    display_chars+="$char"
                    current_width=$((current_width + char_width))
                else
                    break
                fi
            done < <(echo -n "$chars" | grep -o .)
            display_chars+="…"
            visual_len=$((current_width + 1))
        fi
        
        local padding=$((display_width - visual_len))
        [[ "$padding" -lt 0 ]] && padding=0
        local padded_chars="$display_chars$(printf '%*s' "$padding" '')"
        
        printf "  ${COLOR_CYAN}%-12s${COLOR_RESET} │ %s │ %s\n" \
            "$name" "$padded_chars" "($char_count chars) $desc"
    done
    
    # Check for custom palettes
    if [[ -d "$GUMMYWORM_PALETTES_DIR" ]]; then
        local custom_palettes
        custom_palettes=$(find "$GUMMYWORM_PALETTES_DIR" -name "*.palette" 2>/dev/null | wc -l | tr -d ' ')
        
        if [[ "$custom_palettes" -gt 0 ]]; then
            echo ""
            echo "Custom palettes (in $GUMMYWORM_PALETTES_DIR):"
            for f in "$GUMMYWORM_PALETTES_DIR"/*.palette; do
                [[ -f "$f" ]] || continue
                local pname
                pname=$(basename "$f" .palette)
                local pchars
                pchars=$(grep -v '^#' "$f" | grep -v '^$' | head -1)
                printf "  ${COLOR_CYAN}%-12s${COLOR_RESET} │ %s\n" "$pname" "$pchars"
            done
        fi
    fi
}

# Validate a palette string
# Usage: palette_validate <palette_string>
# Returns: 0 if valid, 1 if invalid
palette_validate() {
    local palette="$1"
    local len
    
    len=$(echo -n "$palette" | wc -m | tr -d ' ')
    
    if [[ "$len" -lt 2 ]]; then
        log_error "Palette must have at least 2 characters"
        return 1
    fi
    
    return 0
}

# Check if palette contains wide characters (emojis, CJK, etc.)
# Usage: palette_has_wide_chars <palette_string>
# Returns: 0 if has wide chars, 1 if not
palette_has_wide_chars() {
    local palette="$1"
    local char_count display_width
    char_count=$(echo -n "$palette" | wc -m | tr -d ' ')
    display_width=$(str_display_width "$palette")
    [[ "$display_width" -gt "$char_count" ]]
}

# Get the maximum display width of any character in the palette (1 or 2)
# Usage: palette_char_width <palette_string>
# Returns: 1 for normal chars, 2 if any wide chars exist
palette_char_width() {
    local palette="$1"
    if palette_has_wide_chars "$palette"; then
        echo 2
    else
        echo 1
    fi
}

# Parse palette into array (handles unicode)
# Usage: palette_to_array <palette_string> <array_name>
# Note: Uses eval for bash 3.x compatibility (no nameref)
palette_to_array() {
    local palette="$1"
    local arr_name="$2"
    
    # Clear the array
    eval "$arr_name=()"
    
    # Check if pure ASCII for fast path (no external tools needed)
    if [[ "$palette" =~ ^[[:print:]]*$ ]] && ! [[ "$palette" =~ [^[:ascii:]] ]]; then
        # Pure ASCII - simple indexing (fastest)
        local i=0
        while [[ $i -lt ${#palette} ]]; do
            eval "$arr_name+=(\"\${palette:\$i:1}\")"
            i=$((i + 1))
        done
    else
        # Unicode - use awk for reliable character splitting (faster than Python)
        # LC_ALL=C.UTF-8 ensures proper Unicode handling
        while IFS= read -r char; do
            [[ -n "$char" ]] && eval "$arr_name+=(\"\$char\")"
        done < <(printf '%s' "$palette" | LC_ALL=C.UTF-8 awk '{
            # Split string into individual characters
            n = split($0, chars, "")
            for (i = 1; i <= n; i++) {
                print chars[i]
            }
        }')
        
        # Fallback to Python if awk failed (some systems may have issues)
        if [[ $(eval "echo \${#$arr_name[@]}") -eq 0 ]]; then
            if command -v python3 >/dev/null 2>&1; then
                while IFS= read -r char; do
                    eval "$arr_name+=(\"\$char\")"
                done < <(python3 -c "import sys; [print(c) for c in sys.argv[1]]" "$palette")
            fi
        fi
    fi
}
