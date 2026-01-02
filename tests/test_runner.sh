#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_runner.sh - Shared test utilities and assertions
# ============================================================================
# This file provides a comprehensive testing framework for gummyworm.
# Source this file in your test scripts to get access to assertions,
# setup/teardown helpers, and test execution utilities.
#
# Usage:
#   source "$(dirname "$0")/test_runner.sh"
#   
#   test_my_function() {
#       assert_equals "expected" "actual" "Description"
#   }
#   
#   run_test_suite
# ============================================================================

set -euo pipefail

# ============================================================================
# Test Runner Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GUMMYWORM="$PROJECT_ROOT/gummyworm"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export DIM='\033[2m'
export BOLD='\033[1m'
export NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Current test context
CURRENT_TEST_NAME=""
CURRENT_TEST_FILE=""

# Temp files for cleanup
declare -a TEMP_FILES=()
declare -a TEMP_DIRS=()

# Track registered tests
declare -a REGISTERED_TESTS=()

# ============================================================================
# Source Library Functions (for unit tests)
# ============================================================================

# Load gummyworm libraries for unit testing
load_gummyworm_libs() {
    # Source in dependency order
    source "$PROJECT_ROOT/lib/config.sh"
    source "$PROJECT_ROOT/lib/utils.sh"
    source "$PROJECT_ROOT/lib/palettes.sh"
    source "$PROJECT_ROOT/lib/image.sh"
    source "$PROJECT_ROOT/lib/converter.sh"
    source "$PROJECT_ROOT/lib/export.sh"
    source "$PROJECT_ROOT/lib/cli.sh"
}

# ============================================================================
# Temp File Management
# ============================================================================

# Create a temp file and register for cleanup
# Usage: make_temp_file [suffix]
make_temp_file() {
    local suffix="${1:-.tmp}"
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/gummyworm_test_XXXXXX${suffix}")
    TEMP_FILES+=("$tmpfile")
    echo "$tmpfile"
}

# Create a temp directory and register for cleanup
# Usage: make_temp_dir
make_temp_dir() {
    local tmpdir
    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/gummyworm_test_XXXXXX")
    TEMP_DIRS+=("$tmpdir")
    echo "$tmpdir"
}

# Clean up all temp files and directories
cleanup_temp() {
    for f in "${TEMP_FILES[@]:-}"; do
        [[ -f "$f" ]] && rm -f "$f"
    done
    for d in "${TEMP_DIRS[@]:-}"; do
        [[ -d "$d" ]] && rm -rf "$d"
    done
    TEMP_FILES=()
    TEMP_DIRS=()
}

# ============================================================================
# Test Image Helpers
# ============================================================================

# Check if ImageMagick is available
has_imagemagick() {
    command -v convert &>/dev/null && command -v identify &>/dev/null
}

# Create a test image (requires ImageMagick)
# Usage: create_test_image <filepath> [width] [height] [gradient]
create_test_image() {
    local filepath="$1"
    local width="${2:-50}"
    local height="${3:-50}"
    local gradient="${4:-gradient:black-white}"
    
    if ! has_imagemagick; then
        echo "ImageMagick required to create test images" >&2
        return 1
    fi
    
    convert -size "${width}x${height}" "$gradient" "$filepath"
}

# Get fixture image path (creates if doesn't exist)
# Usage: get_fixture_image [name]
get_fixture_image() {
    local name="${1:-test_image.png}"
    local path="$FIXTURES_DIR/$name"
    
    if [[ ! -f "$path" ]]; then
        mkdir -p "$FIXTURES_DIR"
        create_test_image "$path" 50 50 "gradient:black-white"
    fi
    
    echo "$path"
}

# ============================================================================
# Mock Functions
# ============================================================================

# Mock the 'convert' command for tests without ImageMagick
# Usage: mock_convert
mock_convert() {
    convert() {
        # For -size NxN gradient: output, just create an empty file
        local output="${!#}"  # Last argument
        touch "$output" 2>/dev/null || true
    }
    export -f convert
}

# Mock the 'identify' command
# Usage: mock_identify [width] [height] [format]
mock_identify() {
    local mock_width="${1:-100}"
    local mock_height="${2:-100}"
    local mock_format="${3:-PNG}"
    
    identify() {
        local format_arg=""
        for arg in "$@"; do
            if [[ "$arg" == "-format" ]]; then
                format_arg="next"
            elif [[ "$format_arg" == "next" ]]; then
                case "$arg" in
                    "%w %h") echo "$mock_width $mock_height" ;;
                    "%w")    echo "$mock_width" ;;
                    "%h")    echo "$mock_height" ;;
                    "%m")    echo "$mock_format" ;;
                    *)       echo "$mock_width $mock_height" ;;
                esac
                return 0
            fi
        done
        return 0
    }
    export -f identify
}

# Restore original commands after mocking
restore_mocks() {
    unset -f convert 2>/dev/null || true
    unset -f identify 2>/dev/null || true
}

# ============================================================================
# Assertions
# ============================================================================

# Assert that two values are equal
# Usage: assert_equals <expected> <actual> [message]
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      Expected: ${CYAN}$expected${NC}" >&2
        echo -e "      Actual:   ${CYAN}$actual${NC}" >&2
        return 1
    fi
}

# Assert that two values are not equal
# Usage: assert_not_equals <unexpected> <actual> [message]
assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    
    if [[ "$unexpected" != "$actual" ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      Unexpected: ${CYAN}$unexpected${NC}" >&2
        echo -e "      Actual:     ${CYAN}$actual${NC}" >&2
        return 1
    fi
}

# Assert that a condition is true (exit code 0)
# Usage: assert_true <command> [message]
assert_true() {
    local cmd="$1"
    local message="${2:-Condition should be true}"
    
    if eval "$cmd" >/dev/null 2>&1; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      Command: ${DIM}$cmd${NC}" >&2
        return 1
    fi
}

# Assert that a condition is false (exit code non-zero)
# Usage: assert_false <command> [message]
assert_false() {
    local cmd="$1"
    local message="${2:-Condition should be false}"
    
    if ! eval "$cmd" >/dev/null 2>&1; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      Command should have failed: ${DIM}$cmd${NC}" >&2
        return 1
    fi
}

# Assert that a string contains a substring
# Usage: assert_contains <haystack> <needle> [message]
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      String:    ${DIM}${haystack:0:100}...${NC}" >&2
        echo -e "      Expected:  ${CYAN}$needle${NC}" >&2
        return 1
    fi
}

# Assert that a string does NOT contain a substring
# Usage: assert_not_contains <haystack> <needle> [message]
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not contain substring}"
    
    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      String contains:  ${CYAN}$needle${NC}" >&2
        return 1
    fi
}

# Assert that a string matches a regex
# Usage: assert_matches <string> <pattern> [message]
assert_matches() {
    local string="$1"
    local pattern="$2"
    local message="${3:-String should match pattern}"
    
    if [[ "$string" =~ $pattern ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      String:  ${DIM}${string:0:100}${NC}" >&2
        echo -e "      Pattern: ${CYAN}$pattern${NC}" >&2
        return 1
    fi
}

# Assert that a file exists
# Usage: assert_file_exists <filepath> [message]
assert_file_exists() {
    local filepath="$1"
    local message="${2:-File should exist: $filepath}"
    
    if [[ -f "$filepath" ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        return 1
    fi
}

# Assert that a file does not exist
# Usage: assert_file_not_exists <filepath> [message]
assert_file_not_exists() {
    local filepath="$1"
    local message="${2:-File should not exist: $filepath}"
    
    if [[ ! -f "$filepath" ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        return 1
    fi
}

# Assert that a directory exists
# Usage: assert_dir_exists <dirpath> [message]
assert_dir_exists() {
    local dirpath="$1"
    local message="${2:-Directory should exist: $dirpath}"
    
    if [[ -d "$dirpath" ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        return 1
    fi
}

# Assert that a file is not empty
# Usage: assert_file_not_empty <filepath> [message]
assert_file_not_empty() {
    local filepath="$1"
    local message="${2:-File should not be empty: $filepath}"
    
    if [[ -s "$filepath" ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        return 1
    fi
}

# Assert that a command exits with a specific code
# Usage: assert_exit_code <expected_code> <command> [message]
assert_exit_code() {
    local expected="$1"
    local cmd="$2"
    local message="${3:-Command should exit with code $expected}"
    
    local actual
    set +e
    eval "$cmd" >/dev/null 2>&1
    actual=$?
    set -e
    
    if [[ "$actual" -eq "$expected" ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      Expected exit code: ${CYAN}$expected${NC}" >&2
        echo -e "      Actual exit code:   ${CYAN}$actual${NC}" >&2
        return 1
    fi
}

# Assert that output matches expected value
# Usage: assert_output <expected> <command> [message]
assert_output() {
    local expected="$1"
    local cmd="$2"
    local message="${3:-Output should match expected}"
    
    local actual
    actual=$(eval "$cmd" 2>&1) || true
    
    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      Expected: ${CYAN}$expected${NC}" >&2
        echo -e "      Actual:   ${CYAN}$actual${NC}" >&2
        return 1
    fi
}

# Assert that output contains expected substring
# Usage: assert_output_contains <expected> <command> [message]
assert_output_contains() {
    local expected="$1"
    local cmd="$2"
    local message="${3:-Output should contain expected string}"
    
    local actual
    actual=$(eval "$cmd" 2>&1) || true
    
    if [[ "$actual" == *"$expected"* ]]; then
        return 0
    else
        echo -e "    ${RED}✗ ASSERTION FAILED:${NC} $message" >&2
        echo -e "      Expected to contain: ${CYAN}$expected${NC}" >&2
        echo -e "      Actual output:       ${DIM}${actual:0:200}${NC}" >&2
        return 1
    fi
}

# ============================================================================
# Test Execution
# ============================================================================

# Register a test function
# Usage: register_test <function_name>
register_test() {
    REGISTERED_TESTS+=("$1")
}

# Run a single test function with proper error handling
# Usage: run_test <test_name> [test_function]
run_test() {
    local name="$1"
    local func="${2:-}"
    
    # If no function provided, assume it's a command to run
    if [[ -z "$func" ]]; then
        # Legacy mode: name is description, run as command
        local cmd="$name"
        name="$2"
        
        TESTS_RUN=$((TESTS_RUN + 1))
        echo -n "  Testing: $name... "
        
        if eval "$cmd" >/dev/null 2>&1; then
            echo -e "${GREEN}PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}FAIL${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
    
    TESTS_RUN=$((TESTS_RUN + 1))
    CURRENT_TEST_NAME="$name"
    
    echo -n "  $name... "
    
    # Run the test function, capturing any failures
    local result=0
    set +e
    (
        set -e
        "$func"
    )
    result=$?
    set -e
    
    if [[ $result -eq 0 ]]; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    CURRENT_TEST_NAME=""
    return $result
}

# Skip a test with a reason
# Usage: skip_test <reason>
skip_test() {
    local reason="$1"
    echo -e "${YELLOW}SKIP${NC} ($reason)"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    return 0
}

# Run all registered tests
# Usage: run_test_suite [suite_name]
run_test_suite() {
    local suite_name="${1:-Test Suite}"
    
    echo ""
    echo -e "${BOLD}================================${NC}"
    echo -e "${BOLD}$suite_name${NC}"
    echo -e "${BOLD}================================${NC}"
    echo ""
    
    # Run setup if defined
    if declare -f setup &>/dev/null; then
        setup
    fi
    
    # Run all registered tests
    for test_func in "${REGISTERED_TESTS[@]}"; do
        # Convert function name to readable name (test_foo_bar -> "foo bar")
        local readable_name="${test_func#test_}"
        readable_name="${readable_name//_/ }"
        
        run_test "$readable_name" "$test_func" || true
    done
    
    # Run teardown if defined
    if declare -f teardown &>/dev/null; then
        teardown
    fi
    
    # Cleanup temp files
    cleanup_temp
    
    # Print summary
    print_summary
}

# Print test summary
print_summary() {
    echo ""
    echo -e "${BOLD}================================${NC}"
    echo -e "Results: ${GREEN}$TESTS_PASSED${NC}/$TESTS_RUN passed"
    
    if [[ $TESTS_SKIPPED -gt 0 ]]; then
        echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
    fi
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}$TESTS_FAILED tests failed${NC}"
        return 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

# ============================================================================
# Test Discovery
# ============================================================================

# Discover and run all test_* functions in current script
# Usage: run_discovered_tests [suite_name]
run_discovered_tests() {
    local suite_name="${1:-Discovered Tests}"
    
    # Find all functions starting with test_
    local test_funcs
    test_funcs=$(declare -F | awk '{print $3}' | grep '^test_' || true)
    
    # Register discovered tests
    for func in $test_funcs; do
        register_test "$func"
    done
    
    # Run the suite
    run_test_suite "$suite_name"
}

# ============================================================================
# Cleanup on Exit
# ============================================================================

trap cleanup_temp EXIT
