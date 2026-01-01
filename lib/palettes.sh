#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/palettes.sh - Character palette management
# ============================================================================
# Handles loading, listing, and managing character palettes for ASCII art.
# Requires: lib/config.sh, lib/utils.sh
# ============================================================================

# Guard against multiple inclusion
[[ -n "${_GUMMYWORM_PALETTES_LOADED:-}" ]] && return 0
readonly _GUMMYWORM_PALETTES_LOADED=1

# ============================================================================
# Built-in Palettes
# ============================================================================
# Characters ordered from darkest/empty to brightest/filled

declare -gA BUILTIN_PALETTES=(
    # Standard ASCII palettes
    ["standard"]=" .:-=+*#%@"
    ["detailed"]=" .'°\`^\",:;Il!i><~+_-?][}{1)(|\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@\$"
    ["simple"]=" .oO@"
    ["binary"]=" █"
    ["matrix"]=" 01"
    
    # Unicode block palettes
    ["blocks"]=" ░▒▓█"
    ["shades"]=" ░▒▓█▓▒░"
    ["retro"]=" .:░▒▓█"
    ["dots"]=" ⠁⠃⠇⠿⣿"
    
    # Fun/decorative palettes  
    ["emoji"]="  🌑🌒🌓🌔🌕"
    ["stars"]=" ·✦★✷✸✹"
    ["hearts"]=" ♡♥❤💖💗"
)

# Palette descriptions for help text
declare -gA PALETTE_DESCRIPTIONS=(
    ["standard"]="General purpose, good balance"
    ["detailed"]="Maximum detail, 72 ASCII chars"
    ["simple"]="Quick previews, minimal chars"
    ["binary"]="Silhouettes, two-tone"
    ["matrix"]="Hacker/Matrix aesthetic"
    ["blocks"]="Unicode blocks, high contrast"
    ["shades"]="Symmetric shading effect"
    ["retro"]="Retro computing style"
    ["dots"]="Braille-style patterns"
    ["emoji"]="Moon phases, fun for social"
    ["stars"]="Dreamy, sparkly effect"
    ["hearts"]="Love-themed art"
)

# ============================================================================
# Palette Functions
# ============================================================================

# Get a palette by name (built-in or custom file)
# Usage: palette_get <name>
# Returns: palette string via stdout, or empty if not found
palette_get() {
    local name="$1"
    
    # Check built-in palettes first
    if [[ -n "${BUILTIN_PALETTES[$name]:-}" ]]; then
        echo "${BUILTIN_PALETTES[$name]}"
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
# Usage: palette_exists <name>
palette_exists() {
    local name="$1"
    [[ -n "${BUILTIN_PALETTES[$name]:-}" ]] || \
    [[ -f "${GUMMYWORM_PALETTES_DIR}/${name}.palette" ]]
}

# List all available palettes
# Usage: palette_list
palette_list() {
    echo "Built-in palettes:"
    echo ""
    
    # Sort palette names
    local names
    names=$(echo "${!BUILTIN_PALETTES[@]}" | tr ' ' '\n' | sort)
    
    for name in $names; do
        local chars="${BUILTIN_PALETTES[$name]}"
        local desc="${PALETTE_DESCRIPTIONS[$name]:-}"
        local char_count
        
        # Get visual character count (handles unicode)
        char_count=$(echo -n "$chars" | wc -m)
        
        printf "  ${COLORS[cyan]}%-12s${COLORS[reset]} │ %-20s │ %s\n" \
            "$name" "$chars" "($char_count chars) $desc"
    done
    
    # Check for custom palettes
    if [[ -d "$GUMMYWORM_PALETTES_DIR" ]]; then
        local custom_palettes
        custom_palettes=$(find "$GUMMYWORM_PALETTES_DIR" -name "*.palette" 2>/dev/null | wc -l)
        
        if [[ "$custom_palettes" -gt 0 ]]; then
            echo ""
            echo "Custom palettes (in $GUMMYWORM_PALETTES_DIR):"
            for f in "$GUMMYWORM_PALETTES_DIR"/*.palette; do
                [[ -f "$f" ]] || continue
                local pname
                pname=$(basename "$f" .palette)
                local pchars
                pchars=$(grep -v '^#' "$f" | grep -v '^$' | head -1)
                printf "  ${COLORS[cyan]}%-12s${COLORS[reset]} │ %s\n" "$pname" "$pchars"
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
    
    len=$(echo -n "$palette" | wc -m)
    
    if [[ "$len" -lt 2 ]]; then
        log_error "Palette must have at least 2 characters"
        return 1
    fi
    
    return 0
}

# Parse palette into array (handles unicode)
# Usage: palette_to_array <palette_string> <array_name>
palette_to_array() {
    local palette="$1"
    local -n arr=$2  # nameref to array
    
    arr=()
    
    # Check if pure ASCII for fast path
    if [[ "$palette" =~ ^[[:ascii:]]*$ ]]; then
        local i
        for ((i=0; i<${#palette}; i++)); do
            arr+=("${palette:$i:1}")
        done
    else
        # Unicode - use python for reliable character splitting
        if command_exists python3; then
            while IFS= read -r char; do
                arr+=("$char")
            done < <(python3 -c "
import sys
for c in sys.argv[1]:
    print(c)
" "$palette")
        else
            # Fallback: byte-by-byte (may not work for all unicode)
            local i
            for ((i=0; i<${#palette}; i++)); do
                arr+=("${palette:$i:1}")
            done
        fi
    fi
}
