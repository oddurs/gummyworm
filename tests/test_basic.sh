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
TEST_IMG=$(mktemp -t gummyworm_test).png
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

# ================================
# Batch Processing Tests
# ================================
echo ""
echo "--- Batch Processing Tests ---"

# Create multiple test images for batch processing
TEST_IMG2=$(mktemp -t gummyworm_test2).png
TEST_IMG3=$(mktemp -t gummyworm_test3).png
trap "rm -f '$TEST_IMG' '$TEST_IMG2' '$TEST_IMG3' '$OUTPUT_FILE'" EXIT

convert -size 30x30 gradient:red-blue "$TEST_IMG2"
convert -size 40x40 gradient:green-yellow "$TEST_IMG3"

run_test "Batch: multiple files" "$GUMMYWORM -q -w 20 '$TEST_IMG' '$TEST_IMG2'"
run_test "Batch: three files" "$GUMMYWORM -q -w 20 '$TEST_IMG' '$TEST_IMG2' '$TEST_IMG3'"
run_test "Batch: output to file" "$GUMMYWORM -q -w 20 -o '$OUTPUT_FILE' '$TEST_IMG' '$TEST_IMG2' && [[ -s '$OUTPUT_FILE' ]]"

# Test batch output to directory
BATCH_OUTPUT_DIR=$(mktemp -d)
trap "rm -f '$TEST_IMG' '$TEST_IMG2' '$TEST_IMG3' '$OUTPUT_FILE'; rm -rf '$BATCH_OUTPUT_DIR'" EXIT

run_test "Batch: output to directory" "$GUMMYWORM -q -w 20 -d '$BATCH_OUTPUT_DIR' '$TEST_IMG' '$TEST_IMG2' && [[ -d '$BATCH_OUTPUT_DIR' ]] && [[ \$(ls -1 '$BATCH_OUTPUT_DIR' | wc -l) -ge 2 ]]"

# Test continue-on-error with batch
INVALID_FILE="/tmp/nonexistent_image_$$.png"
run_test "Batch: continue-on-error" "$GUMMYWORM -q -w 20 --continue-on-error '$TEST_IMG' '$INVALID_FILE' '$TEST_IMG2' 2>/dev/null"

# ================================
# Stdin (Pipe) Tests
# ================================
echo ""
echo "--- Stdin/Pipe Tests ---"

run_test "Stdin: basic pipe" "cat '$TEST_IMG' | $GUMMYWORM -q -w 20"
run_test "Stdin: pipe with color" "cat '$TEST_IMG' | $GUMMYWORM -q -w 20 -c"
run_test "Stdin: pipe with invert" "cat '$TEST_IMG' | $GUMMYWORM -q -w 20 -i"
run_test "Stdin: pipe with palette" "cat '$TEST_IMG' | $GUMMYWORM -q -w 20 -p blocks"
run_test "Stdin: pipe to file output" "cat '$TEST_IMG' | $GUMMYWORM -q -w 20 -o '$OUTPUT_FILE' && [[ -s '$OUTPUT_FILE' ]]"

# Test that invalid stdin data is handled properly
run_test "Stdin: reject invalid data" "! echo 'not an image' | $GUMMYWORM -q -w 20 2>/dev/null"

# ================================
# URL Input Tests
# ================================
echo ""
echo "--- URL Input Tests ---"

# Use a reliable public test image (1x1 pixel PNG)
TEST_URL="https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png"
TEST_URL_INVALID="https://example.com/nonexistent_image_12345.png"

run_test "URL: basic URL input" "$GUMMYWORM -q -w 20 '$TEST_URL'"
run_test "URL: with color option" "$GUMMYWORM -q -w 20 -c '$TEST_URL'"
run_test "URL: with invert option" "$GUMMYWORM -q -w 20 -i '$TEST_URL'"
run_test "URL: with palette option" "$GUMMYWORM -q -w 20 -p blocks '$TEST_URL'"
run_test "URL: output to file" "$GUMMYWORM -q -w 20 -o '$OUTPUT_FILE' '$TEST_URL' && [[ -s '$OUTPUT_FILE' ]]"
run_test "URL: reject invalid URL" "! $GUMMYWORM -q -w 20 '$TEST_URL_INVALID' 2>/dev/null"

# Test URL in batch mode with local files
run_test "URL: mixed with local files" "$GUMMYWORM -q -w 20 '$TEST_IMG' '$TEST_URL' --continue-on-error"

echo ""
echo "================================"
echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}$TESTS_FAILED tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
fi
