# Architecture

This document describes gummyworm's internal architecture, module design, and data flow. Useful for contributors and those wanting to extend the tool.

## Overview

gummyworm is a modular Bash application following a library-based architecture. Each module handles a specific concern and can be sourced independently for scripting use.

```
┌─────────────────────────────────────────────────────────────┐
│                         bin/gummyworm                        │
│                    (Entry point / Main)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                          lib/cli.sh                          │
│              (Argument parsing, help, banner)                │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  lib/image.sh   │  │ lib/palettes.sh │  │ lib/converter.sh│
│ (Image loading) │  │ (Palette mgmt)  │  │ (ASCII convert) │
└─────────────────┘  └─────────────────┘  └─────────────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        lib/export.sh                         │
│              (HTML, SVG, PNG output generation)              │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┴───────────────────┐
          ▼                                       ▼
┌─────────────────────────┐          ┌─────────────────────────┐
│     lib/config.sh       │          │      lib/utils.sh       │
│ (Constants, defaults)   │          │ (Logging, helpers)      │
└─────────────────────────┘          └─────────────────────────┘
```

## Module Descriptions

### lib/config.sh

**Purpose:** Global configuration, constants, and version information.

**Key exports:**
- `GUMMYWORM_VERSION` — Current version string
- `GUMMYWORM_ROOT` — Installation root directory
- `DEFAULT_*` — Default values for all settings
- `COLOR_*` — ANSI color codes for output

**Usage:**
```bash
source "$GUMMYWORM_ROOT/lib/config.sh"
echo "Version: $GUMMYWORM_VERSION"
echo "Default width: $DEFAULT_WIDTH"
```

### lib/utils.sh

**Purpose:** Utility functions for logging, validation, and common operations.

**Key functions:**
| Function | Description |
|----------|-------------|
| `log_info <msg>` | Print info message (cyan) |
| `log_error <msg>` | Print error message (red) |
| `log_success <msg>` | Print success message (green) |
| `log_warn <msg>` | Print warning message (yellow) |
| `log_debug <msg>` | Print debug message (if DEBUG set) |
| `die <msg>` | Print error and exit 1 |
| `die_usage <msg>` | Print error, usage hint, exit 1 |
| `command_exists <cmd>` | Check if command is available |
| `file_readable <path>` | Check if file exists and is readable |
| `is_positive_int <val>` | Validate positive integer |
| `is_non_negative_int <val>` | Validate non-negative integer |
| `trim <string>` | Remove leading/trailing whitespace |
| `is_blank <string>` | Check if string is empty/whitespace |
| `find_images_in_dir <dir> [recursive]` | Find image files in directory |

**Logging behavior:**
- Logs go to stderr (stdout reserved for ASCII output)
- Colored output when terminal supports it
- Respects `$QUIET` variable for suppressing info messages

### lib/palettes.sh

**Purpose:** Palette management — loading, validating, and parsing character palettes.

**Key functions:**
| Function | Description |
|----------|-------------|
| `palette_get <name>` | Get palette string by name |
| `palette_exists <name>` | Check if palette exists |
| `palette_list` | List all available palettes |
| `palette_validate <string>` | Validate palette string |
| `palette_to_array <string> <arrayname>` | Parse palette to array |

**Palette resolution order:**
1. Built-in palettes (defined in `BUILTIN_PALETTES` associative array)
2. Custom palette files in `$GUMMYWORM_PALETTES_DIR/*.palette`
3. Inline string (if not matching above)

**Palette file format:**
```
# Comments start with #
# Blank lines ignored
# Palette string on its own line (light to dark)
 .:-=+*#%@
```

### lib/image.sh

**Purpose:** Image loading, validation, and pixel extraction via ImageMagick.

**Key functions:**
| Function | Description |
|----------|-------------|
| `image_check_deps` | Verify ImageMagick is installed |
| `image_validate <file>` | Validate image file (exits on error) |
| `image_is_valid <file>` | Check if valid image (returns boolean) |
| `image_dimensions <file>` | Get "width height" string |
| `image_extract_pixels <file> <w> <h> <output>` | Extract RGB pixel data |
| `is_url <string>` | Check if string is a URL |
| `download_image <url>` | Download image to temp file |
| `image_from_stdin` | Save stdin to temp file |
| `calc_brightness <r> <g> <b>` | Calculate luminance (0-255) |
| `calc_dimensions <ow> <oh> <tw> <th> <preserve>` | Calculate output dimensions |

**Pixel extraction:**
Uses ImageMagick's `convert` to resize and extract RGB values:
```bash
convert "$file" -resize "${w}x${h}!" -depth 8 txt:- | ...
```

**Brightness formula:**
```
luminance = (R × 299 + G × 587 + B × 114) / 1000
```
Based on ITU-R BT.601 standard for perceived brightness.

### lib/converter.sh

**Purpose:** Core ASCII conversion engine.

**Key functions:**
| Function | Description |
|----------|-------------|
| `convert_to_ascii <image> <w> <h> <palette> <invert> <color> <aspect>` | Main conversion function |
| `rgb_to_ansi <r> <g> <b>` | Convert RGB to ANSI 256-color code |
| `save_to_file <content> <file> <strip_ansi>` | Save output to file |

**Conversion algorithm:**
1. Calculate output dimensions (preserving aspect ratio if enabled)
2. Extract pixel data from image at target resolution
3. For each pixel:
   - Calculate brightness (0-255)
   - Map brightness to palette index
   - Optionally wrap with ANSI color codes
4. Output character grid

**Color mapping:**
Uses the ANSI 256-color palette (colors 16-231, the 6×6×6 color cube):
```bash
# RGB (0-255) to ANSI color cube (0-5)
r6=$((r * 6 / 256))
g6=$((g * 6 / 256))
b6=$((b * 6 / 256))
ansi=$((16 + 36 * r6 + 6 * g6 + b6))
```

### lib/export.sh

**Purpose:** Multi-format export (HTML, SVG, PNG).

**Key functions:**
| Function | Description |
|----------|-------------|
| `export_html <content> [bg_color]` | Generate HTML document |
| `export_svg <content> [bg_color]` | Generate SVG document |
| `export_png <content> <output_file> [bg_color]` | Generate PNG via SVG |
| `export_content <format> <content> <file> [bg_color]` | Export dispatcher |
| `export_detect_format <filepath>` | Auto-detect format from extension |
| `export_get_extension <format>` | Get file extension for format |

**HTML generation:**
- Complete HTML5 document with embedded CSS
- ANSI escape codes converted to `<span style="color:...">` elements
- Responsive centered layout

**SVG generation:**
- Vector `<text>` elements for each character
- Proper positioning and monospace font
- Full color support via `fill` attribute

**PNG generation:**
- Generates SVG first
- Uses ImageMagick to rasterize: `convert input.svg output.png`

### lib/cli.sh

**Purpose:** Command-line interface — argument parsing, help display, banner.

**Key functions:**
| Function | Description |
|----------|-------------|
| `show_banner` | Display ASCII art banner |
| `show_help` | Display help message |
| `show_version` | Display version info |
| `show_palettes` | List available palettes |
| `parse_args "$@"` | Parse CLI arguments |

**Argument parsing:**
Sets global `ARG_*` variables:
- `ARG_WIDTH`, `ARG_HEIGHT` — Dimensions
- `ARG_PALETTE` — Selected palette
- `ARG_COLOR`, `ARG_INVERT` — Boolean flags
- `ARG_OUTPUT`, `ARG_OUTPUT_DIR` — Output paths
- `ARG_FORMAT`, `ARG_BACKGROUND` — Export settings
- `ARG_RECURSIVE`, `ARG_CONTINUE_ON_ERROR` — Batch options
- `ARG_QUIET`, `ARG_PRESERVE_ASPECT` — Misc flags
- `ARG_IMAGES` — Array of input files/URLs

## Data Flow

### Single Image Conversion

```
Input (file/URL/stdin)
        │
        ▼
┌───────────────────┐
│ image_validate()  │ ← Verify file exists and is valid image
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ image_dimensions()│ ← Get original width × height
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ calc_dimensions() │ ← Calculate output size (aspect ratio)
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ palette_get()     │ ← Resolve palette string
└───────────────────┘
        │
        ▼
┌───────────────────────────┐
│ image_extract_pixels()    │ ← Resize & extract RGB data
└───────────────────────────┘
        │
        ▼
┌───────────────────────────┐
│ convert_to_ascii()        │ ← Map pixels to characters
│  ├─ calc_brightness()     │
│  ├─ palette index lookup  │
│  └─ rgb_to_ansi() [color] │
└───────────────────────────┘
        │
        ▼
┌───────────────────────────┐
│ export_content()          │ ← Format output (text/html/svg/png)
└───────────────────────────┘
        │
        ▼
     Output (stdout/file)
```

### Batch Processing

```
Input (glob/directory)
        │
        ▼
┌───────────────────────────┐
│ find_images_in_dir()      │ ← Collect all image files
└───────────────────────────┘
        │
        ▼
┌───────────────────────────┐
│ For each image:           │
│  └─ [Single conversion]   │ ← As above
│     ├─ Success: continue  │
│     └─ Error: stop or     │
│        continue (flag)    │
└───────────────────────────┘
        │
        ▼
     Output (combined or per-file)
```

## Extending gummyworm

### Adding a New Built-in Palette

Edit `lib/palettes.sh`:

```bash
# In the BUILTIN_PALETTES declaration
declare -A BUILTIN_PALETTES=(
    # ... existing palettes ...
    [mynewpalette]=" .·:;+=xX#@"
)
```

### Adding a New Export Format

1. Add export function in `lib/export.sh`:
   ```bash
   export_myformat() {
       local content="$1"
       local bg_color="${2:-$DEFAULT_BACKGROUND}"
       # Generate output...
       echo "$output"
   }
   ```

2. Update `export_content()` dispatcher:
   ```bash
   export_content() {
       case "$format" in
           # ... existing cases ...
           myformat) export_myformat "$content" "$bg_color" ;;
       esac
   }
   ```

3. Update `export_detect_format()` and `export_get_extension()`.

4. Add to CLI help in `lib/cli.sh`.

### Adding a New CLI Option

1. Add to `parse_args()` in `lib/cli.sh`:
   ```bash
   --my-option)
       ARG_MY_OPTION=true
       shift
       ;;
   --my-value)
       ARG_MY_VALUE="$2"
       shift 2
       ;;
   ```

2. Initialize default in `lib/config.sh`:
   ```bash
   readonly DEFAULT_MY_OPTION=false
   readonly DEFAULT_MY_VALUE="default"
   ```

3. Use in `bin/gummyworm` main script.

4. Document in `show_help()`.

### Using as a Library

```bash
#!/bin/bash
# my-script.sh

# Set up gummyworm
export GUMMYWORM_ROOT="/path/to/gummyworm"

# Source required modules
source "$GUMMYWORM_ROOT/lib/config.sh"
source "$GUMMYWORM_ROOT/lib/utils.sh"
source "$GUMMYWORM_ROOT/lib/palettes.sh"
source "$GUMMYWORM_ROOT/lib/image.sh"
source "$GUMMYWORM_ROOT/lib/converter.sh"
source "$GUMMYWORM_ROOT/lib/export.sh"

# Use functions directly
image_check_deps

if image_is_valid "photo.jpg"; then
    result=$(convert_to_ascii "photo.jpg" 80 0 "standard" false true true)
    html=$(export_html "$result" "#000000")
    echo "$html" > output.html
fi
```

## Testing

gummyworm has a comprehensive, modular test suite. For full documentation, see [testing.md](testing.md).

### Quick Start

```bash
# Run all tests
./tests/run_all.sh

# Run only unit tests (no ImageMagick required)
./tests/run_all.sh --unit

# Run a specific test file
./tests/test_utils.sh
```

### Test Architecture

```
tests/
├── test_runner.sh      # Shared framework: assertions, helpers, mocks
├── run_all.sh          # Master runner with aggregated results
├── test_utils.sh       # Unit tests: is_positive_int, trim, is_blank, etc.
├── test_palettes.sh    # Unit tests: palette_get, palette_validate, etc.
├── test_image.sh       # Unit tests: is_url, calc_brightness, calc_dimensions
├── test_export.sh      # Unit tests: export_detect_format, rgb_to_ansi, etc.
├── test_integration.sh # E2E tests: full CLI workflows
└── fixtures/           # Test data, expected outputs
```

### Test Categories

| Category | Purpose | ImageMagick |
|----------|---------|-------------|
| **Unit** | Test individual functions in isolation | Optional |
| **Integration** | Test complete CLI workflows | Required |

### Key Testing Features

- **Assertions:** `assert_equals`, `assert_contains`, `assert_file_exists`, `assert_exit_code`
- **Mocking:** `mock_identify`, `mock_convert` for testing without ImageMagick
- **Auto-discovery:** Functions prefixed with `test_` run automatically
- **Fixtures:** Reusable test data in `tests/fixtures/`
- **Temp management:** `make_temp_file()` with automatic cleanup

### Coverage by Module

| Module | Unit Tests | Integration Tests |
|--------|------------|-------------------|
| `lib/utils.sh` | ✅ `test_utils.sh` | — |
| `lib/palettes.sh` | ✅ `test_palettes.sh` | ✅ |
| `lib/image.sh` | ✅ `test_image.sh` | ✅ |
| `lib/converter.sh` | ✅ `test_export.sh` | ✅ |
| `lib/export.sh` | ✅ `test_export.sh` | ✅ |
| `lib/cli.sh` | — | ✅ `test_integration.sh` |
| `bin/gummyworm` | — | ✅ `test_integration.sh` |

---

← [Troubleshooting](troubleshooting.md) | [Back to README](../README.md) →
