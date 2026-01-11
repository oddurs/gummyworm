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
# Run tests
# ============================================================================

# Load config module to test
source "$SCRIPT_DIR/../lib/config.sh"

run_discovered_tests "Configuration File Tests"
