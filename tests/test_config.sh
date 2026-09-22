#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_config.sh - Unit tests for configuration file loading
# ============================================================================
# Tests config file parsing and loading from various locations.
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

# ============================================================================
# Setup/Teardown
# ============================================================================

TEST_TMP_DIR=""

setup_config_tests() {
    TEST_TMP_DIR="$(mktemp -d)"
}

cleanup_config_tests() {
    [[ -n "$TEST_TMP_DIR" && -d "$TEST_TMP_DIR" ]] && rm -rf "$TEST_TMP_DIR"
}

# ============================================================================
# Tests: _load_config_file()
# ============================================================================

test_load_config_file_basic() {
    setup_config_tests

    # Create a test config
    cat > "$TEST_TMP_DIR/config" << 'EOF'
width=120
palette=blocks
color=true
EOF

    # Reset to defaults first
    CONFIG_WIDTH="80"
    CONFIG_PALETTE="standard"
    CONFIG_COLOR="false"

    # Load the config
    _load_config_file "$TEST_TMP_DIR/config"

    assert_equals "$CONFIG_WIDTH" "120" "width loaded from config"
    assert_equals "$CONFIG_PALETTE" "blocks" "palette loaded from config"
    assert_equals "$CONFIG_COLOR" "true" "color loaded from config"

    cleanup_config_tests
}

test_load_config_file_with_comments() {
    setup_config_tests

    cat > "$TEST_TMP_DIR/config" << 'EOF'
# This is a comment
width=100

# Another comment
palette=emoji
# color=true  <- this should be ignored
EOF

    CONFIG_WIDTH="80"
    CONFIG_PALETTE="standard"
    CONFIG_COLOR="false"

    _load_config_file "$TEST_TMP_DIR/config"

    assert_equals "$CONFIG_WIDTH" "100" "width loaded despite comments"
    assert_equals "$CONFIG_PALETTE" "emoji" "palette loaded despite comments"
    assert_equals "$CONFIG_COLOR" "false" "commented setting ignored"

    cleanup_config_tests
}

test_load_config_file_with_quotes() {
    setup_config_tests

    cat > "$TEST_TMP_DIR/config" << 'EOF'
background="#1a1a2e"
palette='blocks'
gamma="1.5"
EOF

    CONFIG_BACKGROUND="#1e1e1e"
    CONFIG_PALETTE="standard"
    CONFIG_GAMMA="1.0"

    _load_config_file "$TEST_TMP_DIR/config"

    assert_equals "$CONFIG_BACKGROUND" "#1a1a2e" "double-quoted value parsed"
    assert_equals "$CONFIG_PALETTE" "blocks" "single-quoted value parsed"
    assert_equals "$CONFIG_GAMMA" "1.5" "quoted number parsed"

    cleanup_config_tests
}

test_load_config_file_with_whitespace() {
    setup_config_tests

    cat > "$TEST_TMP_DIR/config" << 'EOF'
  width = 150
palette=  detailed
  contrast  =  25
EOF

    CONFIG_WIDTH="80"
    CONFIG_PALETTE="standard"
    CONFIG_CONTRAST="0"

    _load_config_file "$TEST_TMP_DIR/config"

    assert_equals "$CONFIG_WIDTH" "150" "whitespace around = handled"
    assert_equals "$CONFIG_PALETTE" "detailed" "whitespace after = handled"
    assert_equals "$CONFIG_CONTRAST" "25" "whitespace everywhere handled"

    cleanup_config_tests
}

test_load_config_file_empty_lines() {
    setup_config_tests

    cat > "$TEST_TMP_DIR/config" << 'EOF'

width=90

palette=dots


EOF

    CONFIG_WIDTH="80"
    CONFIG_PALETTE="standard"

    _load_config_file "$TEST_TMP_DIR/config"

    assert_equals "$CONFIG_WIDTH" "90" "empty lines don't break parsing"
    assert_equals "$CONFIG_PALETTE" "dots" "values after empty lines work"

    cleanup_config_tests
}

test_load_config_file_nonexistent() {
    # Should not error, just return
    CONFIG_WIDTH="80"
    _load_config_file "/nonexistent/path/config"
    assert_equals "$CONFIG_WIDTH" "80" "nonexistent file doesn't change values"
}

test_load_config_file_all_settings() {
    setup_config_tests

    cat > "$TEST_TMP_DIR/config" << 'EOF'
width=200
height=50
palette=matrix
invert=true
color=true
truecolor=true
format=html
background=#000000
padding=20
brightness=-10
contrast=30
gamma=2.2
animate=false
frame_delay=200
max_frames=10
loops=5
quiet=true
preserve_aspect=false
EOF

    # Reset all values
    CONFIG_WIDTH="80"; CONFIG_HEIGHT="0"; CONFIG_PALETTE="standard"
    CONFIG_INVERT="false"; CONFIG_COLOR="false"; CONFIG_TRUECOLOR="false"
    CONFIG_FORMAT="text"; CONFIG_BACKGROUND="#1e1e1e"; CONFIG_PADDING="0"
    CONFIG_BRIGHTNESS="0"; CONFIG_CONTRAST="0"; CONFIG_GAMMA="1.0"
    CONFIG_ANIMATE="auto"; CONFIG_FRAME_DELAY="100"; CONFIG_MAX_FRAMES="0"
    CONFIG_LOOPS="0"; CONFIG_QUIET="false"; CONFIG_PRESERVE_ASPECT="true"

    _load_config_file "$TEST_TMP_DIR/config"

    assert_equals "$CONFIG_WIDTH" "200" "width"
    assert_equals "$CONFIG_HEIGHT" "50" "height"
    assert_equals "$CONFIG_PALETTE" "matrix" "palette"
    assert_equals "$CONFIG_INVERT" "true" "invert"
    assert_equals "$CONFIG_COLOR" "true" "color"
    assert_equals "$CONFIG_TRUECOLOR" "true" "truecolor"
    assert_equals "$CONFIG_FORMAT" "html" "format"
    assert_equals "$CONFIG_BACKGROUND" "#000000" "background"
    assert_equals "$CONFIG_PADDING" "20" "padding"
    assert_equals "$CONFIG_BRIGHTNESS" "-10" "brightness"
    assert_equals "$CONFIG_CONTRAST" "30" "contrast"
    assert_equals "$CONFIG_GAMMA" "2.2" "gamma"
    assert_equals "$CONFIG_ANIMATE" "false" "animate"
    assert_equals "$CONFIG_FRAME_DELAY" "200" "frame_delay"
    assert_equals "$CONFIG_MAX_FRAMES" "10" "max_frames"
    assert_equals "$CONFIG_LOOPS" "5" "loops"
    assert_equals "$CONFIG_QUIET" "true" "quiet"
    assert_equals "$CONFIG_PRESERVE_ASPECT" "false" "preserve_aspect"

    cleanup_config_tests
}

test_load_config_file_unknown_keys_ignored() {
    setup_config_tests

    cat > "$TEST_TMP_DIR/config" << 'EOF'
width=100
unknown_setting=foobar
another_bad_key=123
palette=stars
EOF

    CONFIG_WIDTH="80"
    CONFIG_PALETTE="standard"

    # Should not error
    _load_config_file "$TEST_TMP_DIR/config"

    assert_equals "$CONFIG_WIDTH" "100" "known keys still work"
    assert_equals "$CONFIG_PALETTE" "stars" "known keys after unknown still work"

    cleanup_config_tests
}

# ============================================================================
# Tests: Config file priority
# ============================================================================

test_config_file_priority() {
    setup_config_tests

    # Create two config files
    mkdir -p "$TEST_TMP_DIR/first"
    mkdir -p "$TEST_TMP_DIR/second"

    cat > "$TEST_TMP_DIR/first/config" << 'EOF'
width=100
palette=blocks
EOF

    cat > "$TEST_TMP_DIR/second/config" << 'EOF'
width=200
EOF

    CONFIG_WIDTH="80"
    CONFIG_PALETTE="standard"

    # Load in order (simulating the priority)
    _load_config_file "$TEST_TMP_DIR/first/config"
    _load_config_file "$TEST_TMP_DIR/second/config"

    # Second file should override width but not palette
    assert_equals "$CONFIG_WIDTH" "200" "later config overrides width"
    assert_equals "$CONFIG_PALETTE" "blocks" "earlier config preserved for palette"

    cleanup_config_tests
}

# ============================================================================
# Tests: background colour validation
# ============================================================================
# A config file's background= value does not come from the person running the
# command -- ./.gummywormrc ships with a cloned repository -- so it is
# validated on the way in rather than trusted.

test_config_accepts_valid_background() {
    setup_config_tests
    mkdir -p "$TEST_TMP_DIR"
    printf 'background=#abcdef\n' > "$TEST_TMP_DIR/config"

    CONFIG_BACKGROUND="#1e1e1e"
    _load_config_file "$TEST_TMP_DIR/config" 2>/dev/null

    assert_equals "#abcdef" "$CONFIG_BACKGROUND" "a valid hex background is accepted"
    cleanup_config_tests
}

test_config_accepts_named_background() {
    setup_config_tests
    printf 'background=black\n' > "$TEST_TMP_DIR/config"

    CONFIG_BACKGROUND="#1e1e1e"
    _load_config_file "$TEST_TMP_DIR/config" 2>/dev/null

    assert_equals "black" "$CONFIG_BACKGROUND" "a valid named background is accepted"
    cleanup_config_tests
}

test_config_rejects_invalid_background() {
    setup_config_tests
    printf 'background=notacolor\n' > "$TEST_TMP_DIR/config"

    CONFIG_BACKGROUND="#1e1e1e"
    _load_config_file "$TEST_TMP_DIR/config" 2>/dev/null

    assert_equals "#1e1e1e" "$CONFIG_BACKGROUND" "an unknown background name is ignored"
    cleanup_config_tests
}

test_config_rejects_markup_in_background() {
    setup_config_tests
    printf 'background=%s\n' '"><script>x</script>' > "$TEST_TMP_DIR/config"

    CONFIG_BACKGROUND="#1e1e1e"
    _load_config_file "$TEST_TMP_DIR/config" 2>/dev/null

    assert_equals "#1e1e1e" "$CONFIG_BACKGROUND" "a background carrying markup is ignored"
    cleanup_config_tests
}

# ============================================================================
# Tests: every config value is validated (security boundary)
# ============================================================================
# Numeric config values end up in shell arithmetic, where bash evaluates a
# variable's value as an expression -- including array subscripts, which
# undergo command substitution. ./.gummywormrc travels with cloned repositories,
# so an unvalidated `width=HOME[$(cmd)]` ran cmd.

# Every key the loader maps, with one valid and one invalid value
CONFIG_KEY_CASES=(
    "width:100:0"
    "height:0:-1"
    "padding:10:ten"
    "brightness:-100:101"
    "contrast:100:-101"
    "gamma:2.2:10.5"
    "char_aspect:2.0:0.4"
    "frame_delay:50:0"
    "max_frames:0:-1"
    "loops:3:3.5"
    "invert:true:yes"
    "color:false:1"
    "truecolor:true:on"
    "animate:false:no"
    "quiet:true:TRUE"
    "preserve_aspect:false:0"
    "format:svg:pdf"
    "background:#1e1e1e:notacolor"
)

test_config_validator_accepts_and_rejects_every_key() {
    local entry key good bad
    for entry in "${CONFIG_KEY_CASES[@]}"; do
        key="${entry%%:*}"; good="${entry#*:}"; good="${good%%:*}"; bad="${entry##*:}"
        assert_true  "_config_value_valid '$key' '$good'" "$key accepts '$good'"
        assert_false "_config_value_valid '$key' '$bad'"  "$key rejects '$bad'"
    done
}

test_config_validator_rejects_arithmetic_payloads_for_every_key() {
    local entry key payload
    for entry in "${CONFIG_KEY_CASES[@]}"; do
        key="${entry%%:*}"
        for payload in 'HOME[$(touch /tmp/x)]' 'a[`id`]' '1+1' ' 5' '5;id'; do
            assert_false "_config_value_valid '$key' '$payload'" "$key rejects '$payload'"
        done
    done
}

test_config_integer_keys_reject_leading_zeros() {
    # Integer values reach bash arithmetic, which reads 08 as invalid octal.
    # Decimal keys (gamma, char_aspect) go to awk, where 08 is simply 8.
    local key
    for key in width height padding brightness contrast frame_delay max_frames loops; do
        assert_false "_config_value_valid '$key' '08'" "$key rejects a leading zero"
    done
}

test_config_validator_leaves_unknown_keys_alone() {
    local rc=0
    _config_value_valid "no_such_key" "whatever" || rc=$?
    assert_equals "2" "$rc" "an unknown key is reported as unknown, not invalid"
}

test_config_invalid_value_keeps_default_and_warns() {
    setup_config_tests
    printf 'width=HOME[$(touch %s/PWNED)]\n' "$TEST_TMP_DIR" > "$TEST_TMP_DIR/config"
    CONFIG_WIDTH="80"
    local err
    err=$(_load_config_file "$TEST_TMP_DIR/config" 2>&1 >/dev/null)
    assert_equals "80" "$CONFIG_WIDTH" "an invalid width keeps the default"
    assert_contains "$err" "ignoring invalid value for 'width'" "the key is named in a warning"
    assert_not_contains "$err" 'HOME[' "the raw value is not echoed back"
    assert_true "[[ ! -e '$TEST_TMP_DIR/PWNED' ]]" "loading the value executed nothing"
    cleanup_config_tests
}

test_config_valid_values_take_effect() {
    setup_config_tests
    printf 'width=123\nheight=45\ngamma=1.8\ninvert=true\nformat=html\n' > "$TEST_TMP_DIR/config"
    CONFIG_WIDTH=80; CONFIG_HEIGHT=0; CONFIG_GAMMA=1.0; CONFIG_INVERT=false; CONFIG_FORMAT=text
    _load_config_file "$TEST_TMP_DIR/config" 2>/dev/null
    assert_equals "123"  "$CONFIG_WIDTH"  "width takes effect"
    assert_equals "45"   "$CONFIG_HEIGHT" "height takes effect"
    assert_equals "1.8"  "$CONFIG_GAMMA"  "gamma takes effect"
    assert_equals "true" "$CONFIG_INVERT" "invert takes effect"
    assert_equals "html" "$CONFIG_FORMAT" "format takes effect"
    cleanup_config_tests
}

# End to end: run the real binary inside a directory whose ./.gummywormrc
# carries the payload, through every key, and assert nothing executed.
test_project_config_cannot_execute_commands() {
    local d marker entry key
    d=$(mktemp -d)
    marker="$d/PWNED"
    local img="$d/in.png"
    if command -v magick >/dev/null 2>&1; then
        magick -size 20x20 xc:white -fill black -draw "circle 10,10 10,3" "$img" 2>/dev/null
    else
        convert -size 20x20 xc:white -fill black -draw "circle 10,10 10,3" "$img" 2>/dev/null
    fi
    for entry in "${CONFIG_KEY_CASES[@]}" "palette:x:x"; do
        key="${entry%%:*}"
        rm -f "$marker"
        printf '%s=HOME[$(touch %s)]\n' "$key" "$marker" > "$d/.gummywormrc"
        ( cd "$d" && "$PROJECT_ROOT/gummyworm" -q "$img" >/dev/null 2>&1 ) || true
        ( cd "$d" && "$PROJECT_ROOT/gummyworm" -q -f svg -o "$d/o.svg" "$img" >/dev/null 2>&1 ) || true
        assert_true "[[ ! -e '$marker' ]]" "$key= in ./.gummywormrc executes nothing"
    done
    rm -rf "$d"
}

# ============================================================================
# Run tests
# ============================================================================

# Load config module to test
source "$SCRIPT_DIR/../lib/config.sh"

run_discovered_tests "Configuration File Tests"
