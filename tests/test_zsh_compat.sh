#!/usr/bin/env zsh
# ============================================================================
# gummyworm/tests/test_zsh_compat.sh - zsh compatibility tests
# ============================================================================
# Specific tests to verify zsh compatibility features work correctly.
# Run this with: zsh tests/test_zsh_compat.sh
# ============================================================================

# zsh compatibility settings
setopt KSH_ARRAYS SH_WORD_SPLIT NO_NOMATCH POSIX_BUILTINS 2>/dev/null || true
set -e; set -u; set -o pipefail 2>/dev/null || setopt PIPE_FAIL 2>/dev/null || true

# Portable script directory (zsh-specific)
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

# Load gummyworm libraries for unit testing
load_gummyworm_libs

# ============================================================================
# Tests: Shell Detection
# ============================================================================

test_shell_detected_as_zsh() {
    assert_equals "zsh" "$_GUMMYWORM_SHELL" "shell detected as zsh"
}

test_is_zsh_returns_true() {
    assert_true '_is_zsh' "_is_zsh returns true in zsh"
}

test_is_bash_returns_false() {
    assert_false '_is_bash' "_is_bash returns false in zsh"
}

# ============================================================================
# Tests: Array Compatibility (KSH_ARRAYS)
# ============================================================================

test_arrays_are_zero_indexed() {
    local arr=(a b c d e)
    assert_equals "a" "${arr[0]}" "array index 0 is first element"
    assert_equals "b" "${arr[1]}" "array index 1 is second element"
    assert_equals "5" "${#arr[@]}" "array length is 5"
}

test_array_expansion_works() {
    local arr=(one two three)
    local result="${arr[*]}"
    # With SH_WORD_SPLIT, this should work like bash
    assert_contains "$result" "one" "array expansion contains first element"
    assert_contains "$result" "three" "array expansion contains last element"
}

# ============================================================================
# Tests: Script Source Detection
# ============================================================================

test_script_source_returns_path() {
    # _script_source returns the config.sh path when called from there
    # What we really care about is that it returns a valid path
    local source
    source="$(_script_source)"
    assert_not_equals "" "$source" "script source returns non-empty path"
    assert_contains "$source" ".sh" "script source contains .sh extension"
}

# ============================================================================
# Tests: Palette Functions Work in zsh
# ============================================================================

test_palette_get_works() {
    local result
    result=$(palette_get "standard")
    assert_equals " .:-=+*#%@" "$result" "palette_get returns correct chars in zsh"
}

test_palette_to_array_works() {
    local test_arr=()
    palette_to_array " .oO@" test_arr
    
    assert_equals "5" "${#test_arr[@]}" "palette_to_array creates 5 elements"
    assert_equals " " "${test_arr[0]}" "first element is space"
    assert_equals "@" "${test_arr[4]}" "last element is @"
}

# ============================================================================
# Tests: String Functions Work in zsh
# ============================================================================

test_str_display_width_works() {
    local width
    width=$(str_display_width "hello")
    assert_equals "5" "$width" "str_display_width works for ASCII"
}

test_trim_works() {
    local result
    result=$(trim "  hello world  ")
    assert_equals "hello world" "$result" "trim works in zsh"
}

# ============================================================================
# Tests: Validation Functions Work in zsh
# ============================================================================

test_is_positive_int_works() {
    assert_true 'is_positive_int 42' "is_positive_int works for positive"
    assert_false 'is_positive_int -5' "is_positive_int rejects negative"
    assert_false 'is_positive_int abc' "is_positive_int rejects non-numeric"
}

test_is_valid_hex_color_works() {
    assert_true 'is_valid_hex_color "#FF0000"' "is_valid_hex_color accepts valid"
    assert_false 'is_valid_hex_color "red"' "is_valid_hex_color rejects invalid"
}

# ============================================================================
# Tests: CLI Execution in zsh
# ============================================================================

test_gummyworm_version_works() {
    local output
    output=$("$PROJECT_ROOT/gummyworm" --version 2>&1)
    assert_contains "$output" "gummyworm" "version output contains name"
    assert_contains "$output" "2.1.0" "version output contains version"
}

test_gummyworm_help_works() {
    local output
    output=$("$PROJECT_ROOT/gummyworm" --help 2>&1)
    # Help output should contain common help text (case-insensitive check)
    assert_contains "$output" "gummyworm" "help output contains gummyworm"
    assert_contains "$output" "image" "help output mentions image"
}

test_gummyworm_list_palettes_works() {
    local output
    output=$("$PROJECT_ROOT/gummyworm" --list-palettes 2>&1)
    assert_contains "$output" "standard" "list-palettes shows standard palette"
    assert_contains "$output" "blocks" "list-palettes shows blocks palette"
}

# ============================================================================
# Run Tests
# ============================================================================

run_discovered_tests "zsh Compatibility Tests"
