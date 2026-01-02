#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_export.sh - Unit tests for lib/export.sh & lib/converter.sh
# ============================================================================
# Tests export format detection, validation, and color conversion.
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

# Load gummyworm libraries for unit testing
load_gummyworm_libs

# ============================================================================
# Tests: export_detect_format()
# ============================================================================

test_export_detect_format_html() {
    local format
    format=$(export_detect_format "output.html")
    assert_equals "html" "$format" ".html detected as html"
    
    format=$(export_detect_format "output.htm")
    assert_equals "html" "$format" ".htm detected as html"
}

test_export_detect_format_svg() {
    local format
    format=$(export_detect_format "output.svg")
    assert_equals "svg" "$format" ".svg detected as svg"
}

test_export_detect_format_png() {
    local format
    format=$(export_detect_format "output.png")
    assert_equals "png" "$format" ".png detected as png"
}

test_export_detect_format_ansi() {
    local format
    format=$(export_detect_format "output.ans")
    assert_equals "ansi" "$format" ".ans detected as ansi"
    
    format=$(export_detect_format "output.ansi")
    assert_equals "ansi" "$format" ".ansi detected as ansi"
}

test_export_detect_format_text() {
    local format
    format=$(export_detect_format "output.txt")
    assert_equals "text" "$format" ".txt detected as text"
}

test_export_detect_format_unknown() {
    local format
    format=$(export_detect_format "output.xyz")
    assert_equals "text" "$format" "unknown extension defaults to text"
    
    format=$(export_detect_format "noextension")
    assert_equals "text" "$format" "no extension defaults to text"
}

test_export_detect_format_case_insensitive() {
    local format
    format=$(export_detect_format "output.HTML")
    assert_equals "html" "$format" ".HTML detected as html"
    
    format=$(export_detect_format "output.SVG")
    assert_equals "svg" "$format" ".SVG detected as svg"
    
    format=$(export_detect_format "output.PNG")
    assert_equals "png" "$format" ".PNG detected as png"
}

test_export_detect_format_with_path() {
    local format
    format=$(export_detect_format "/path/to/output.html")
    assert_equals "html" "$format" "path with .html detected"
    
    format=$(export_detect_format "./relative/output.svg")
    assert_equals "svg" "$format" "relative path with .svg detected"
}

# ============================================================================
# Tests: export_validate_format()
# ============================================================================

test_export_validate_format_valid() {
    assert_true 'export_validate_format "text"' "text is valid format"
    assert_true 'export_validate_format "ansi"' "ansi is valid format"
    assert_true 'export_validate_format "html"' "html is valid format"
    assert_true 'export_validate_format "svg"' "svg is valid format"
    assert_true 'export_validate_format "png"' "png is valid format"
}

test_export_validate_format_invalid() {
    assert_false 'export_validate_format "pdf"' "pdf is not valid format"
    assert_false 'export_validate_format "jpg"' "jpg is not valid format"
    assert_false 'export_validate_format "gif"' "gif is not valid format"
    assert_false 'export_validate_format ""' "empty is not valid format"
    assert_false 'export_validate_format "invalid"' "invalid is not valid format"
}

# ============================================================================
# Tests: export_get_extension()
# ============================================================================

test_export_get_extension_text() {
    local ext
    ext=$(export_get_extension "text")
    assert_equals "txt" "$ext" "text -> txt"
}

test_export_get_extension_ansi() {
    local ext
    ext=$(export_get_extension "ansi")
    assert_equals "ans" "$ext" "ansi -> ans"
}

test_export_get_extension_html() {
    local ext
    ext=$(export_get_extension "html")
    assert_equals "html" "$ext" "html -> html"
}

test_export_get_extension_svg() {
    local ext
    ext=$(export_get_extension "svg")
    assert_equals "svg" "$ext" "svg -> svg"
}

test_export_get_extension_png() {
    local ext
    ext=$(export_get_extension "png")
    assert_equals "png" "$ext" "png -> png"
}

test_export_get_extension_unknown() {
    local ext
    ext=$(export_get_extension "unknown")
    assert_equals "txt" "$ext" "unknown defaults to txt"
}

# ============================================================================
# Tests: rgb_to_ansi() from converter.sh
# ============================================================================

test_rgb_to_ansi_black() {
    local ansi
    ansi=$(rgb_to_ansi 0 0 0)
    # Black should map to color 16 (first in 6x6x6 cube)
    assert_contains "$ansi" "38;5;16" "black maps to ANSI 16"
}

test_rgb_to_ansi_white() {
    local ansi
    ansi=$(rgb_to_ansi 255 255 255)
    # White should map to color 231 (last in 6x6x6 cube)
    assert_contains "$ansi" "38;5;231" "white maps to ANSI 231"
}

test_rgb_to_ansi_red() {
    local ansi
    ansi=$(rgb_to_ansi 255 0 0)
    # Pure red: r_idx=5, g_idx=0, b_idx=0 -> 16 + 5*36 + 0 + 0 = 196
    assert_contains "$ansi" "38;5;196" "red maps to ANSI 196"
}

test_rgb_to_ansi_green() {
    local ansi
    ansi=$(rgb_to_ansi 0 255 0)
    # Pure green: r_idx=0, g_idx=5, b_idx=0 -> 16 + 0 + 5*6 + 0 = 46
    assert_contains "$ansi" "38;5;46" "green maps to ANSI 46"
}

test_rgb_to_ansi_blue() {
    local ansi
    ansi=$(rgb_to_ansi 0 0 255)
    # Pure blue: r_idx=0, g_idx=0, b_idx=5 -> 16 + 0 + 0 + 5 = 21
    assert_contains "$ansi" "38;5;21" "blue maps to ANSI 21"
}

test_rgb_to_ansi_mid_gray() {
    local ansi
    ansi=$(rgb_to_ansi 128 128 128)
    # Mid gray: r_idx=2, g_idx=2, b_idx=2 -> 16 + 2*36 + 2*6 + 2 = 102
    assert_contains "$ansi" "38;5;" "mid gray produces ANSI code"
}

test_rgb_to_ansi_escape_format() {
    local ansi
    ansi=$(rgb_to_ansi 100 150 200)
    # Should produce escape sequence format
    assert_matches "$ansi" "\\\\033\[38;5;[0-9]+m" "correct escape format"
}

# ============================================================================
# Tests: export_html() output structure
# ============================================================================

test_export_html_doctype() {
    local html
    html=$(export_html "test content")
    assert_contains "$html" "<!DOCTYPE html>" "HTML has doctype"
}

test_export_html_charset() {
    local html
    html=$(export_html "test content")
    assert_contains "$html" 'charset="UTF-8"' "HTML has UTF-8 charset"
}

test_export_html_ascii_art_class() {
    local html
    html=$(export_html "test content")
    assert_contains "$html" 'class="ascii-art"' "HTML has ascii-art class"
}

test_export_html_custom_background() {
    local html
    html=$(export_html "test" "#ff0000")
    assert_contains "$html" "background-color: #ff0000" "custom background applied"
}

test_export_html_default_background() {
    local html
    html=$(export_html "test")
    assert_contains "$html" "background-color: #1e1e1e" "default background applied"
}

test_export_html_custom_title() {
    local html
    html=$(export_html "test" "#000000" "My Custom Title")
    assert_contains "$html" "<title>My Custom Title</title>" "custom title applied"
}

# ============================================================================
# Tests: EXPORT_FORMATS constant
# ============================================================================

test_export_formats_all_defined() {
    assert_contains "$EXPORT_FORMATS" "text" "text in EXPORT_FORMATS"
    assert_contains "$EXPORT_FORMATS" "ansi" "ansi in EXPORT_FORMATS"
    assert_contains "$EXPORT_FORMATS" "html" "html in EXPORT_FORMATS"
    assert_contains "$EXPORT_FORMATS" "svg" "svg in EXPORT_FORMATS"
    assert_contains "$EXPORT_FORMATS" "png" "png in EXPORT_FORMATS"
}

# ============================================================================
# Tests: Round-trip format detection and extension
# ============================================================================

test_format_extension_roundtrip() {
    # For each format, get extension and verify it detects back to same format
    for format in text ansi html svg png; do
        local ext
        ext=$(export_get_extension "$format")
        local detected
        detected=$(export_detect_format "test.$ext")
        assert_equals "$format" "$detected" "roundtrip for $format"
    done
}

# ============================================================================
# Run Tests
# ============================================================================

run_discovered_tests "lib/export.sh & lib/converter.sh Unit Tests"
