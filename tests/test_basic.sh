#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_basic.sh - Basic functionality tests
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GUMMYWORM="$PROJECT_ROOT/gummyworm"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
run_test() {
    local name="$1"
    local cmd="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "Testing: $name... "
    
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Create test image
TEST_IMG=$(mktemp --suffix=.png)
trap "rm -f '$TEST_IMG'" EXIT

convert -size 50x50 gradient:black-white "$TEST_IMG"

echo "================================"
echo "Gummyworm Test Suite"
echo "================================"
echo ""

# Basic tests
run_test "--help works" "$GUMMYWORM --help"
run_test "--version works" "$GUMMYWORM --version"
run_test "--list-palettes works" "$GUMMYWORM --list-palettes"

# Conversion tests
run_test "Basic conversion" "$GUMMYWORM -q -w 20 '$TEST_IMG'"
run_test "With width option" "$GUMMYWORM -q -w 40 '$TEST_IMG'"
run_test "With invert" "$GUMMYWORM -q -w 20 -i '$TEST_IMG'"
run_test "With color" "$GUMMYWORM -q -w 20 -c '$TEST_IMG'"

# Palette tests
run_test "Standard palette" "$GUMMYWORM -q -w 20 -p standard '$TEST_IMG'"
run_test "Blocks palette" "$GUMMYWORM -q -w 20 -p blocks '$TEST_IMG'"
run_test "Simple palette" "$GUMMYWORM -q -w 20 -p simple '$TEST_IMG'"
run_test "Custom palette" "$GUMMYWORM -q -w 20 -p ' .oO@' '$TEST_IMG'"

# File output test
OUTPUT_FILE=$(mktemp)
trap "rm -f '$TEST_IMG' '$OUTPUT_FILE'" EXIT
run_test "File output" "$GUMMYWORM -q -w 20 -o '$OUTPUT_FILE' '$TEST_IMG' && [[ -s '$OUTPUT_FILE' ]]"

echo ""
echo "================================"
echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}$TESTS_FAILED tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
fi
