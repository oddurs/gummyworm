# 🐛 GUMMYWORM

```
 ██████╗ ██╗   ██╗███╗   ███╗███╗   ███╗██╗   ██╗██╗    ██╗ ██████╗ ██████╗ ███╗   ███╗
██╔════╝ ██║   ██║████╗ ████║████╗ ████║╚██╗ ██╔╝██║    ██║██╔═══██╗██╔══██╗████╗ ████║
██║  ███╗██║   ██║██╔████╔██║██╔████╔██║ ╚████╔╝ ██║ █╗ ██║██║   ██║██████╔╝██╔████╔██║
██║   ██║██║   ██║██║╚██╔╝██║██║╚██╔╝██║  ╚██╔╝  ██║███╗██║██║   ██║██╔══██╗██║╚██╔╝██║
╚██████╔╝╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║ ╚═╝ ██║
 ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
```

**Transform images into glorious ASCII art!** ✨

A playful, feature-rich, and extensible command-line tool for converting images to ASCII art with support for multiple character palettes, color output, and customization options.

## Features

- 🖼️ **Multiple image format support** - JPEG, PNG, GIF, BMP, TIFF, WebP, and more
- 🎭 **12 built-in character palettes** - From simple to detailed, blocks to emoji
- 🎨 **256-color ANSI output** - Full color mode for terminal display
- 🔄 **Aspect ratio preservation** - Images look right in the terminal
- 📏 **Customizable dimensions** - Control width and height
- 🌙 **Invert mode** - For images with dark backgrounds
- 💾 **File output** - Save ASCII art to files
- 🔧 **Extensible** - Use custom character palettes

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

### Install gummyworm

```bash
# Download and make executable
curl -o gummyworm https://raw.githubusercontent.com/example/gummyworm/main/gummyworm
chmod +x gummyworm

# Move to a directory in your PATH (optional)
sudo mv gummyworm /usr/local/bin/
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

# Emoji mode! 🎉
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
| `-p, --palette <name>` | Character palette to use | standard |
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
| `shades` | ` ░▒▓█▓▒░` | Symmetric shading |

### Custom Palettes

You can use any string of characters as a custom palette:

```bash
# Space-separated for simple sets
./gummyworm -p " .oO0@#" image.jpg

# Any unicode characters work
./gummyworm -p " ·•●◉" image.jpg
```

Characters should be ordered from lightest (or darkest with `-i`) to darkest.

## Examples

### Basic Usage

```bash
# Convert a photo with default settings
./gummyworm vacation.jpg
```
```
        .:-=+**#%%@@@%%#*+=--:.        
      :+%@@@@@@@@@@@@@@@@@@@@@@#=      
    .+@@@@@%%%%%%%%%%%%%%%%%%%%@@%-    
   .*@@@@%+--::::::::::::::--=#@@@@-   
```

### Colored Terminal Output

```bash
# Full color ASCII art
./gummyworm -c -w 100 sunset.png
```

### High Detail

```bash
# Use detailed palette for maximum detail
./gummyworm -w 200 -p detailed photo.jpg
```

### Block Art

```bash
# Great for logos and high-contrast images
./gummyworm -p blocks logo.png
```
```
    ██████████████████████    
  ██░░░░░░░░░░░░░░░░░░░░░░██  
  ██░░▓▓▓▓▓▓░░░░▓▓▓▓▓▓░░░░██  
  ██░░▓▓░░░░░░░░░░░░▓▓░░░░██  
```

### Save to File

```bash
# Save ASCII art to a text file
./gummyworm -w 120 -o art.txt image.jpg

# Save with colors (for terminals that support it)
./gummyworm -c -w 120 -o art.ansi image.jpg
```

### Dark Background Images

```bash
# Use invert for images with dark backgrounds
./gummyworm -i space_photo.jpg
```

## Pro Tips

1. **Width matters**: Wider output (100-200 chars) gives more detail
2. **Terminal font**: Use a monospace font for proper alignment
3. **Color mode**: Use `-c` only for terminal display, not text files
4. **Dark images**: Use `-i` for images with dark backgrounds
5. **Blocks palette**: Great for logos and high-contrast images
6. **Aspect ratio**: Terminal characters are taller than wide; the tool compensates automatically

## Extending gummyworm

### Adding New Palettes

Edit the `PALETTES` associative array in the script:

```bash
declare -A PALETTES=(
    # ... existing palettes ...
    ["mynewpalette"]=" ·∘○◎●"
)
```

### Using as a Library

Source the script in your own bash scripts:

```bash
#!/bin/bash
source /path/to/gummyworm

# Use the convert_to_ascii function directly
result=$(convert_to_ascii "image.jpg" 80 0 " .:-=+*#%@" false false true)
echo "$result"
```

## Technical Details

- Uses ImageMagick's `convert` command for image processing
- Calculates luminance using the standard formula: `(R×299 + G×587 + B×114) / 1000`
- Supports both ASCII and Unicode character palettes
- Color output uses 256-color ANSI escape sequences
- Aspect ratio correction assumes 2:1 terminal character height:width ratio

## Troubleshooting

### "ImageMagick is required but not installed"

Install ImageMagick using your system's package manager.

### Unicode characters display incorrectly

- Ensure your terminal supports Unicode
- Set `LANG` environment variable: `export LANG=en_US.UTF-8`

### Colors don't display

- Ensure your terminal supports 256 colors
- Some terminals need `TERM=xterm-256color`

### Output looks stretched

- Use `--no-aspect` if automatic aspect ratio doesn't work
- Manually specify `-h` height parameter

## License

MIT License - feel free to use, modify, and share!

## Contributing

Contributions welcome! Ideas for enhancement:
- Additional palettes
- Different aspect ratio presets
- Dithering algorithms
- Animation support (GIF frames to ASCII)
- HTML/ANSI output formats

---

Made with ❤️ and ☕

*"Because sometimes you just need to see your cat in ASCII"*
