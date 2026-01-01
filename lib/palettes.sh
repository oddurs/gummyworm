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
        emoji)    echo "  🌑🌒🌓🌔🌕" ;;
        stars)    echo " ·✦★✷✸✹" ;;
        hearts)   echo " ♡♥❤💖💗" ;;
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
    names=$(echo "$BUILTIN_PALETTE_NAMES" | tr ' ' '\n' | sort)
    
    for name in $names; do
        local chars
        chars=$(_get_builtin_palette "$name")
        local desc
        desc=$(_get_palette_description "$name")
        local char_count
        
        # Get visual character count (handles unicode)
        char_count=$(echo -n "$chars" | wc -m | tr -d ' ')
        
        printf "  ${COLOR_CYAN}%-12s${COLOR_RESET} │ %-20s │ %s\n" \
            "$name" "$chars" "($char_count chars) $desc"
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

# Parse palette into array (handles unicode)
# Usage: palette_to_array <palette_string> <array_name>
# Note: Uses eval for bash 3.x compatibility (no nameref)
palette_to_array() {
    local palette="$1"
    local arr_name="$2"
    
    # Clear the array
    eval "$arr_name=()"
    
    # Check if pure ASCII for fast path
    if echo "$palette" | grep -qE '^[[:print:]]*$' 2>/dev/null && \
       ! echo "$palette" | grep -q '[^[:ascii:]]' 2>/dev/null; then
        # Pure ASCII - simple indexing
        local i=0
        while [[ $i -lt ${#palette} ]]; do
            eval "$arr_name+=(\"\${palette:\$i:1}\")"
            i=$((i + 1))
        done
    else
        # Unicode - use python for reliable character splitting
        if command -v python3 >/dev/null 2>&1; then
            while IFS= read -r char; do
                eval "$arr_name+=(\"\$char\")"
            done < <(python3 -c "
import sys
for c in sys.argv[1]:
    print(c)
" "$palette")
        elif command -v python >/dev/null 2>&1; then
            while IFS= read -r char; do
                eval "$arr_name+=(\"\$char\")"
            done < <(python -c "
import sys
for c in sys.argv[1]:
    print(c)
" "$palette")
        else
            # Fallback: byte-by-byte (may not work for all unicode)
            local i=0
            while [[ $i -lt ${#palette} ]]; do
                eval "$arr_name+=(\"\${palette:\$i:1}\")"
                i=$((i + 1))
            done
        fi
    fi
}
