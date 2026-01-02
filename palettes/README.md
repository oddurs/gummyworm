# Palettes Directory

This directory contains character palettes for gummyworm ASCII art generation.

## Quick Start

```bash
# List all available palettes
gummyworm --list-palettes

# Use a palette
gummyworm -p blocks photo.jpg
gummyworm -p emoji cat.jpg
```

## Creating Custom Palettes

1. **Copy the template:**
   ```bash
   cp _template.palette mypalette.palette
   ```

2. **Edit the file** with your favorite editor

3. **Use your palette:**
   ```bash
   gummyworm -p mypalette image.jpg
   ```

## Palette File Format

Palette files (`.palette`) use a simple format with optional metadata:

```
# Name: My Palette
# Description: A brief description
# Author: Your Name
# Tags: ascii, custom, artistic

 .:-=+*#%@
```

### Rules

- **Comments:** Lines starting with `#` are comments or metadata
- **Metadata:** Optional headers in format `# Key: Value`
- **Characters:** First non-comment, non-empty line is the character set
- **Order:** Characters go from LIGHTEST to DARKEST (left to right)
- **Minimum:** At least 2 characters required
- **First character:** Should be a space for "empty" areas

### Metadata Fields

| Field | Description |
|-------|-------------|
| `Name` | Display name for the palette |
| `Description` | Brief description shown in `--list-palettes` |
| `Author` | Creator's name |
| `Tags` | Comma-separated tags (e.g., `ascii, high-contrast`) |

## Built-in Palettes

| Name | Characters | Best For |
|------|------------|----------|
| `standard` | ` .:-=+*#%@` | General use (default) |
| `detailed` | 72 ASCII chars | High detail, portraits |
| `simple` | ` .oO@` | Quick previews |
| `binary` | ` █` | Silhouettes, logos |
| `matrix` | ` 01` | Hacker aesthetic |
| `blocks` | ` ░▒▓█` | Smooth gradients |
| `shades` | ` ░▒▓█▓▒░` | Artistic effect |
| `retro` | ` .:░▒▓█` | Vintage computing |
| `dots` | ` ⠁⠃⠇⠿⣿` | Braille/stippled |
| `emoji` | `🌑🌒🌓🌔🌕` | Social sharing |
| `stars` | ` ·✦★✷✸✹` | Sparkly/dreamy |
| `hearts` | `🤍💓💗💖💘` | Romantic images |

## Tips

### Wide Characters (Emoji)

When using emoji or other double-width characters, start with a full-width space (U+3000) instead of regular space for proper alignment:

```
# Wrong - regular space causes misalignment
 🌑🌒🌓🌔🌕

# Correct - full-width space (　)
　🌑🌒🌓🌔🌕
```

### ASCII Compatibility

For maximum compatibility, use ASCII-only characters:
- Works in all terminals
- Safe for plain text files
- Faster processing

### Character Ideas

| Theme | Characters |
|-------|------------|
| Geometric | `·∘○◎●` |
| Arrows | `←↖↑↗→` |
| Math | `∴∵∷∶·` |
| Music | `♩♪♫♬` |
| Weather | `☀☁☂☃❄` |
| Cards | `♠♣♥♦` |
| Dice | `⚀⚁⚂⚃⚄⚅` |

## See Also

- [Palettes Guide](../docs/palettes.md) - Complete documentation
- [CLI Reference](../docs/cli-reference.md) - Command-line options
