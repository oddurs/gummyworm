#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_utils.sh - Unit tests for lib/utils.sh
# ============================================================================
# Tests utility functions: validation, string manipulation, file checks.
# Shell compatibility: Bash 3.2+, zsh 5.0+
# ============================================================================

# Shell detection and compatibility
if [[ -n "${ZSH_VERSION:-}" ]]; then
    setopt KSH_ARRAYS SH_WORD_SPLIT NO_NOMATCH 2>/dev/null || true
fi
set -e; set -u; set -o pipefail 2>/dev/null || true

# Portable script directory
if [[ -n "${BASH_VERSION:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
source "$SCRIPT_DIR/test_runner.sh"

# Load gummyworm libraries for unit testing
load_gummyworm_libs

# ============================================================================
# Tests: is_positive_int()
# ============================================================================

test_is_positive_int_valid_numbers() {
    assert_true 'is_positive_int "1"' "1 is positive int"
    assert_true 'is_positive_int "42"' "42 is positive int"
    assert_true 'is_positive_int "100"' "100 is positive int"
    assert_true 'is_positive_int "999999"' "999999 is positive int"
}

test_is_positive_int_zero() {
    assert_false 'is_positive_int "0"' "0 is not positive"
}

test_is_positive_int_negative() {
    assert_false 'is_positive_int "-1"' "-1 is not positive int"
    assert_false 'is_positive_int "-100"' "-100 is not positive int"
}

test_is_positive_int_invalid() {
    assert_false 'is_positive_int ""' "empty string is not positive int"
    assert_false 'is_positive_int "abc"' "abc is not positive int"
    assert_false 'is_positive_int "12.5"' "12.5 is not positive int"
    assert_false 'is_positive_int "1a2"' "1a2 is not positive int"
    assert_false 'is_positive_int " 5"' "leading space is not positive int"
    assert_false 'is_positive_int "5 "' "trailing space is not positive int"
}

# ============================================================================
# Tests: is_non_negative_int()
# ============================================================================

test_is_non_negative_int_valid() {
    assert_true 'is_non_negative_int "0"' "0 is non-negative"
    assert_true 'is_non_negative_int "1"' "1 is non-negative"
    assert_true 'is_non_negative_int "42"' "42 is non-negative"
}

test_is_non_negative_int_negative() {
    assert_false 'is_non_negative_int "-1"' "-1 is not non-negative"
}

test_is_non_negative_int_invalid() {
    assert_false 'is_non_negative_int "abc"' "abc is not non-negative int"
    assert_false 'is_non_negative_int ""' "empty is not non-negative int"
}

# ============================================================================
# Tests: trim()
# ============================================================================

test_trim_leading_whitespace() {
    local result
    result=$(trim "   hello")
    assert_equals "hello" "$result" "trim leading spaces"
}

test_trim_trailing_whitespace() {
    local result
    result=$(trim "hello   ")
    assert_equals "hello" "$result" "trim trailing spaces"
}

test_trim_both_whitespace() {
    local result
    result=$(trim "   hello   ")
    assert_equals "hello" "$result" "trim both sides"
}

test_trim_tabs_and_spaces() {
    local result
    result=$(trim $'\t  hello world  \t')
    assert_equals "hello world" "$result" "trim tabs and spaces"
}

test_trim_no_whitespace() {
    local result
    result=$(trim "hello")
    assert_equals "hello" "$result" "no trim needed"
}

test_trim_empty_string() {
    local result
    result=$(trim "")
    assert_equals "" "$result" "trim empty string"
}

test_trim_only_whitespace() {
    local result
    result=$(trim "   ")
    assert_equals "" "$result" "trim whitespace-only string"
}

# ============================================================================
# Tests: is_blank()
# ============================================================================

test_is_blank_empty() {
    assert_true 'is_blank ""' "empty string is blank"
}

test_is_blank_spaces() {
    assert_true 'is_blank "   "' "spaces-only is blank"
}

test_is_blank_tabs() {
    assert_true 'is_blank "	"' "tab-only is blank"
}

test_is_blank_mixed_whitespace() {
    assert_true 'is_blank "  	  "' "mixed whitespace is blank"
}

test_is_blank_not_blank() {
    assert_false 'is_blank "hello"' "hello is not blank"
    assert_false 'is_blank " x "' "string with char is not blank"
}

# ============================================================================
# Tests: command_exists()
# ============================================================================

test_command_exists_common_commands() {
    assert_true 'command_exists "bash"' "bash exists"
    assert_true 'command_exists "echo"' "echo exists"
    assert_true 'command_exists "cat"' "cat exists"
}

test_command_exists_nonexistent() {
    assert_false 'command_exists "this_command_definitely_does_not_exist_xyz123"' "fake command does not exist"
}

# ============================================================================
# Tests: file_readable()
# ============================================================================

test_file_readable_existing_file() {
    local tmpfile
    tmpfile=$(make_temp_file)
    echo "test content" > "$tmpfile"
    
    assert_true "file_readable '$tmpfile'" "temp file is readable"
}

test_file_readable_nonexistent() {
    assert_false 'file_readable "/nonexistent/file/path/xyz"' "nonexistent file is not readable"
}

test_file_readable_directory() {
    local tmpdir
    tmpdir=$(make_temp_dir)
    
    assert_false "file_readable '$tmpdir'" "directory is not a file"
}

# ============================================================================
# Tests: is_image_file()
# ============================================================================

test_is_image_file_valid_extensions() {
    assert_true 'is_image_file "photo.jpg"' ".jpg is image"
    assert_true 'is_image_file "photo.jpeg"' ".jpeg is image"
    assert_true 'is_image_file "photo.png"' ".png is image"
    assert_true 'is_image_file "photo.gif"' ".gif is image"
    assert_true 'is_image_file "photo.bmp"' ".bmp is image"
    assert_true 'is_image_file "photo.webp"' ".webp is image"
    assert_true 'is_image_file "photo.tiff"' ".tiff is image"
    assert_true 'is_image_file "photo.tif"' ".tif is image"
}

test_is_image_file_case_insensitive() {
    assert_true 'is_image_file "photo.PNG"' ".PNG is image"
    assert_true 'is_image_file "photo.JPG"' ".JPG is image"
    assert_true 'is_image_file "photo.Jpeg"' ".Jpeg is image"
}

test_is_image_file_invalid_extensions() {
    assert_false 'is_image_file "file.txt"' ".txt is not image"
    assert_false 'is_image_file "file.pdf"' ".pdf is not image"
    assert_false 'is_image_file "file.doc"' ".doc is not image"
    assert_false 'is_image_file "file"' "no extension is not image"
}

test_is_image_file_with_path() {
    assert_true 'is_image_file "/path/to/photo.jpg"' "path with .jpg is image"
    assert_true 'is_image_file "./relative/photo.png"' "relative path with .png is image"
}

# ============================================================================
# Tests: str_display_width() - if python3 available
# ============================================================================

test_str_display_width_ascii() {
    if ! command -v python3 &>/dev/null; then
        skip_test "python3 not available"
        return 0
    fi
    
    local width
    width=$(str_display_width "hello")
    assert_equals "5" "$width" "ASCII string width"
}

test_str_display_width_empty() {
    if ! command -v python3 &>/dev/null; then
        skip_test "python3 not available"
        return 0
    fi
    
    local width
    width=$(str_display_width "")
    assert_equals "0" "$width" "empty string width"
}

test_str_display_width_emoji() {
    if ! command -v python3 &>/dev/null; then
        skip_test "python3 not available"
        return 0
    fi
    
    local width
    # Single emoji should be width 2 (wide char)
    width=$(str_display_width "🌕")
    assert_equals "2" "$width" "emoji width is 2"
}

test_str_display_width_mixed() {
    if ! command -v python3 &>/dev/null; then
        skip_test "python3 not available"
        return 0
    fi
    
    local width
    # "hi🌕" = 2 + 2 = 4
    width=$(str_display_width "hi🌕")
    assert_equals "4" "$width" "mixed string width"
}

# ============================================================================
# Tests: char_is_wide()
# ============================================================================

test_char_is_wide_emoji() {
    if ! command -v python3 &>/dev/null; then
        skip_test "python3 not available"
        return 0
    fi
    
    assert_true 'char_is_wide "🌕"' "moon emoji is wide"
    assert_true 'char_is_wide "💖"' "heart emoji is wide"
}

test_char_is_wide_ascii() {
    if ! command -v python3 &>/dev/null; then
        skip_test "python3 not available"
        return 0
    fi
    
    assert_false 'char_is_wide "a"' "a is not wide"
    assert_false 'char_is_wide "@"' "@ is not wide"
    assert_false 'char_is_wide " "' "space is not wide"
}

# ============================================================================
# Run Tests
# ============================================================================

run_discovered_tests "lib/utils.sh Unit Tests"
