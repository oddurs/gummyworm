# Testing Guide

This guide covers the gummyworm testing infrastructure, including how to run tests, write new tests, and understand the test architecture.

## Quick Start

```bash
# Run all tests
./tests/run_all.sh

# Run only unit tests (fast, no ImageMagick required)
./tests/run_all.sh --unit

# Run only integration tests
./tests/run_all.sh --integration

# Run with verbose output
./tests/run_all.sh --verbose

# Run a single test file
./tests/test_utils.sh
```

## Test Architecture

```
tests/
├── test_runner.sh      # Shared test framework & assertions
├── run_all.sh          # Master test runner
├── test_utils.sh       # Unit tests for lib/utils.sh
├── test_palettes.sh    # Unit tests for lib/palettes.sh
├── test_image.sh       # Unit tests for lib/image.sh
├── test_export.sh      # Unit tests for lib/export.sh & lib/converter.sh
├── test_integration.sh # End-to-end CLI tests
├── test_basic.sh       # Legacy integration tests (deprecated)
└── fixtures/           # Test data
    ├── test.palette    # Sample custom palette
    ├── README.md       # Fixtures documentation
    └── expected/       # Expected outputs for regression tests
```

### Test Categories

| Category | Files | ImageMagick | Purpose |
|----------|-------|-------------|---------|
| **Unit** | `test_*.sh` (except integration) | Optional | Test individual functions in isolation |
| **Integration** | `test_integration.sh` | Required | Test complete CLI workflows |

## Test Runner Framework

All test files source `test_runner.sh` which provides:

### Assertions

```bash
# Equality checks
assert_equals "expected" "actual" "message"
assert_not_equals "unexpected" "actual" "message"

# Boolean conditions
assert_true 'command_to_test' "message"
assert_false 'command_that_should_fail' "message"

# String checks
assert_contains "$haystack" "needle" "message"
assert_not_contains "$haystack" "needle" "message"
assert_matches "$string" "regex_pattern" "message"

# File checks
assert_file_exists "/path/to/file" "message"
assert_file_not_exists "/path/to/file" "message"
assert_dir_exists "/path/to/dir" "message"
assert_file_not_empty "/path/to/file" "message"

# Exit codes
assert_exit_code 0 "command_to_run" "message"
assert_exit_code 1 "command_that_should_fail" "message"

# Output checks
assert_output "expected output" "command" "message"
assert_output_contains "substring" "command" "message"
```

### Temp File Management

```bash
# Create temp files (automatically cleaned up)
local tmpfile=$(make_temp_file ".txt")
local tmpdir=$(make_temp_dir)

# Files are cleaned up automatically after tests
```

### Mock Functions

```bash
# Mock ImageMagick commands for unit tests
mock_identify 640 480 "PNG"  # Returns these dimensions
mock_convert                  # Creates empty files

# Restore after testing
restore_mocks
```

### Test Discovery

Tests are automatically discovered by function name prefix:

```bash
test_my_feature_works() {
    # Test code here
    assert_equals "expected" "actual"
}

# Discovered and run automatically
run_discovered_tests "My Test Suite"
```

## Writing Tests

### Unit Test Example

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

# Load gummyworm libraries
load_gummyworm_libs

# Test functions must start with test_
test_my_function_basic() {
    local result
    result=$(my_function "input")
    assert_equals "expected" "$result" "basic case works"
}

test_my_function_edge_case() {
    assert_false 'my_function ""' "empty input handled"
}

# Run all test_* functions
run_discovered_tests "my_function Unit Tests"
```

### Integration Test Example

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

# Setup creates test images
setup() {
    if ! has_imagemagick; then
        echo "Warning: ImageMagick not available"
        return
    fi
    
    TEST_IMG=$(make_temp_file ".png")
    create_test_image "$TEST_IMG" 50 50
}

# Helper to skip when ImageMagick unavailable
require_imagemagick() {
    if ! has_imagemagick; then
        skip_test "ImageMagick not available"
        return 1
    fi
    return 0
}

test_cli_basic_conversion() {
    require_imagemagick || return 0
    assert_exit_code 0 "$GUMMYWORM -q -w 20 '$TEST_IMG'"
}

run_discovered_tests "CLI Integration Tests"
```

### Testing Best Practices

1. **Name tests descriptively**: `test_is_positive_int_rejects_negative`
2. **Test one thing per function**: Keep tests focused
3. **Use meaningful assertion messages**: Help debug failures
4. **Clean up resources**: Use `make_temp_file` for automatic cleanup
5. **Handle missing dependencies**: Use `skip_test` gracefully
6. **Mock external commands**: Use mocks for unit test isolation

## Running Specific Tests

```bash
# Run individual test file
./tests/test_utils.sh

# Run with bash debugging
bash -x ./tests/test_utils.sh

# Run specific test function (not directly supported, but you can add)
TEST_FILTER="is_positive_int" ./tests/test_utils.sh
```

## CI Integration

The test suite is designed for CI environments:

```yaml
# GitHub Actions example
- name: Run unit tests
  run: ./tests/run_all.sh --unit

- name: Run integration tests
  run: |
    brew install imagemagick  # or apt-get
    ./tests/run_all.sh --integration
```

### Exit Codes

- `0`: All tests passed
- `1`: One or more tests failed

## Test Coverage

### Current Coverage by Module

| Module | Unit Tests | Integration Tests | Coverage |
|--------|------------|-------------------|----------|
| `lib/utils.sh` | ✅ | - | High |
| `lib/palettes.sh` | ✅ | ✅ | High |
| `lib/image.sh` | ✅ | ✅ | Medium |
| `lib/converter.sh` | ✅ | ✅ | Medium |
| `lib/export.sh` | ✅ | ✅ | High |
| `lib/cli.sh` | - | ✅ | Medium |
| `bin/gummyworm` | - | ✅ | High |

### Adding Coverage

To improve coverage:

1. Identify untested functions in `lib/` files
2. Add unit tests for pure functions
3. Add integration tests for CLI behaviors
4. Add regression tests with fixtures for output formats

## Fixtures

Test fixtures are stored in `tests/fixtures/`:

```
fixtures/
├── test.palette        # Custom palette for testing
├── expected/           # Expected outputs for regression
│   └── .gitkeep
└── README.md
```

### Adding Expected Outputs

```bash
# Generate expected output
./gummyworm -w 20 -f html tests/fixtures/test_image.png > tests/fixtures/expected/output.html

# Use in regression test
test_html_output_unchanged() {
    local output=$(make_temp_file ".html")
    "$GUMMYWORM" -w 20 -f html -o "$output" "$FIXTURE_IMG"
    
    # Compare with expected
    diff -q "$output" "$FIXTURES_DIR/expected/output.html"
}
```

## Troubleshooting

### Tests fail with "command not found"

Ensure scripts are executable:
```bash
chmod +x tests/*.sh
```

### ImageMagick tests skipped

Install ImageMagick:
```bash
# macOS
brew install imagemagick

# Ubuntu/Debian
sudo apt-get install imagemagick

# Fedora
sudo dnf install ImageMagick
```

### Python-dependent tests fail

Some unicode tests require Python 3:
```bash
python3 --version  # Verify installation
```

### Test hangs

Check for infinite loops in tested functions, or use timeout:
```bash
timeout 60 ./tests/test_utils.sh
```
