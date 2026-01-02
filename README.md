# 🐛 GUMMYWORM

```
 ██████╗ ██╗   ██╗███╗   ███╗███╗   ███╗██╗   ██╗██╗    ██╗ ██████╗ ██████╗ ███╗   ███╗
██╔════╝ ██║   ██║████╗ ████║████╗ ████║╚██╗ ██╔╝██║    ██║██╔═══██╗██╔══██╗████╗ ████║
██║  ███╗██║   ██║██╔████╔██║██╔████╔██║ ╚████╔╝ ██║ █╗ ██║██║   ██║██████╔╝██╔████╔██║
██║   ██║██║   ██║██║╚██╔╝██║██║╚██╔╝██║  ╚██╔╝  ██║███╗██║██║   ██║██╔══██╗██║╚██╔╝██║
╚██████╔╝╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║ ╚═╝ ██║
 ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
```

**Transform images into glorious ASCII art!** 🐛

A playful, feature-rich, and extensible command-line tool for converting images to ASCII art.

## Features

- 🖼️ **Multiple image format support** - JPEG, PNG, GIF, BMP, TIFF, WebP, and more
- 🎭 **12+ built-in character palettes** - From simple to detailed, blocks to emoji
- 🎨 **256-color ANSI output** - Full color mode for terminal display
- 🔄 **Aspect ratio preservation** - Images look right in the terminal
- 📏 **Customizable dimensions** - Control width and height
- 🌙 **Invert mode** - For images with dark backgrounds
- 💾 **File output** - Save ASCII art to files
- 🔧 **Extensible** - Custom palettes via files or inline strings
- 📦 **Modular architecture** - Clean, maintainable code structure
- 📁 **Batch processing** - Convert multiple files at once
- 🔍 **Recursive directories** - Process entire folders of images
- 🌐 **URL support** - Download and convert images from URLs
- 📥 **Stdin piping** - Pipe image data directly
- 🌍 **Multiple output formats** - Export to HTML, SVG, PNG, ANSI, or plain text

## Project Structure

```
gummyworm/
├── gummyworm           # Main entry point (convenience wrapper)
├── bin/
│   └── gummyworm       # Primary executable
├── lib/
│   ├── config.sh       # Configuration and constants
│   ├── utils.sh        # Logging and utility functions
│   ├── palettes.sh     # Palette management
│   ├── image.sh        # Image processing functions
│   ├── converter.sh    # Core ASCII conversion engine
│   ├── cli.sh          # Command-line interface
│   └── export.sh       # Multi-format export (HTML, SVG, PNG)
├── palettes/
│   └── *.palette       # Custom palette files
├── tests/
│   └── test_basic.sh   # Test suite
├── docs/               # Additional documentation
└── README.md
```

## Installation

### Homebrew (macOS/Linux)

The easiest way to install gummyworm on macOS or Linux:

```bash
# Add the tap (first time only)
brew tap oddurs/gummyworm

# Install gummyworm
brew install gummyworm
```

This automatically installs ImageMagick as a dependency.

### Manual Installation

#### Prerequisites

- **Bash** 4.0+ (most Linux/macOS systems)
- **ImageMagick** (for image processing)
- **Python 3** (optional, for unicode palette support)

```bash
# Ubuntu/Debian
sudo apt install imagemagick

# macOS
brew install imagemagick

# Fedora/RHEL
sudo dnf install ImageMagick
```

#### Install from Source

```bash
# Clone or download
git clone https://github.com/oddurs/gummyworm.git
cd gummyworm

# Make executable
chmod +x gummyworm bin/gummyworm

# Optional: symlink to PATH
sudo ln -s "$(pwd)/bin/gummyworm" /usr/local/bin/gummyworm
```

## Quick Start

```bash
# Basic conversion
./gummyworm photo.jpg

# With color output
./gummyworm -c sunset.png

# Wider output for more detail
./gummyworm -w 120 landscape.jpg

# Use block characters
./gummyworm -p blocks portrait.png

# Emoji mode! 🌕
./gummyworm -p emoji cat.jpg

# Batch process multiple files
./gummyworm photos/*.jpg

# Process from URL
./gummyworm https://example.com/image.jpg

# Pipe from stdin
curl -s https://example.com/image.png | ./gummyworm

# Export as HTML (auto-detected from extension)
./gummyworm -o gallery.html photo.jpg

# Export as SVG with custom background
./gummyworm -f svg --background '#000000' -o art.svg image.png

# Export as PNG image
./gummyworm -f png -o artwork.png photo.jpg
```

## Usage

```
gummyworm [OPTIONS] <image_file> [image_file2 ...]
gummyworm [OPTIONS] < image_data
cat image.png | gummyworm [OPTIONS]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-w, --width <N>` | Output width in characters | 80 |
| `-h, --height <N>` | Output height in lines | auto |
| `-p, --palette <n>` | Character palette to use | standard |
| `-c, --color` | Enable ANSI color output | off |
| `-i, --invert` | Invert brightness (dark ↔ light) | off |
| `-f, --format <type>` | Output format: text, ansi, html, svg, png | text |
| `--background <color>` | Background color for html/svg/png exports | #1e1e1e |
| `-o, --output <FILE>` | Save output to file (appends in batch mode) | stdout |
| `-d, --output-dir <DIR>` | Save each output to directory with auto-naming | - |
| `-r, --recursive` | Process directories recursively | off |
| `--continue-on-error` | Continue batch processing if one file fails | off |
| `-l, --list-palettes` | Show available palettes | - |
| `-q, --quiet` | Suppress info messages | off |
| `--no-aspect` | Don't preserve aspect ratio | - |
| `--help` | Show help message | - |
| `--version` | Show version | - |

## Character Palettes

View available palettes with `gummyworm --list-palettes`:

| Palette | Characters | Best For |
|---------|------------|----------|
| `standard` | ` .:-=+*#%@` | General use |
| `detailed` | 72 ASCII chars | High detail photos |
| `simple` | ` .oO@` | Quick previews |
| `blocks` | ` ░▒▓█` | High contrast images |
| `binary` | ` █` | Silhouettes |
| `dots` | ` ⠁⠃⠇⠿⣿` | Braille-style art |
| `emoji` | 🌑🌒🌓🌔🌕 | Fun social posts |
| `stars` | ` ·✦★✷✸✹` | Dreamy effects |
| `hearts` | ` ♡♥❤💖💗` | Love-themed art |
| `matrix` | ` 01` | Matrix/hacker vibe |
| `retro` | ` .:░▒▓█` | Retro computing |

### Custom Palettes

**Inline:**
```bash
./gummyworm -p " .oO0@#" image.jpg
```

**File-based:** Create `palettes/mypalette.palette`:
```
# My custom palette
# Characters from light to dark
 ·•●◉⬤
```

Then use: `./gummyworm -p mypalette image.jpg`

## Output Formats

Gummyworm can export ASCII art in multiple formats using the `-f, --format` flag:

| Format | Extension | Description |
|--------|-----------|-------------|
| `text` | .txt | Plain ASCII text (default) |
| `ansi` | .ans | ANSI colored text with escape codes |
| `html` | .html | Styled HTML document with inline CSS |
| `svg` | .svg | Scalable Vector Graphics |
| `png` | .png | PNG image (requires ImageMagick) |

### Auto-Detection

When using `-o`, the format is automatically detected from the file extension:

```bash
./gummyworm -o art.html image.jpg   # Exports as HTML
./gummyworm -o art.svg image.jpg    # Exports as SVG
./gummyworm -o art.png image.jpg    # Exports as PNG
```

### HTML Export

Generates a complete HTML document with CSS styling:

```bash
./gummyworm -f html -o gallery.html photo.jpg
./gummyworm -f html --background '#000000' -o dark.html photo.jpg
```

Features:
- Responsive centered layout
- Monospace font stack
- Full color preservation from ANSI codes
- Customizable background color

### SVG Export

Creates scalable vector graphics perfect for web or print:

```bash
./gummyworm -f svg -o artwork.svg landscape.png
./gummyworm -f svg --background '#1a1a2e' -o styled.svg image.jpg
```

Features:
- Infinite scalability without pixelation
- Proper text positioning
- Color-accurate rendering
- Embedded font styles

### PNG Export

Renders ASCII art to a PNG image via SVG conversion:

```bash
./gummyworm -f png -o poster.png -w 100 photo.jpg
```

Features:
- High-quality rasterization
- Preserves colors from original
- Great for sharing on social media

## Module Reference

### lib/config.sh
Global configuration, constants, version info, and color codes.

### lib/utils.sh
Utility functions:
- `log_info`, `log_error`, `log_success`, `log_warn`, `log_debug`
- `die`, `die_usage`
- `command_exists`, `file_readable`
- `is_positive_int`, `is_non_negative_int`
- `trim`, `is_blank`
- `find_images_in_dir <dir> [recursive]` - Find image files in directory

### lib/palettes.sh
Palette management:
- `palette_get <name>` - Get palette string
- `palette_exists <name>` - Check if palette exists
- `palette_list` - List all palettes
- `palette_validate <string>` - Validate palette
- `palette_to_array <string> <arrayname>` - Parse to array

### lib/image.sh
Image processing:
- `image_check_deps` - Verify ImageMagick installed
- `image_validate <file>` - Validate image file (fatal)
- `image_is_valid <file>` - Check if valid image (non-fatal)
- `image_dimensions <file>` - Get "width height"
- `image_extract_pixels <file> <w> <h> <output>` - Extract pixel data
- `is_url <string>` - Check if string is a URL
- `download_image <url>` - Download image to temp file
- `image_from_stdin` - Save stdin to temp file
- `calc_brightness <r> <g> <b>` - Calculate luminance
- `calc_dimensions <ow> <oh> <tw> <th> <preserve>` - Calculate output size

### lib/converter.sh
Core conversion:
- `convert_to_ascii <image> <w> <h> <palette> <invert> <color> <aspect>` - Main conversion
- `rgb_to_ansi <r> <g> <b>` - RGB to ANSI color code
- `save_to_file <content> <file> <strip_ansi>` - Save output

### lib/cli.sh
User interface:
- `show_banner`, `show_help`, `show_version`, `show_palettes`
- `parse_args "$@"` - Parse CLI arguments (sets `ARG_*` globals including `ARG_IMAGES` array)

### lib/export.sh
Multi-format export:
- `export_html <content> [bg_color]` - Generate HTML document
- `export_svg <content> [bg_color]` - Generate SVG document
- `export_png <content> <output_file> [bg_color]` - Generate PNG image
- `export_content <format> <content> <file> [bg_color]` - Export dispatcher
- `export_detect_format <filepath>` - Auto-detect format from extension
- `export_get_extension <format>` - Get file extension for format

## Testing

```bash
# Run test suite
chmod +x tests/test_basic.sh
./tests/test_basic.sh
```

## Extending Gummyworm

### Adding a New Palette

1. **Built-in:** Edit `lib/palettes.sh`, add to `BUILTIN_PALETTES` array
2. **Custom file:** Create `palettes/yourname.palette`

### Using as a Library

```bash
#!/bin/bash
export GUMMYWORM_ROOT="/path/to/gummyworm"

source "$GUMMYWORM_ROOT/lib/config.sh"
source "$GUMMYWORM_ROOT/lib/utils.sh"
source "$GUMMYWORM_ROOT/lib/palettes.sh"
source "$GUMMYWORM_ROOT/lib/image.sh"
source "$GUMMYWORM_ROOT/lib/converter.sh"

# Use functions directly
result=$(convert_to_ascii "image.jpg" 80 0 " .:-=+*#%@" false false true)
echo "$result"
```

### Adding New Features

The modular structure makes it easy to extend:
- Add new output formats in `lib/converter.sh`
- Add new CLI options in `lib/cli.sh`
- Add new image operations in `lib/image.sh`

## Technical Details

- Uses ImageMagick for image processing
- Luminance formula: `(R×299 + G×587 + B×114) / 1000`
- Color output: 256-color ANSI (6×6×6 color cube)
- Aspect ratio: Assumes 2:1 terminal character height:width

## License

MIT License - feel free to use, modify, and share!

---

Made with ❤️ and 🐛

*"Wiggling your images into ASCII since 2024"*
