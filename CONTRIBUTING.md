# Contributing to gummyworm

Thank you for your interest in contributing to gummyworm! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be kind, respectful, and constructive. We're all here to make a fun tool better.

## Ways to Contribute

### Reporting Bugs

1. **Check existing issues** to avoid duplicates
2. **Use the bug report template** (if available)
3. **Include:**
   - gummyworm version (`gummyworm --version`)
   - OS and version (`uname -a`)
   - Bash version (`bash --version`)
   - ImageMagick version (`convert --version`)
   - Exact command that failed
   - Full error output
   - Sample image (if relevant and shareable)

### Suggesting Features

1. **Check existing issues/discussions** for similar ideas
2. **Describe the use case** — what problem does it solve?
3. **Propose a solution** — how should it work?

### Submitting Code

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Test your changes
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/gummyworm.git
cd gummyworm

# Make scripts executable
chmod +x gummyworm bin/gummyworm tests/test_basic.sh

# Verify it works
./gummyworm --version
./tests/test_basic.sh
```

### Prerequisites

- Bash 4.0+
- ImageMagick
- ShellCheck (for linting)

```bash
# Install ShellCheck
brew install shellcheck      # macOS
sudo apt install shellcheck  # Ubuntu/Debian
```

## Code Style

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use `[[ ]]` for conditionals (not `[ ]`)
- Quote variables: `"$var"` not `$var`
- Use lowercase for local variables, UPPERCASE for constants/exports
- Use `local` for function-scoped variables
- Indent with 4 spaces (not tabs)

### Function Documentation

```bash
# Description of what the function does
# Arguments:
#   $1 - description of first argument
#   $2 - description of second argument (optional)
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Writes result to stdout
function_name() {
    local arg1="$1"
    local arg2="${2:-default}"
    # ...
}
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Functions | `snake_case` | `convert_to_ascii` |
| Local variables | `snake_case` | `local output_width` |
| Global constants | `UPPER_SNAKE` | `DEFAULT_WIDTH` |
| Module prefix | `module_` | `palette_get`, `image_validate` |

## Testing

gummyworm has a modular test suite with unit tests and integration tests.
See [docs/testing.md](docs/testing.md) for the complete testing guide.

### Running Tests

```bash
# Run all tests
./tests/run_all.sh

# Run only unit tests (fast, no ImageMagick required)
./tests/run_all.sh --unit

# Run only integration tests  
./tests/run_all.sh --integration

# Run a single test file
./tests/test_utils.sh

# Run with verbose output
./tests/run_all.sh --verbose
```

### Test Structure

```
tests/
├── test_runner.sh      # Shared test framework & assertions
├── run_all.sh          # Master test runner
├── test_utils.sh       # Unit tests for lib/utils.sh
├── test_palettes.sh    # Unit tests for lib/palettes.sh
├── test_image.sh       # Unit tests for lib/image.sh
├── test_export.sh      # Unit tests for lib/export.sh
├── test_integration.sh # End-to-end CLI tests
└── fixtures/           # Test data and expected outputs
```

### Writing Tests

Create a new test file or add to an existing one:

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_runner.sh"
load_gummyworm_libs

# Test functions must start with test_
test_my_feature_works() {
    local result
    result=$(my_function "input")
    assert_equals "expected" "$result" "my_function returns expected value"
}

test_my_feature_handles_edge_case() {
    assert_false 'my_function ""' "empty input returns false"
}

# Run all test_* functions automatically
run_discovered_tests "My Feature Tests"
```

### Available Assertions

```bash
assert_equals "expected" "actual" "message"
assert_not_equals "unexpected" "actual" "message"
assert_true 'command' "message"
assert_false 'command' "message"
assert_contains "$string" "substring" "message"
assert_file_exists "/path/to/file" "message"
assert_exit_code 0 "command" "message"
```

### Test Coverage

When adding features, include tests for:
- Normal operation (happy path)
- Edge cases (empty input, large input, etc.)
- Error conditions (invalid input, missing files, etc.)
- Both unit tests (isolated function testing) and integration tests (CLI behavior)

## Linting

Run ShellCheck before submitting:

```bash
# Check all shell files
shellcheck bin/gummyworm lib/*.sh tests/*.sh

# Fix common issues automatically (if available)
shellcheck -f diff bin/gummyworm | patch -p1
```

Common ShellCheck issues to watch for:
- SC2086: Quote to prevent globbing and word splitting
- SC2155: Declare and assign separately to avoid masking return values
- SC2034: Variable appears unused (may be used dynamically)

## Project Structure

```
gummyworm/
├── bin/gummyworm      # Main entry point
├── lib/
│   ├── config.sh      # Configuration, constants
│   ├── utils.sh       # Logging, utilities
│   ├── palettes.sh    # Palette management
│   ├── image.sh       # Image processing
│   ├── converter.sh   # ASCII conversion
│   ├── cli.sh         # CLI parsing
│   └── export.sh      # Format export
├── palettes/          # Custom palette files
├── tests/             # Test suite
├── docs/              # Documentation
└── Formula/           # Homebrew formula
```

## Pull Request Guidelines

### Before Submitting

- [ ] Code follows the style guide
- [ ] ShellCheck passes with no errors
- [ ] Tests pass (`./tests/test_basic.sh`)
- [ ] New features include tests
- [ ] Documentation is updated if needed
- [ ] Commit messages are clear and descriptive

### PR Description

Include:
- **What:** Brief description of changes
- **Why:** Motivation or issue being fixed
- **How:** High-level approach (if complex)
- **Testing:** How you tested the changes

### Commit Messages

Use clear, descriptive commit messages:

```
feat: add webp format support to image module

- Add webp to supported formats list
- Update image_validate to handle webp files
- Add test case for webp conversion
```

Format:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `test:` Adding tests
- `refactor:` Code change that neither fixes a bug nor adds a feature
- `style:` Formatting, missing semicolons, etc.
- `chore:` Maintenance tasks

## Adding New Features

### Adding a Palette

1. **Built-in:** Add to `BUILTIN_PALETTES` in `lib/palettes.sh`
2. **Custom file:** Create `palettes/name.palette`
3. **Update docs:** Add to palette table in `docs/palettes.md`

### Adding a CLI Option

1. Add parsing in `lib/cli.sh` → `parse_args()`
2. Add default in `lib/config.sh`
3. Update help text in `lib/cli.sh` → `show_help()`
4. Document in `docs/cli-reference.md`

### Adding an Export Format

1. Add export function in `lib/export.sh`
2. Update `export_content()` dispatcher
3. Update `export_detect_format()` and `export_get_extension()`
4. Document in `docs/export-formats.md`

## Release Process

(For maintainers)

1. Update version in `lib/config.sh`
2. Update CHANGELOG.md
3. Create git tag: `git tag v2.x.x`
4. Push tag: `git push origin v2.x.x`
5. Create GitHub Release
6. Update Homebrew formula

See [docs/homebrew.md](docs/homebrew.md) for detailed release instructions.

## Questions?

- Open a GitHub Discussion for general questions
- Open an Issue for bugs or feature requests
- Check existing docs in the `docs/` folder

Thank you for contributing! 🐛
