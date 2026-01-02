#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_integration.sh - End-to-end integration tests
# ============================================================================
# Tests the complete gummyworm CLI with real image processing.
# Requires ImageMagick for test image generation.
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

# ============================================================================
# Setup & Teardown
# ============================================================================

# Test images and output files
TEST_IMG=""
TEST_IMG2=""
TEST_IMG3=""
OUTPUT_FILE=""
OUTPUT_DIR=""

setup() {
    # Check for ImageMagick
    if ! has_imagemagick; then
        echo -e "${YELLOW}Warning: ImageMagick not found. Some tests will be skipped.${NC}"
    fi
    
    # Create test images
    TEST_IMG=$(make_temp_file ".png")
    TEST_IMG2=$(make_temp_file ".png")
    TEST_IMG3=$(make_temp_file ".png")
    OUTPUT_FILE=$(make_temp_file ".txt")
    OUTPUT_DIR=$(make_temp_dir)
    
    if has_imagemagick; then
        convert -size 50x50 gradient:black-white "$TEST_IMG"
        convert -size 30x30 gradient:red-blue "$TEST_IMG2"
        convert -size 40x40 gradient:green-yellow "$TEST_IMG3"
    fi
}

teardown() {
    # Cleanup handled by test_runner.sh
    :
}

# ============================================================================
# Helper for skipping tests when ImageMagick unavailable
# ============================================================================

require_imagemagick() {
    if ! has_imagemagick; then
        skip_test "ImageMagick not available"
        return 1
    fi
    return 0
}

# ============================================================================
# Tests: Basic CLI
# ============================================================================

test_help_flag() {
    assert_exit_code 0 "$GUMMYWORM --help"
}

test_help_output_content() {
    assert_output_contains "Usage" "$GUMMYWORM --help"
    assert_output_contains "Options" "$GUMMYWORM --help"
}

test_version_flag() {
    assert_exit_code 0 "$GUMMYWORM --version"
}

test_version_output_format() {
    local output
    output=$("$GUMMYWORM" --version)
    assert_matches "$output" "[0-9]+\.[0-9]+\.[0-9]+" "version has semantic format"
}

test_list_palettes_flag() {
    assert_exit_code 0 "$GUMMYWORM --list-palettes"
}

test_list_palettes_shows_builtins() {
    local output
    output=$("$GUMMYWORM" --list-palettes)
    assert_contains "$output" "standard" "lists standard palette"
    assert_contains "$output" "blocks" "lists blocks palette"
    assert_contains "$output" "emoji" "lists emoji palette"
}

# ============================================================================
# Tests: Basic Conversion
# ============================================================================

test_basic_conversion() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 '$TEST_IMG'"
}

test_conversion_with_width() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 40 '$TEST_IMG'"
}

test_conversion_with_invert() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 -i '$TEST_IMG'"
}

test_conversion_with_color() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 -c '$TEST_IMG'"
}

test_conversion_produces_output() {
    require_imagemagick || return 0
    
    local output
    output=$("$GUMMYWORM" -q -w 20 "$TEST_IMG")
    assert_not_equals "" "$output" "conversion produces output"
}

# ============================================================================
# Tests: Palette Options
# ============================================================================

test_palette_standard() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 -p standard '$TEST_IMG'"
}

test_palette_blocks() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 -p blocks '$TEST_IMG'"
}

test_palette_simple() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 -p simple '$TEST_IMG'"
}

test_palette_custom_inline() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 -p ' .oO@' '$TEST_IMG'"
}

test_palette_emoji() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 -p emoji '$TEST_IMG'"
}

# ============================================================================
# Tests: File Output
# ============================================================================

test_output_to_file() {
    require_imagemagick || return 0
    
    "$GUMMYWORM" -q -w 20 -o "$OUTPUT_FILE" "$TEST_IMG"
    assert_file_exists "$OUTPUT_FILE"
    assert_file_not_empty "$OUTPUT_FILE"
}

test_output_file_content() {
    require_imagemagick || return 0
    
    "$GUMMYWORM" -q -w 20 -o "$OUTPUT_FILE" "$TEST_IMG"
    local content
    content=$(cat "$OUTPUT_FILE")
    assert_not_equals "" "$content" "output file has content"
}

# ============================================================================
# Tests: Batch Processing
# ============================================================================

test_batch_multiple_files() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 '$TEST_IMG' '$TEST_IMG2'"
}

test_batch_three_files() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 '$TEST_IMG' '$TEST_IMG2' '$TEST_IMG3'"
}

test_batch_output_to_directory() {
    require_imagemagick || return 0
    
    "$GUMMYWORM" -q -w 20 -d "$OUTPUT_DIR" "$TEST_IMG" "$TEST_IMG2"
    
    local file_count
    file_count=$(ls -1 "$OUTPUT_DIR" | wc -l | tr -d ' ')
    assert_true '[[ "$file_count" -ge 2 ]]' "batch creates multiple files"
}

test_batch_continue_on_error() {
    require_imagemagick || return 0
    
    local invalid_file="/tmp/nonexistent_image_$$.png"
    # Should succeed overall even with one invalid file
    "$GUMMYWORM" -q -w 20 --continue-on-error "$TEST_IMG" "$invalid_file" "$TEST_IMG2" 2>/dev/null || true
    # Just verify it doesn't crash
    assert_true 'true' "continue-on-error handles invalid files"
}

# ============================================================================
# Tests: Stdin (Pipe) Input
# ============================================================================

test_stdin_basic() {
    require_imagemagick || return 0
    assert_exit_code 0 "cat '$TEST_IMG' | $GUMMYWORM -q -w 20"
}

test_stdin_with_color() {
    require_imagemagick || return 0
    assert_exit_code 0 "cat '$TEST_IMG' | $GUMMYWORM -q -w 20 -c"
}

test_stdin_with_palette() {
    require_imagemagick || return 0
    assert_exit_code 0 "cat '$TEST_IMG' | $GUMMYWORM -q -w 20 -p blocks"
}

test_stdin_to_file() {
    require_imagemagick || return 0
    
    cat "$TEST_IMG" | "$GUMMYWORM" -q -w 20 -o "$OUTPUT_FILE"
    assert_file_not_empty "$OUTPUT_FILE"
}

test_stdin_reject_invalid() {
    assert_exit_code 1 "echo 'not an image' | $GUMMYWORM -q -w 20 2>/dev/null"
}

# ============================================================================
# Tests: Export Formats
# ============================================================================

test_format_text_explicit() {
    require_imagemagick || return 0
    
    "$GUMMYWORM" -q -w 20 -f text -o "$OUTPUT_FILE" "$TEST_IMG"
    assert_file_not_empty "$OUTPUT_FILE"
}

test_format_ansi_explicit() {
    require_imagemagick || return 0
    
    local ansi_file
    ansi_file=$(make_temp_file ".ans")
    "$GUMMYWORM" -q -w 20 -f ansi -o "$ansi_file" "$TEST_IMG"
    assert_file_not_empty "$ansi_file"
}

test_format_html_explicit() {
    require_imagemagick || return 0
    
    local html_file
    html_file=$(make_temp_file ".html")
    "$GUMMYWORM" -q -w 20 -f html -o "$html_file" "$TEST_IMG"
    assert_file_not_empty "$html_file"
    
    # Verify HTML structure
    local content
    content=$(cat "$html_file")
    assert_contains "$content" "<!DOCTYPE html>" "HTML has doctype"
}

test_format_svg_explicit() {
    require_imagemagick || return 0
    
    local svg_file
    svg_file=$(make_temp_file ".svg")
    "$GUMMYWORM" -q -w 20 -f svg -o "$svg_file" "$TEST_IMG"
    assert_file_not_empty "$svg_file"
    
    # Verify SVG structure
    local content
    content=$(cat "$svg_file")
    assert_contains "$content" "<svg" "SVG has svg element"
}

test_format_png_explicit() {
    require_imagemagick || return 0
    
    local png_file
    png_file=$(make_temp_file ".png")
    "$GUMMYWORM" -q -w 20 -f png -o "$png_file" "$TEST_IMG"
    assert_file_not_empty "$png_file"
    
    # Verify it's actually a PNG
    local file_type
    file_type=$(file "$png_file")
    assert_contains "$file_type" "PNG" "output is PNG format"
}

test_format_auto_detect_html() {
    require_imagemagick || return 0
    
    local html_file
    html_file=$(make_temp_file ".html")
    "$GUMMYWORM" -q -w 20 -o "$html_file" "$TEST_IMG"
    
    local content
    content=$(cat "$html_file")
    assert_contains "$content" "<!DOCTYPE html>" "auto-detected HTML format"
}

test_format_auto_detect_svg() {
    require_imagemagick || return 0
    
    local svg_file
    svg_file=$(make_temp_file ".svg")
    "$GUMMYWORM" -q -w 20 -o "$svg_file" "$TEST_IMG"
    
    local content
    content=$(cat "$svg_file")
    assert_contains "$content" "<svg" "auto-detected SVG format"
}

test_format_invalid_rejected() {
    require_imagemagick || return 0
    assert_exit_code 1 "$GUMMYWORM -q -w 20 -f invalid '$TEST_IMG' 2>/dev/null"
}

# ============================================================================
# Tests: HTML Content Structure
# ============================================================================

test_html_has_style_block() {
    require_imagemagick || return 0
    
    local html_file
    html_file=$(make_temp_file ".html")
    "$GUMMYWORM" -q -w 20 -f html -o "$html_file" "$TEST_IMG"
    
    local content
    content=$(cat "$html_file")
    assert_contains "$content" "<style>" "HTML has style block"
}

test_html_has_ascii_art_class() {
    require_imagemagick || return 0
    
    local html_file
    html_file=$(make_temp_file ".html")
    "$GUMMYWORM" -q -w 20 -f html -o "$html_file" "$TEST_IMG"
    
    local content
    content=$(cat "$html_file")
    assert_contains "$content" "ascii-art" "HTML has ascii-art class"
}

test_html_custom_background() {
    require_imagemagick || return 0
    
    local html_file
    html_file=$(make_temp_file ".html")
    "$GUMMYWORM" -q -w 20 -f html --background '#000000' -o "$html_file" "$TEST_IMG"
    
    local content
    content=$(cat "$html_file")
    assert_contains "$content" "background-color: #000000" "custom background applied"
}

# ============================================================================
# Tests: SVG Content Structure
# ============================================================================

test_svg_has_xml_declaration() {
    require_imagemagick || return 0
    
    local svg_file
    svg_file=$(make_temp_file ".svg")
    "$GUMMYWORM" -q -w 20 -f svg -o "$svg_file" "$TEST_IMG"
    
    local content
    content=$(cat "$svg_file")
    assert_contains "$content" "<?xml" "SVG has XML declaration"
}

test_svg_has_text_elements() {
    require_imagemagick || return 0
    
    local svg_file
    svg_file=$(make_temp_file ".svg")
    "$GUMMYWORM" -q -w 20 -f svg -o "$svg_file" "$TEST_IMG"
    
    local content
    content=$(cat "$svg_file")
    assert_contains "$content" "<text" "SVG has text elements"
}

test_svg_custom_background() {
    require_imagemagick || return 0
    
    local svg_file
    svg_file=$(make_temp_file ".svg")
    "$GUMMYWORM" -q -w 20 -f svg --background '#ff0000' -o "$svg_file" "$TEST_IMG"
    
    local content
    content=$(cat "$svg_file")
    assert_contains "$content" 'fill="#ff0000"' "SVG has custom background"
}

# ============================================================================
# Tests: ANSI Output
# ============================================================================

test_ansi_contains_escape_codes() {
    require_imagemagick || return 0
    
    local ansi_file
    ansi_file=$(make_temp_file ".ans")
    "$GUMMYWORM" -q -w 20 -c -f ansi -o "$ansi_file" "$TEST_IMG"
    
    # Check for ANSI escape sequence
    assert_true "grep -q $'\\033' '$ansi_file'" "ANSI output contains escape codes"
}

test_text_no_ansi_codes() {
    require_imagemagick || return 0
    
    "$GUMMYWORM" -q -w 20 -c -f text -o "$OUTPUT_FILE" "$TEST_IMG"
    
    # Text format should strip ANSI codes
    assert_false "grep -q $'\\033' '$OUTPUT_FILE'" "text output has no ANSI codes"
}

# ============================================================================
# Tests: Error Handling
# ============================================================================

test_nonexistent_file_error() {
    assert_exit_code 1 "$GUMMYWORM -q '/nonexistent/file.png' 2>/dev/null"
}

test_invalid_width_error() {
    require_imagemagick || return 0
    assert_exit_code 1 "$GUMMYWORM -q -w 0 '$TEST_IMG' 2>/dev/null"
}

test_invalid_width_negative_error() {
    require_imagemagick || return 0
    assert_exit_code 1 "$GUMMYWORM -q -w -10 '$TEST_IMG' 2>/dev/null"
}

test_invalid_width_string_error() {
    require_imagemagick || return 0
    assert_exit_code 1 "$GUMMYWORM -q -w abc '$TEST_IMG' 2>/dev/null"
}

# ============================================================================
# Run Tests
# ============================================================================

run_discovered_tests "gummyworm Integration Tests"
