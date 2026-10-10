#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_cli.sh - Unit tests for argument parsing
# ============================================================================
# Tests parse_args() directly: per-flag validation, range boundaries, missing
# arguments, unknown options, config/CLI precedence, and positional collection.
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

# shellcheck source=lib/all.sh
source "$PROJECT_ROOT/lib/all.sh"
init_image_deps

# Run from a scratch directory. parse_args creates --output-dir with mkdir -p,
# so a test that ever passes a relative -d value writes into the working
# directory. That once left an empty ./dummy.png directory in the repository
# root, and because DUMMY_IMAGE is relative, every "accepts" test then expanded
# it as a directory, found no images, and passed only by falling through to
# stdin. A private cwd keeps the suite from polluting the tree or reading back
# its own leftovers.
CLI_TEST_CWD=$(mktemp -d)
cd "$CLI_TEST_CWD" || exit 1
# Chain onto test_runner.sh's own EXIT trap rather than replacing it.
trap 'rm -rf "$CLI_TEST_CWD"; cleanup_temp' EXIT

# ============================================================================
# Helpers
# ============================================================================
#
# parse_args exits via die_usage on a bad value, so every call runs in a
# subshell. A trailing positional keeps it off the "no images" path, which
# would print help and exit 1 for reasons unrelated to what is under test.
# The file need not exist: parse_args only collects non-directory inputs.

DUMMY_IMAGE="dummy.png"

# Every helper redirects stdin from /dev/null. With no image argument and a
# stdin that is not a terminal, parse_args reads an image from stdin -- which
# blocks forever if stdin is an open pipe or terminal, as it is when the suite
# runs under run_all.sh. These tests are about parsing, not stdin handling.

# Succeeds when parse_args accepts the given flags
cli_accepts() {
    ( parse_args "$@" "$DUMMY_IMAGE" >/dev/null 2>&1 </dev/null )
}

# Succeeds when parse_args rejects the given flags
cli_rejects() {
    ! ( parse_args "$@" "$DUMMY_IMAGE" >/dev/null 2>&1 </dev/null )
}

# Succeeds when parse_args rejects the flags with nothing following them.
# No positional is appended: a flag takes the next token whatever it is, so
# appending one would make the flag consume it rather than report it missing.
cli_rejects_bare() {
    ! ( parse_args "$@" >/dev/null 2>&1 </dev/null )
}

# Echo the value an ARG_ variable ends up holding
# Usage: cli_value <ARG_NAME> [flags...]
cli_value() {
    local var="$1"
    shift
    (
        parse_args "$@" "$DUMMY_IMAGE" >/dev/null 2>&1 </dev/null
        eval "printf '%s' \"\${$var:-}\""
    )
}

# ============================================================================
# Tests: numeric flag validation
# ============================================================================

test_width_validation() {
    assert_true  'cli_accepts -w 80'        "--width accepts a positive integer"
    assert_equals "80" "$(cli_value ARG_WIDTH -w 80)" "--width is stored"
    assert_true  'cli_rejects -w abc'       "--width rejects non-numeric"
    assert_true  'cli_rejects -w 0'         "--width rejects zero"
    assert_true  'cli_rejects -w -5'        "--width rejects negative"
}

test_height_validation() {
    assert_true  'cli_accepts -h 40'        "--height accepts a positive integer"
    assert_true  'cli_accepts -h 0'         "--height accepts zero (auto)"
    assert_equals "40" "$(cli_value ARG_HEIGHT -h 40)" "--height is stored"
    assert_true  'cli_rejects -h abc'       "--height rejects non-numeric"
}

test_padding_validation() {
    assert_true  'cli_accepts --padding 10' "--padding accepts a non-negative integer"
    assert_true  'cli_accepts --padding 0'  "--padding accepts zero"
    assert_true  'cli_rejects --padding -1' "--padding rejects negative"
    assert_true  'cli_rejects --padding x'  "--padding rejects non-numeric"
}

test_frame_delay_validation() {
    assert_true  'cli_accepts --frame-delay 100' "--frame-delay accepts a positive integer"
    assert_true  'cli_rejects --frame-delay 0'   "--frame-delay rejects zero"
    assert_true  'cli_rejects --frame-delay abc' "--frame-delay rejects non-numeric"
}

test_max_frames_validation() {
    assert_true  'cli_accepts --max-frames 30' "--max-frames accepts a positive integer"
    assert_true  'cli_accepts --max-frames 0'  "--max-frames accepts zero (unlimited)"
    assert_true  'cli_rejects --max-frames -1' "--max-frames rejects negative"
}

test_loops_validation() {
    assert_true  'cli_accepts --loops 3'  "--loops accepts a positive integer"
    assert_true  'cli_accepts --loops 0'  "--loops accepts zero (infinite)"
    assert_true  'cli_rejects --loops -1' "--loops rejects negative"
}

# ============================================================================
# Tests: inclusive range boundaries
# ============================================================================
# Every range below is documented as inclusive, so both ends are asserted --
# an off-by-one in the comparison only shows up at the boundary.

test_brightness_range_boundaries() {
    assert_true  'cli_accepts --brightness -100' "--brightness accepts the lower bound"
    assert_true  'cli_accepts --brightness 100'  "--brightness accepts the upper bound"
    assert_true  'cli_accepts --brightness 0'    "--brightness accepts zero"
    assert_true  'cli_rejects --brightness -101' "--brightness rejects below the lower bound"
    assert_true  'cli_rejects --brightness 101'  "--brightness rejects above the upper bound"
    assert_true  'cli_rejects --brightness 1.5'  "--brightness rejects a non-integer"
}

test_contrast_range_boundaries() {
    assert_true  'cli_accepts --contrast -100' "--contrast accepts the lower bound"
    assert_true  'cli_accepts --contrast 100'  "--contrast accepts the upper bound"
    assert_true  'cli_rejects --contrast -101' "--contrast rejects below the lower bound"
    assert_true  'cli_rejects --contrast 101'  "--contrast rejects above the upper bound"
}

test_gamma_range_boundaries() {
    assert_true  'cli_accepts --gamma 0.1'  "--gamma accepts the lower bound"
    assert_true  'cli_accepts --gamma 10.0' "--gamma accepts the upper bound"
    assert_true  'cli_accepts --gamma 2.2'  "--gamma accepts a mid-range value"
    assert_true  'cli_rejects --gamma 0.09' "--gamma rejects below the lower bound"
    assert_true  'cli_rejects --gamma 10.1' "--gamma rejects above the upper bound"
    assert_true  'cli_rejects --gamma abc'  "--gamma rejects non-numeric"
    assert_true  'cli_rejects --gamma -1'   "--gamma rejects negative"
}

test_char_aspect_range_boundaries() {
    assert_true  'cli_accepts --char-aspect 0.5' "--char-aspect accepts the lower bound"
    assert_true  'cli_accepts --char-aspect 5.0' "--char-aspect accepts the upper bound"
    assert_true  'cli_accepts --char-aspect 2.0' "--char-aspect accepts the default"
    assert_true  'cli_rejects --char-aspect 0.4' "--char-aspect rejects below the lower bound"
    assert_true  'cli_rejects --char-aspect 5.1' "--char-aspect rejects above the upper bound"
    assert_true  'cli_rejects --char-aspect abc' "--char-aspect rejects non-numeric"
}

# ============================================================================
# Tests: enumerated and colour flags
# ============================================================================

test_format_validation() {
    local fmt
    for fmt in text ansi html svg png gif; do
        assert_true "cli_accepts -f $fmt" "--format accepts $fmt"
    done
    assert_equals "svg" "$(cli_value ARG_FORMAT -f svg)" "--format is stored"
    assert_true 'cli_rejects -f pdf'  "--format rejects an unsupported format"
    assert_true 'cli_rejects -f ""'   "--format rejects empty"
}

test_background_validation() {
    assert_true 'cli_accepts --background "#1e1e1e"'  "--background accepts 6-digit hex"
    assert_true 'cli_accepts --background "#fff"'     "--background accepts 3-digit hex"
    assert_true 'cli_accepts --background black'    "--background accepts a named colour"
    assert_true 'cli_accepts --background TRANSPARENT' "--background accepts a named colour case-insensitively"
    assert_true 'cli_rejects --background notacolor' "--background rejects an unknown name"
    assert_true 'cli_rejects --background "#12345"'   "--background rejects malformed hex"
    # The value reaches SVG/HTML markup, so it must not be able to carry markup.
    assert_true 'cli_rejects --background "\"><script>x</script>"' \
        "--background rejects a value containing markup"
}

# ============================================================================
# Tests: missing arguments
# ============================================================================
test_enhance_accepts_only_the_three_modes() {
    assert_true  'cli_accepts --enhance off'     "--enhance accepts off"
    assert_true  'cli_accepts --enhance stretch' "--enhance accepts stretch"
    assert_true  'cli_accepts --enhance full'    "--enhance accepts full"
    assert_true  'cli_rejects --enhance on'      "--enhance rejects an unknown mode"
    assert_true  'cli_rejects --enhance FULL'    "--enhance is case-sensitive"
    assert_true  'cli_rejects --enhance ""'      "--enhance rejects an empty value"
}

# Each of these must produce a usage error rather than consuming the following
# flag as its value or tripping over an unbound variable under set -u.

test_flags_require_an_argument() {
    local flag
    for flag in -w --width -h --height -p --palette --brightness --contrast \
                --gamma -f --format --background --padding -o --output \
                -d --output-dir --frame-delay --max-frames --loops --char-aspect --enhance; do
        assert_true "cli_rejects_bare $flag" "$flag alone is a usage error"
    done
}

# ============================================================================
# Tests: unknown options and positionals
# ============================================================================

test_unknown_option_is_rejected() {
    assert_true 'cli_rejects --definitely-not-a-flag' "an unknown long option is rejected"
    assert_true 'cli_rejects -Z'                      "an unknown short option is rejected"
}

test_positionals_collect_in_order() {
    local out
    out=$(
        parse_args a.png b.png c.png >/dev/null 2>&1 </dev/null
        printf '%s' "${ARG_IMAGES[*]}"
    )
    assert_equals "a.png b.png c.png" "$out" "positional images collect in order"
}

test_directory_without_images_is_an_error_about_the_directory() {
    # An explicit input that yields no images used to fall through to the
    # stdin path and report "Stdin does not contain valid image data".
    local d msg
    d=$(mktemp -d)
    mkdir -p "$d/empty" "$d/noimg"
    echo "not an image" > "$d/noimg/readme.txt"

    assert_true "cli_rejects_bare '$d/empty'" "an empty directory is rejected"
    msg=$( ( parse_args "$d/empty" </dev/null ) 2>&1 || true )
    assert_contains "$msg" "No images found" "the error names the missing images"
    assert_not_contains "$msg" "Stdin" "the error does not blame stdin"

    msg=$( ( parse_args "$d/noimg" </dev/null ) 2>&1 || true )
    assert_contains "$msg" "No images found" "a directory of non-images is rejected the same way"
    assert_not_contains "$msg" "Stdin" "and does not blame stdin either"
    rm -rf "$d"
}

test_empty_directory_alongside_a_file_still_proceeds() {
    local d out
    d=$(mktemp -d)
    mkdir -p "$d/empty"
    out=$(
        parse_args "$d/empty" "$DUMMY_IMAGE" >/dev/null 2>&1 </dev/null
        printf '%s' "${ARG_IMAGES[*]}"
    )
    assert_equals "$DUMMY_IMAGE" "$out" "the named file is kept when a sibling directory is empty"
    rm -rf "$d"
}

test_double_dash_ends_option_parsing() {
    local out
    out=$(
        parse_args -w 40 -- -cover.png --not-a-flag.png >/dev/null 2>&1 </dev/null
        printf '%s|%s' "$ARG_WIDTH" "${ARG_IMAGES[*]}"
    )
    assert_equals "40|-cover.png --not-a-flag.png" "$out" \
        "arguments after -- are inputs, options before it still apply"
}

test_double_dash_alone_is_not_an_unknown_option() {
    local msg
    msg=$( ( parse_args -- "$DUMMY_IMAGE" </dev/null ) 2>&1 || true )
    assert_not_contains "$msg" "Unknown option" "-- is not reported as an unknown option"
}

test_dash_file_without_double_dash_is_still_an_option() {
    assert_true 'cli_rejects -cover.png' "without --, a leading dash is still parsed as an option"
}

# ============================================================================
# Tests: boolean flags
# ============================================================================

test_truecolor_implies_color() {
    assert_equals "true" "$(cli_value ARG_TRUECOLOR --truecolor)" "--truecolor sets truecolor"
    assert_equals "true" "$(cli_value ARG_COLOR --truecolor)"     "--truecolor implies color"
}

test_no_truecolor_does_not_disable_color() {
    # --no-truecolor turns off truecolor only; plain colour stays as it was.
    assert_equals "false" "$(cli_value ARG_TRUECOLOR --truecolor --no-truecolor)" \
        "--no-truecolor turns truecolor off"
    assert_equals "true" "$(cli_value ARG_COLOR --truecolor --no-truecolor)" \
        "--no-truecolor leaves color enabled"
}

test_simple_boolean_flags() {
    assert_equals "true"  "$(cli_value ARG_INVERT -i)"           "-i sets invert"
    assert_equals "true"  "$(cli_value ARG_QUIET -q)"            "-q sets quiet"
    assert_equals "true"  "$(cli_value ARG_RECURSIVE -r)"        "-r sets recursive"
    assert_equals "true"  "$(cli_value ARG_ANIMATE -a)"          "-a sets animate"
    assert_equals "false" "$(cli_value ARG_ANIMATE -a --no-animate)" "--no-animate overrides -a"
    assert_equals "false" "$(cli_value ARG_PRESERVE_ASPECT --no-aspect)" "--no-aspect clears preserve-aspect"
    assert_equals "true"  "$(cli_value ARG_CONTINUE_ON_ERROR --continue-on-error)" \
        "--continue-on-error is set"
}

# ============================================================================
# Tests: precedence
# ============================================================================

test_cli_overrides_config() {
    # parse_args seeds ARG_* from CONFIG_*, so a CLI flag must win over it.
    local out
    out=$(
        CONFIG_WIDTH=111
        parse_args -w 222 "$DUMMY_IMAGE" >/dev/null 2>&1 </dev/null
        printf '%s' "$ARG_WIDTH"
    )
    assert_equals "222" "$out" "a CLI flag overrides the config value"
}

test_config_used_when_flag_absent() {
    local out
    out=$(
        CONFIG_WIDTH=111
        parse_args "$DUMMY_IMAGE" >/dev/null 2>&1 </dev/null
        printf '%s' "$ARG_WIDTH"
    )
    assert_equals "111" "$out" "the config value is used when no flag is given"
}

test_char_aspect_is_published_to_config_global() {
    # The dimension maths and the exporter both read CONFIG_CHAR_ASPECT, not
    # ARG_CHAR_ASPECT, so parse_args has to publish the resolved value.
    local out
    out=$(
        parse_args --char-aspect 1.67 "$DUMMY_IMAGE" >/dev/null 2>&1 </dev/null
        printf '%s' "$CONFIG_CHAR_ASPECT"
    )
    assert_equals "1.67" "$out" "--char-aspect is published as CONFIG_CHAR_ASPECT"
}

test_enhance_is_published_to_config_global() {
    # image_extract_pixels reads CONFIG_ENHANCE, not ARG_ENHANCE.
    local out
    out=$(
        parse_args --enhance off "$DUMMY_IMAGE" >/dev/null 2>&1 </dev/null
        printf '%s' "$CONFIG_ENHANCE"
    )
    assert_equals "off" "$out" "--enhance is published as CONFIG_ENHANCE"
}

# ============================================================================
# Run
# ============================================================================

run_discovered_tests "CLI Argument Parsing"
