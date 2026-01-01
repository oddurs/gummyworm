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
│   └── cli.sh          # Command-line interface
├── palettes/
│   └── *.palette       # Custom palette files
├── tests/
│   └── test_basic.sh   # Test suite
├── docs/               # Additional documentation
└── README.md
```

## Installation

### Prerequisites

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

### Install

```bash
# Clone or download
git clone https://github.com/example/gummyworm.git
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
```

## Usage

```
gummyworm [OPTIONS] <image_file>
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-w, --width <N>` | Output width in characters | 80 |
| `-h, --height <N>` | Output height in lines | auto |
| `-p, --palette <n>` | Character palette to use | standard |
| `-c, --color` | Enable ANSI color output | off |
| `-i, --invert` | Invert brightness (dark ↔ light) | off |
| `-o, --output <FILE>` | Save output to file | stdout |
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
- `image_validate <file>` - Validate image file
- `image_dimensions <file>` - Get "width height"
- `image_extract_pixels <file> <w> <h> <output>` - Extract pixel data
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
- `parse_args "$@"` - Parse CLI arguments (sets `ARG_*` globals)

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
