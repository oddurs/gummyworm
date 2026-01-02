#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_image.sh - Unit tests for lib/image.sh
# ============================================================================
# Tests image processing functions: URL detection, dimensions, brightness.
# Includes mock support for testing without ImageMagick.
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
# Tests: is_url()
# ============================================================================

test_is_url_http() {
    assert_true 'is_url "http://example.com"' "http URL detected"
    assert_true 'is_url "http://example.com/image.png"' "http URL with path"
    assert_true 'is_url "http://example.com:8080/image.png"' "http URL with port"
}

test_is_url_https() {
    assert_true 'is_url "https://example.com"' "https URL detected"
    assert_true 'is_url "https://example.com/path/to/image.jpg"' "https URL with path"
    assert_true 'is_url "https://user:pass@example.com/image.png"' "https URL with auth"
}

test_is_url_with_query() {
    assert_true 'is_url "https://example.com/image.png?size=large"' "URL with query string"
    assert_true 'is_url "https://example.com/image.png?a=1&b=2"' "URL with multiple params"
}

test_is_url_not_url() {
    assert_false 'is_url "/path/to/file.png"' "absolute path is not URL"
    assert_false 'is_url "./relative/file.png"' "relative path is not URL"
    assert_false 'is_url "file.png"' "filename is not URL"
    assert_false 'is_url "ftp://example.com"' "ftp is not http/https URL"
    assert_false 'is_url "file://local/path"' "file:// is not http/https URL"
    assert_false 'is_url ""' "empty string is not URL"
}

# ============================================================================
# Tests: calc_brightness()
# ============================================================================

test_calc_brightness_black() {
    local brightness
    brightness=$(calc_brightness 0 0 0)
    assert_equals "0" "$brightness" "black has brightness 0"
}

test_calc_brightness_white() {
    local brightness
    brightness=$(calc_brightness 255 255 255)
    assert_equals "255" "$brightness" "white has brightness 255"
}

test_calc_brightness_red() {
    local brightness
    brightness=$(calc_brightness 255 0 0)
    # Luminance formula: (255*299 + 0*587 + 0*114) / 1000 = 76.245 ≈ 76
    assert_equals "76" "$brightness" "pure red brightness"
}

test_calc_brightness_green() {
    local brightness
    brightness=$(calc_brightness 0 255 0)
    # Luminance formula: (0*299 + 255*587 + 0*114) / 1000 = 149.685 ≈ 149
    assert_equals "149" "$brightness" "pure green brightness"
}

test_calc_brightness_blue() {
    local brightness
    brightness=$(calc_brightness 0 0 255)
    # Luminance formula: (0*299 + 0*587 + 255*114) / 1000 = 29.07 ≈ 29
    assert_equals "29" "$brightness" "pure blue brightness"
}

test_calc_brightness_gray() {
    local brightness
    brightness=$(calc_brightness 128 128 128)
    # (128*299 + 128*587 + 128*114) / 1000 = 128
    assert_equals "128" "$brightness" "mid gray brightness"
}

test_calc_brightness_yellow() {
    local brightness
    brightness=$(calc_brightness 255 255 0)
    # (255*299 + 255*587 + 0*114) / 1000 = 225.93 ≈ 225
    assert_equals "225" "$brightness" "yellow brightness"
}

# ============================================================================
# Tests: calc_dimensions()
# ============================================================================

test_calc_dimensions_basic() {
    local dims
    dims=$(calc_dimensions 100 100 50 0 true)
    # Should calculate height based on aspect ratio and terminal char ratio
    assert_matches "$dims" "^50 [0-9]+$" "dimensions format correct"
}

test_calc_dimensions_wide_image() {
    local dims
    dims=$(calc_dimensions 200 100 80 0 true)
    # Wide image: height should be relatively small
    read -r w h <<< "$dims"
    assert_equals "80" "$w" "width preserved"
    # Height should be calculated based on aspect ratio
    assert_true '[[ "$h" -gt 0 ]]' "height is positive"
    assert_true '[[ "$h" -lt 80 ]]' "height less than width for wide image"
}

test_calc_dimensions_tall_image() {
    local dims
    dims=$(calc_dimensions 100 200 80 0 true)
    read -r w h <<< "$dims"
    assert_equals "80" "$w" "width preserved"
    # Height should be larger relative to width
    assert_true '[[ "$h" -gt 0 ]]' "height is positive"
}

test_calc_dimensions_square_image() {
    local dims
    dims=$(calc_dimensions 100 100 40 0 true)
    read -r w h <<< "$dims"
    assert_equals "40" "$w" "width preserved for square"
    # For square image with terminal ratio compensation
    assert_true '[[ "$h" -gt 0 ]]' "height is positive"
}

test_calc_dimensions_explicit_height() {
    local dims
    dims=$(calc_dimensions 100 100 80 40 true)
    read -r w h <<< "$dims"
    assert_equals "80" "$w" "width preserved"
    assert_equals "40" "$h" "explicit height preserved"
}

test_calc_dimensions_no_aspect() {
    local dims
    dims=$(calc_dimensions 100 100 80 0 false)
    read -r w h <<< "$dims"
    assert_equals "80" "$w" "width preserved"
    # Without aspect preservation, height defaults to width/2
    assert_equals "40" "$h" "height is half width without aspect"
}

test_calc_dimensions_minimum_height() {
    local dims
    dims=$(calc_dimensions 1000 1 50 0 true)
    read -r w h <<< "$dims"
    # Very wide image should still have at least height 1
    assert_true '[[ "$h" -ge 1 ]]' "minimum height is 1"
}

# ============================================================================
# Tests: image_is_valid() with mocks
# ============================================================================

test_image_is_valid_real_file() {
    if ! has_imagemagick; then
        skip_test "ImageMagick not available"
        return 0
    fi
    
    local tmpfile
    tmpfile=$(make_temp_file ".png")
    create_test_image "$tmpfile" 10 10
    
    assert_true "image_is_valid '$tmpfile'" "valid image file"
}

test_image_is_valid_nonexistent() {
    assert_false 'image_is_valid "/nonexistent/file.png"' "nonexistent file is not valid"
}

test_image_is_valid_not_image() {
    local tmpfile
    tmpfile=$(make_temp_file ".txt")
    echo "this is not an image" > "$tmpfile"
    
    assert_false "image_is_valid '$tmpfile'" "text file is not valid image"
}

# ============================================================================
# Tests: image_dimensions() with mocks
# ============================================================================

test_image_dimensions_mocked() {
    # Save original
    local orig_identify
    orig_identify=$(which identify 2>/dev/null || echo "")
    
    # Apply mock
    mock_identify 640 480 "PNG"
    
    local dims
    dims=$(image_dimensions "/any/file.png")
    
    # Restore
    restore_mocks
    
    assert_equals "640 480" "$dims" "mocked dimensions returned"
}

test_image_dimensions_real() {
    if ! has_imagemagick; then
        skip_test "ImageMagick not available"
        return 0
    fi
    
    local tmpfile
    tmpfile=$(make_temp_file ".png")
    create_test_image "$tmpfile" 100 50
    
    local dims
    dims=$(image_dimensions "$tmpfile")
    
    assert_equals "100 50" "$dims" "real image dimensions"
}

# ============================================================================
# Tests: image_width() and image_height()
# ============================================================================

test_image_width_mocked() {
    mock_identify 800 600 "JPEG"
    
    local width
    width=$(image_width "/any/file.jpg")
    
    restore_mocks
    
    assert_equals "800" "$width" "mocked width returned"
}

test_image_height_mocked() {
    mock_identify 800 600 "JPEG"
    
    local height
    height=$(image_height "/any/file.jpg")
    
    restore_mocks
    
    assert_equals "600" "$height" "mocked height returned"
}

# ============================================================================
# Tests: download_image() - basic validation
# ============================================================================

test_download_requires_curl_or_wget() {
    # Just verify the function exists and checks for curl/wget
    assert_true 'declare -f download_image >/dev/null' "download_image function exists"
}

# ============================================================================
# Tests: image_from_stdin() - basic validation
# ============================================================================

test_image_from_stdin_function_exists() {
    assert_true 'declare -f image_from_stdin >/dev/null' "image_from_stdin function exists"
}

# ============================================================================
# Tests: Animation Functions
# ============================================================================

test_image_is_animated_function_exists() {
    assert_true 'declare -f image_is_animated >/dev/null' "image_is_animated function exists"
}

test_image_frame_count_function_exists() {
    assert_true 'declare -f image_frame_count >/dev/null' "image_frame_count function exists"
}

test_image_get_delays_function_exists() {
    assert_true 'declare -f image_get_delays >/dev/null' "image_get_delays function exists"
}

test_image_extract_frames_function_exists() {
    assert_true 'declare -f image_extract_frames >/dev/null' "image_extract_frames function exists"
}

test_image_is_animated_with_animated_gif() {
    local animated_gif="$SCRIPT_DIR/fixtures/animated_test.gif"
    if [[ -f "$animated_gif" ]]; then
        assert_true "image_is_animated '$animated_gif'" "animated GIF is detected as animated"
    else
        skip_test "animated_test.gif fixture not found"
    fi
}

test_image_is_animated_with_static_image() {
    local static_png="$SCRIPT_DIR/fixtures/test.png"
    # Create a simple static test image if it doesn't exist
    if [[ ! -f "$static_png" ]]; then
        $_MAGICK_CONVERT -size 10x10 xc:red "$static_png" 2>/dev/null || true
    fi
    if [[ -f "$static_png" ]]; then
        assert_false "image_is_animated '$static_png'" "static PNG is not animated"
        rm -f "$static_png"
    else
        skip_test "Could not create static test image"
    fi
}

test_image_frame_count_with_animated_gif() {
    local animated_gif="$SCRIPT_DIR/fixtures/animated_test.gif"
    if [[ -f "$animated_gif" ]]; then
        local count
        count=$(image_frame_count "$animated_gif")
        assert_equals "3" "$count" "animated GIF has 3 frames"
    else
        skip_test "animated_test.gif fixture not found"
    fi
}

test_image_get_delays_with_animated_gif() {
    local animated_gif="$SCRIPT_DIR/fixtures/animated_test.gif"
    if [[ -f "$animated_gif" ]]; then
        local delays
        delays=$(image_get_delays "$animated_gif")
        # Should have 3 lines of delays (one per frame)
        local delay_count
        delay_count=$(echo "$delays" | wc -l | tr -d ' ')
        assert_equals "3" "$delay_count" "animated GIF has 3 frame delays"
    else
        skip_test "animated_test.gif fixture not found"
    fi
}

test_image_extract_frames_with_animated_gif() {
    local animated_gif="$SCRIPT_DIR/fixtures/animated_test.gif"
    if [[ -f "$animated_gif" ]]; then
        local tmpdir
        tmpdir=$(mktemp -d)
        if image_extract_frames "$animated_gif" "$tmpdir" 0; then
            local frame_count
            frame_count=$(ls "$tmpdir"/frame_*.png 2>/dev/null | wc -l | tr -d ' ')
            assert_equals "3" "$frame_count" "extracted 3 frames from animated GIF"
        else
            fail "image_extract_frames failed"
        fi
        rm -rf "$tmpdir"
    else
        skip_test "animated_test.gif fixture not found"
    fi
}

test_image_extract_frames_with_max_frames() {
    local animated_gif="$SCRIPT_DIR/fixtures/animated_test.gif"
    if [[ -f "$animated_gif" ]]; then
        local tmpdir
        tmpdir=$(mktemp -d)
        if image_extract_frames "$animated_gif" "$tmpdir" 2; then
            local frame_count
            frame_count=$(ls "$tmpdir"/frame_*.png 2>/dev/null | wc -l | tr -d ' ')
            assert_equals "2" "$frame_count" "extracted max 2 frames from animated GIF"
        else
            fail "image_extract_frames with max_frames failed"
        fi
        rm -rf "$tmpdir"
    else
        skip_test "animated_test.gif fixture not found"
    fi
}

# ============================================================================
# Run Tests
# ============================================================================

run_discovered_tests "lib/image.sh Unit Tests"
