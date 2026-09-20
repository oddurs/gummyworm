# 🐛 gummyworm

```
 ██████╗ ██╗   ██╗███╗   ███╗███╗   ███╗██╗   ██╗██╗    ██╗ ██████╗ ██████╗ ███╗   ███╗
██╔════╝ ██║   ██║████╗ ████║████╗ ████║╚██╗ ██╔╝██║    ██║██╔═══██╗██╔══██╗████╗ ████║
██║  ███╗██║   ██║██╔████╔██║██╔████╔██║ ╚████╔╝ ██║ █╗ ██║██║   ██║██████╔╝██╔████╔██║
██║   ██║██║   ██║██║╚██╔╝██║██║╚██╔╝██║  ╚██╔╝  ██║███╗██║██║   ██║██╔══██╗██║╚██╔╝██║
╚██████╔╝╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║ ╚═╝ ██║
 ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
```

**Transform images into glorious ASCII art!** 🐛

A playful, feature-rich command-line tool for converting images to ASCII art with 256-color support, multiple export formats, and 12+ built-in palettes.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **macOS** | ✅ Full | Bash 3.2+ or zsh 5.0+, BSD tools |
| **Linux** | ✅ Full | Bash 4+ or zsh 5.0+, GNU tools |
| **FreeBSD** | ✅ Full | Bash 3.2+ or zsh 5.0+, BSD tools |
| **Windows (WSL)** | ✅ Full | Via Windows Subsystem for Linux |
| **Windows (Git Bash)** | ⚠️ Limited | May need ImageMagick manually |

### Requirements

- **Shell**: Bash 3.2+ or zsh 5.0+ (macOS ships with both)
- **ImageMagick** (`convert` and `identify` commands)
- **Optional**: `librsvg` (`rsvg-convert`) — required for `png` and `gif` export.
  ImageMagick cannot rasterise SVG on its own, and installing it does not pull
  this in. `brew install librsvg`, or `apt install librsvg2-bin`.
  Text, ANSI, HTML and SVG output need nothing extra.
- **Optional**: `curl` or `wget` for URL input
- **Optional**: `python3` for better Unicode support

## Features

- 🖼️ **Multiple formats** — JPEG, PNG, GIF, BMP, WebP, and more
- 🎬 **Animated GIFs** — Process and export animated ASCII art
- 🎨 **256-color output** — Full color mode for terminals
- 🌈 **True color (24-bit)** — Full RGB color support
- 🔆 **Image preprocessing** — Brightness, contrast, gamma adjustment
- 🎭 **12+ palettes** — Standard, blocks, emoji, braille, and more
- 🌍 **Export anywhere** — HTML, SVG, PNG, GIF, ANSI, plain text
- 📁 **Batch processing** — Multiple files, recursive directories
- 🌐 **URL & stdin** — Download from URLs or pipe data
- 🔧 **Extensible** — Custom palettes via files or inline

## Documentation

| Guide | Description |
|-------|-------------|
| **[Installation](docs/installation.md)** | Homebrew, manual install, platform notes |
| **[CLI Reference](docs/cli-reference.md)** | All options and flags |
| **[Palettes](docs/palettes.md)** | Built-in palettes, creating custom ones |
| **[Export Formats](docs/export-formats.md)** | HTML, SVG, PNG output |
| **[Examples](docs/examples.md)** | Common use cases and recipes |
| **[Troubleshooting](docs/troubleshooting.md)** | Common issues and solutions |
| **[Architecture](docs/architecture.md)** | Internals and extending |

## Quick Install

```bash
# Homebrew (macOS/Linux)
brew tap oddurs/gummyworm
brew install gummyworm

# From source
git clone https://github.com/oddurs/gummyworm.git
cd gummyworm && chmod +x bin/gummyworm
sudo ln -s "$(pwd)/bin/gummyworm" /usr/local/bin/gummyworm
```

See [Installation Guide](docs/installation.md) for detailed instructions.

## Quick Start

```bash
# Basic conversion
gummyworm photo.jpg

# With color
gummyworm -c sunset.png

# Wider output
gummyworm -w 120 landscape.jpg

# Block characters
gummyworm -p blocks portrait.png

# Emoji art 🌕
gummyworm -p emoji -w 40 cat.jpg

# Export to HTML
gummyworm -c -o gallery.html photo.jpg

# Export to PNG
gummyworm -c -f png -o art.png photo.jpg

# Animated GIF to terminal
gummyworm -c animation.gif

# Export animated ASCII GIF
gummyworm -c -f gif -o ascii-anim.gif animation.gif

# From URL
gummyworm https://example.com/image.jpg

# Adjust brightness/contrast
gummyworm --brightness 20 --contrast 10 dark-photo.jpg

# Gamma correction
gummyworm --gamma 2.2 -c photo.jpg

# Batch process
gummyworm -d ./output/ photos/*.jpg
```

See [Examples](docs/examples.md) for more.

## Usage

```
gummyworm [OPTIONS] <image> [image2 ...]
```

### Common Options

| Option | Description |
|--------|-------------|
| `-w, --width <N>` | Output width (default: 80) |
| `-p, --palette <name>` | Palette: standard, blocks, emoji, etc. |
| `-c, --color` | Enable 256-color output |
| `--truecolor` | Enable true color (24-bit RGB) |
| `-i, --invert` | Invert brightness |
| `--brightness <N>` | Adjust brightness (-100 to 100) |
| `--contrast <N>` | Adjust contrast (-100 to 100) |
| `--gamma <N>` | Adjust gamma (e.g., 0.5, 1.0, 2.2) |
| `--char-aspect <N>` | Terminal cell height:width (default: 2.0) |
| `-a, --animate` | Enable animation processing |
| `-f, --format <type>` | Output: text, html, svg, png, gif |
| `-o, --output <file>` | Save to file |

See [CLI Reference](docs/cli-reference.md) for all options.

## Palettes

```bash
gummyworm --list-palettes
```

| Palette | Best For |
|---------|----------|
| `standard` | General use |
| `blocks` | High contrast |
| `emoji` | Social sharing |
| `dots` | Braille art |
| `detailed` | Portraits |

Create custom palettes in `palettes/` folder with optional metadata:

```bash
# palettes/custom.palette
# Name: My Custom
# Description: A custom palette for artistic effects
 .oO0@#
```

See [Palettes Guide](docs/palettes.md) for all 12+ palettes and custom creation.

## Project Structure

```
gummyworm/
├── bin/gummyworm       # Main executable
├── lib/                # Modular library
│   ├── config.sh       # Configuration
│   ├── cli.sh          # CLI parsing
│   ├── image.sh        # Image processing
│   ├── converter.sh    # ASCII conversion
│   ├── palettes.sh     # Palette management
│   └── export.sh       # Format export
├── palettes/           # Palette files (built-in + custom)
│   ├── *.palette       # 12 built-in palettes
│   ├── _template.palette # Template for custom palettes
│   └── README.md       # Palette format docs
├── docs/               # Documentation
└── tests/              # Test suite
```

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — feel free to use, modify, and share!

---

Made with ❤️ and 🐛

*"Wiggling your images into ASCII since 2024"*
