#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/run_all.sh - Master test runner
# ============================================================================
# Runs all test suites and provides aggregated results.
# Shell compatibility: Bash 3.2+, zsh 5.0+
#
# Usage:
#   ./tests/run_all.sh           # Run all tests
#   ./tests/run_all.sh --unit    # Run only unit tests
#   ./tests/run_all.sh --integration  # Run only integration tests
#   ./tests/run_all.sh --verbose # Show detailed output
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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
TOTAL_SUITES=0
SUITES_PASSED=0
SUITES_FAILED=0
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# Options
RUN_UNIT=true
RUN_INTEGRATION=true
VERBOSE=false

# ============================================================================
# Parse Arguments
# ============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --unit|-u)
            RUN_UNIT=true
            RUN_INTEGRATION=false
            shift
            ;;
        --integration|-i)
            RUN_UNIT=false
            RUN_INTEGRATION=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --unit, -u         Run only unit tests"
            echo "  --integration, -i  Run only integration tests"
            echo "  --verbose, -v      Show detailed test output"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# Test Suite Definitions
# ============================================================================

# Unit test files (no ImageMagick required for core tests)
UNIT_TESTS=(
    "test_utils.sh"
    "test_palettes.sh"
    "test_image.sh"
    "test_export.sh"
)

# Integration test files (require ImageMagick)
INTEGRATION_TESTS=(
    "test_integration.sh"
)

# ============================================================================
# Run Test Suite
# ============================================================================

run_suite() {
    local suite_file="$1"
    local suite_path="$SCRIPT_DIR/$suite_file"
    
    if [[ ! -f "$suite_path" ]]; then
        echo -e "${YELLOW}⚠ Suite not found: $suite_file${NC}"
        return 0
    fi
    
    # Make executable
    chmod +x "$suite_path"
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Running: $suite_file${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local start_time
    start_time=$(date +%s)
    
    local result=0
    if [[ "$VERBOSE" == "true" ]]; then
        "$suite_path" || result=$?
    else
        # Capture output and show only summary
        local output
        output=$("$suite_path" 2>&1) || result=$?
        
        # Extract and display test results (lines starting with spaces that have PASS/FAIL/SKIP)
        echo "$output" | grep -E "^  .*(PASS|FAIL|SKIP)" || true
    fi
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Parse results from output (look for Results: line)
    local suite_output
    suite_output=$("$suite_path" 2>&1) || true
    
    # Strip ANSI codes for parsing
    local clean_output
    clean_output=$(echo "$suite_output" | sed 's/\x1b\[[0-9;]*m//g')
    
    # Extract passed/total from "Results: X/Y passed"
    # Use grep/sed for portability instead of BASH_REMATCH (not available in zsh)
    local results_line
    results_line=$(echo "$clean_output" | grep -o 'Results: [0-9]*/[0-9]* passed' | head -1) || true
    if [[ -n "$results_line" ]]; then
        local passed total
        passed=$(echo "$results_line" | sed 's/Results: \([0-9]*\)\/[0-9]* passed/\1/')
        total=$(echo "$results_line" | sed 's/Results: [0-9]*\/\([0-9]*\) passed/\1/')
        TOTAL_TESTS=$((TOTAL_TESTS + total))
        TOTAL_PASSED=$((TOTAL_PASSED + passed))
        TOTAL_FAILED=$((TOTAL_FAILED + (total - passed)))
    fi
    
    # Extract skipped count
    local skipped_line
    skipped_line=$(echo "$clean_output" | grep -o '[0-9]* skipped' | head -1) || true
    if [[ -n "$skipped_line" ]]; then
        local skipped
        skipped=$(echo "$skipped_line" | sed 's/ skipped//')
        TOTAL_SKIPPED=$((TOTAL_SKIPPED + skipped))
    fi
    
    if [[ $result -eq 0 ]]; then
        SUITES_PASSED=$((SUITES_PASSED + 1))
        echo -e "${GREEN}✔ Suite passed${NC} (${duration}s)"
    else
        SUITES_FAILED=$((SUITES_FAILED + 1))
        echo -e "${RED}✖ Suite failed${NC} (${duration}s)"
    fi
    
    return $result
}

# ============================================================================
# Main
# ============================================================================

echo ""
echo -e "${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║              gummyworm Test Suite Runner                       ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Project: ${CYAN}$PROJECT_ROOT${NC}"
echo -e "Date:    ${CYAN}$(date)${NC}"

# Check for ImageMagick
if command -v convert &>/dev/null; then
    echo -e "ImageMagick: ${GREEN}Available${NC}"
else
    echo -e "ImageMagick: ${YELLOW}Not found (some tests will be skipped)${NC}"
fi

# Run unit tests
if [[ "$RUN_UNIT" == "true" ]]; then
    echo ""
    echo -e "${BOLD}═══ Unit Tests ═══${NC}"
    
    for suite in "${UNIT_TESTS[@]}"; do
        run_suite "$suite" || true
    done
fi

# Run integration tests
if [[ "$RUN_INTEGRATION" == "true" ]]; then
    echo ""
    echo -e "${BOLD}═══ Integration Tests ═══${NC}"
    
    for suite in "${INTEGRATION_TESTS[@]}"; do
        run_suite "$suite" || true
    done
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                      Test Summary                              ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Test Suites:  ${SUITES_PASSED}/${TOTAL_SUITES} passed"
echo -e "  Total Tests:  ${TOTAL_PASSED}/${TOTAL_TESTS} passed"

if [[ $TOTAL_SKIPPED -gt 0 ]]; then
    echo -e "  Skipped:      ${YELLOW}${TOTAL_SKIPPED}${NC}"
fi

if [[ $TOTAL_FAILED -gt 0 ]]; then
    echo -e "  Failed:       ${RED}${TOTAL_FAILED}${NC}"
fi

echo ""

if [[ $SUITES_FAILED -gt 0 ]]; then
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    TESTS FAILED                                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 1
else
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    ALL TESTS PASSED                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 0
fi
