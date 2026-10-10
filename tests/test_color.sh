#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_color.sh - Tests for the colour engine
# ============================================================================
# Covers the glyph coverage table, background resolution, the optical engine
# and its fallbacks, and 256-colour snapping.
# Shell compatibility: Bash 3.2+
# ============================================================================

set -e; set -u; set -o pipefail 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

# shellcheck source=lib/all.sh
source "$PROJECT_ROOT/lib/all.sh"
init_image_deps

GUMMYWORM="$PROJECT_ROOT/bin/gummyworm"
SOLID_DIR=""

setup() {
    SOLID_DIR=$(make_temp_dir)
}

# A 200x100 image of one colour
# Usage: solid <name> <colour>; prints the path
solid() {
    local path="$SOLID_DIR/$1.png"
    [[ -f "$path" ]] || $_MAGICK_CONVERT -size 200x100 "xc:$2" "$path" 2>/dev/null
    printf '%s' "$path"
}

# The first foreground colour in an ANSI render, as "R;G;B" or the 256 index
first_color() {
    sed -n 's/.*\x1b\[38;[25];\([0-9;]*\)m.*/\1/p' | head -1
}

# ============================================================================
# Tests: glyph coverage table
# ============================================================================

test_coverage_table_covers_printable_ascii() {
    local table missing="" c
    table=$(glyph_coverage_table)
    for c in '!' '#' '.' '@' 'M' 'a' '~'; do
        printf '%s\n' "$table" | grep -q "^$(printf '%s' "$c" | sed 's/[][\.*^$/]/\\&/g')	" || missing="$missing $c"
    done
    assert_equals "" "$missing" "common glyphs all have a measured coverage"
}

test_coverage_values_are_fractions_and_ordered_sensibly() {
    local table dot hash space
    table=$(glyph_coverage_table)
    space=$(printf '%s\n' "$table" | awk -F'\t' '$1==" " {print $2}')
    dot=$(printf '%s\n' "$table" | awk -F'\t' '$1=="." {print $2}')
    hash=$(printf '%s\n' "$table" | awk -F'\t' '$1=="#" {print $2}')
    assert_equals "0.0000" "$space" "a space inks nothing"
    assert_true "awk -v a=$dot -v b=$hash 'BEGIN { exit !(a > 0 && a < b && b < 1) }'" \
        "a dot inks less than a hash, and both less than a full cell"
    assert_true "glyph_coverage_table | awk -F'\t' '\$2 < 0 || \$2 > 1.01 { bad=1 } END { exit bad }'" \
        "every coverage is between 0 and a full cell"
}

# ============================================================================
# Tests: background resolution
# ============================================================================

test_color_to_rgb_hex() {
    assert_equals "30 30 30" "$(color_to_rgb '#1e1e1e')" "six digit hex"
    assert_equals "255 0 0" "$(color_to_rgb '#f00')" "three digit hex expands"
    assert_equals "0 0 0" "$(color_to_rgb '#000000')" "black"
}

test_color_to_rgb_named() {
    has_imagemagick || { skip_test "ImageMagick not available"; return 0; }
    assert_equals "0 0 0" "$(color_to_rgb black)" "a named colour resolves through ImageMagick"
}

# ============================================================================
# Tests: the optical engine
# ============================================================================

test_optical_normalises_a_dim_colour_to_full_strength() {
    has_imagemagick || { skip_test "ImageMagick not available"; return 0; }
    # A dark orange. The plain engine paints glyphs in this dark colour, so it
    # reaches the eye at a fraction of its brightness. The optical engine picks
    # a lighter foreground and a sparser glyph to deliver the same colour.
    local img plain optical pr pg pb or_ og ob
    img=$(solid orange "rgb(120,60,30)")
    plain=$($GUMMYWORM -q -w 8 --enhance off --color-engine plain -c --truecolor --background '#000000' "$img" | first_color)
    optical=$($GUMMYWORM -q -w 8 --enhance off --color-engine optical -c --truecolor --background '#000000' "$img" | first_color)
    IFS=';' read -r pr pg pb <<< "$plain"
    IFS=';' read -r or_ og ob <<< "$optical"
    assert_true "[[ $or_ -gt $pr ]]" "the optical foreground is brighter than the plain one ($or_ vs $pr)"
    assert_true "[[ $or_ -ge $og && $og -ge $ob ]]" "hue order is kept (r >= g >= b): $optical"
}

test_optical_black_is_background() {
    has_imagemagick || { skip_test "ImageMagick not available"; return 0; }
    local out
    out=$($GUMMYWORM -q -w 8 --enhance off --color-engine optical -c --truecolor "$(solid black black)" | sed 's/\x1b\[[0-9;]*m//g')
    assert_equals "" "$(printf '%s' "$out" | tr -d ' \n')" "a black image renders as spaces, not dim dots"
}

test_optical_falls_back_to_plain_where_it_cannot_be_exact() {
    has_imagemagick || { skip_test "ImageMagick not available"; return 0; }
    local img
    img=$(solid teal "rgb(30,140,150)")
    assert_equals \
        "$($GUMMYWORM -q -w 8 --enhance off --color-engine plain -c --truecolor -i "$img")" \
        "$($GUMMYWORM -q -w 8 --enhance off --color-engine optical -c --truecolor -i "$img")" \
        "--invert uses the plain engine"
    assert_equals \
        "$($GUMMYWORM -q -w 8 --enhance off --color-engine plain -c --truecolor --background '#ffffff' "$img")" \
        "$($GUMMYWORM -q -w 8 --enhance off --color-engine optical -c --truecolor --background '#ffffff' "$img")" \
        "a light background uses the plain engine"
    assert_equals \
        "$($GUMMYWORM -q -w 8 --enhance off --color-engine plain -c --truecolor -p emoji "$img")" \
        "$($GUMMYWORM -q -w 8 --enhance off --color-engine optical -c --truecolor -p emoji "$img")" \
        "a palette without measured coverage uses the plain engine"
}

test_engine_does_not_affect_monochrome_output() {
    has_imagemagick || { skip_test "ImageMagick not available"; return 0; }
    local img
    img=$(solid gray "rgb(120,120,120)")
    assert_equals \
        "$($GUMMYWORM -q -w 8 --color-engine plain "$img")" \
        "$($GUMMYWORM -q -w 8 --color-engine optical "$img")" \
        "without colour, both engines print the same text"
}

# ============================================================================
# Tests: 256-colour snapping
# ============================================================================

test_256_snaps_to_the_real_palette() {
    has_imagemagick || { skip_test "ImageMagick not available"; return 0; }
    local code
    code=$($GUMMYWORM -q -w 4 --enhance off --color-engine plain -c "$(solid red red)" | first_color)
    assert_equals "196" "$code" "pure red is colour 196"
    # Mid grey is nearer the grey ramp (232-255) than any cube colour
    code=$($GUMMYWORM -q -w 4 --enhance off --color-engine plain -c "$(solid grey128 'rgb(128,128,128)')" | first_color)
    assert_true "[[ $code -ge 232 ]]" "mid grey uses the grey ramp, got $code"
    # (95,95,95) is exactly cube level 1 on every channel: 16 + 36 + 6 + 1
    code=$($GUMMYWORM -q -w 4 --enhance off --color-engine plain -c "$(solid cubelevel 'rgb(95,95,95)')" | first_color)
    assert_equals "59" "$code" "an exact cube level maps to its cube colour"
}

# ============================================================================
# Run
# ============================================================================

run_discovered_tests "Colour Engine"
