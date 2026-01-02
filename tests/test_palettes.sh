#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_palettes.sh - Unit tests for lib/palettes.sh
# ============================================================================
# Tests palette loading, validation, and character handling.
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

# Load gummyworm libraries for unit testing
load_gummyworm_libs

# ============================================================================
# Tests: _get_builtin_palette()
# ============================================================================

test_builtin_palette_standard() {
    local result
    result=$(_get_builtin_palette "standard")
    assert_equals " .:-=+*#%@" "$result" "standard palette"
}

test_builtin_palette_simple() {
    local result
    result=$(_get_builtin_palette "simple")
    assert_equals " .oO@" "$result" "simple palette"
}

test_builtin_palette_binary() {
    local result
    result=$(_get_builtin_palette "binary")
    assert_equals " █" "$result" "binary palette"
}

test_builtin_palette_blocks() {
    local result
    result=$(_get_builtin_palette "blocks")
    assert_equals " ░▒▓█" "$result" "blocks palette"
}

test_builtin_palette_matrix() {
    local result
    result=$(_get_builtin_palette "matrix")
    assert_equals " 01" "$result" "matrix palette"
}

test_builtin_palette_emoji() {
    local result
    result=$(_get_builtin_palette "emoji")
    assert_equals "　🌑🌒🌓🌔🌕" "$result" "emoji palette"
}

test_builtin_palette_invalid() {
    assert_false '_get_builtin_palette "nonexistent"' "invalid palette returns error"
}

# ============================================================================
# Tests: palette_get()
# ============================================================================

test_palette_get_builtin() {
    local result
    result=$(palette_get "standard")
    assert_equals " .:-=+*#%@" "$result" "get builtin palette"
}

test_palette_get_all_builtins() {
    # Verify all documented palettes are accessible
    for name in standard detailed simple binary matrix blocks shades retro dots emoji stars hearts; do
        local result
        result=$(palette_get "$name")
        assert_not_equals "" "$result" "palette_get returns content for $name"
    done
}

test_palette_get_nonexistent() {
    local result
    result=$(palette_get "this_palette_does_not_exist_xyz" 2>/dev/null) || true
    assert_equals "" "$result" "nonexistent palette returns empty"
}

# ============================================================================
# Tests: palette_exists()
# ============================================================================

test_palette_exists_builtin() {
    assert_true 'palette_exists "standard"' "standard palette exists"
    assert_true 'palette_exists "blocks"' "blocks palette exists"
    assert_true 'palette_exists "emoji"' "emoji palette exists"
}

test_palette_exists_nonexistent() {
    assert_false 'palette_exists "nonexistent_palette_xyz"' "nonexistent palette does not exist"
}

# ============================================================================
# Tests: palette_validate()
# ============================================================================

test_palette_validate_valid() {
    assert_true 'palette_validate "ab"' "2-char palette is valid"
    assert_true 'palette_validate " .oO@"' "5-char palette is valid"
    assert_true 'palette_validate " .:-=+*#%@"' "10-char palette is valid"
}

test_palette_validate_too_short() {
    # Single character palette should fail
    assert_false 'palette_validate "a" 2>/dev/null' "1-char palette is invalid"
}

test_palette_validate_empty() {
    assert_false 'palette_validate "" 2>/dev/null' "empty palette is invalid"
}

# ============================================================================
# Tests: palette_has_wide_chars()
# ============================================================================

test_palette_has_wide_chars_ascii() {
    assert_false 'palette_has_wide_chars " .:-=+*#%@"' "ASCII palette has no wide chars"
    assert_false 'palette_has_wide_chars " .oO@"' "simple ASCII has no wide chars"
}

test_palette_has_wide_chars_emoji() {
    # Emoji palettes use wide characters
    assert_true 'palette_has_wide_chars "　🌑🌒🌓🌔🌕"' "emoji palette has wide chars"
    assert_true 'palette_has_wide_chars "　🤍💓💗💖💘"' "hearts palette has wide chars"
}

test_palette_has_wide_chars_blocks() {
    # Unicode blocks (░▒▓█) are typically NOT wide chars (they're 1-column)
    assert_false 'palette_has_wide_chars " ░▒▓█"' "blocks palette has no wide chars"
}

# ============================================================================
# Tests: palette_char_width()
# ============================================================================

test_palette_char_width_ascii() {
    local width
    width=$(palette_char_width " .:-=+*#%@")
    assert_equals "1" "$width" "ASCII palette char width is 1"
}

test_palette_char_width_emoji() {
    local width
    width=$(palette_char_width "　🌑🌒🌓🌔🌕")
    assert_equals "2" "$width" "emoji palette char width is 2"
}

# ============================================================================
# Tests: palette_to_array()
# ============================================================================

test_palette_to_array_ascii() {
    local test_arr=()
    palette_to_array " .oO@" test_arr
    
    assert_equals "5" "${#test_arr[@]}" "array has 5 elements"
    assert_equals " " "${test_arr[0]}" "first char is space"
    assert_equals "." "${test_arr[1]}" "second char is dot"
    assert_equals "o" "${test_arr[2]}" "third char is o"
    assert_equals "O" "${test_arr[3]}" "fourth char is O"
    assert_equals "@" "${test_arr[4]}" "fifth char is @"
}

test_palette_to_array_unicode() {
    if ! command -v python3 &>/dev/null; then
        skip_test "python3 not available"
        return 0
    fi
    
    local test_arr=()
    palette_to_array " ░▒▓█" test_arr
    
    assert_equals "5" "${#test_arr[@]}" "unicode array has 5 elements"
    assert_equals " " "${test_arr[0]}" "first char is space"
    assert_equals "░" "${test_arr[1]}" "second char is light shade"
    assert_equals "█" "${test_arr[4]}" "fifth char is full block"
}

test_palette_to_array_emoji() {
    if ! command -v python3 &>/dev/null; then
        skip_test "python3 not available"
        return 0
    fi
    
    local test_arr=()
    palette_to_array "　🌑🌒🌓🌔🌕" test_arr
    
    assert_equals "6" "${#test_arr[@]}" "emoji array has 6 elements"
    assert_equals "🌑" "${test_arr[1]}" "second char is new moon"
    assert_equals "🌕" "${test_arr[5]}" "sixth char is full moon"
}

# ============================================================================
# Tests: Custom palette file loading
# ============================================================================

test_palette_get_custom_file() {
    # Create a temporary custom palette file
    local palette_dir="$GUMMYWORM_PALETTES_DIR"
    local custom_palette="$palette_dir/test_custom.palette"
    
    mkdir -p "$palette_dir"
    echo "# Test custom palette" > "$custom_palette"
    echo " XYZ" >> "$custom_palette"
    
    local result
    result=$(palette_get "test_custom")
    
    # Cleanup
    rm -f "$custom_palette"
    
    assert_equals " XYZ" "$result" "custom palette loaded from file"
}

# ============================================================================
# Run Tests
# ============================================================================

run_discovered_tests "lib/palettes.sh Unit Tests"
