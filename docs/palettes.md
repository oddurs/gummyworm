# Palettes Guide

Palettes define which characters are used to represent different brightness levels in your ASCII art. gummyworm comes with 12 built-in palettes and supports custom palettes via inline strings or files.

## How Palettes Work

A palette is an ordered string of characters from **lightest** (or empty) to **darkest**. When converting an image:

1. Each pixel's brightness is calculated using luminance
2. The brightness (0-255) is mapped to a character index
3. The corresponding character from the palette is output

**Example:** With palette ` .oO@` (5 characters):
- Very bright pixels → ` ` (space)
- Bright pixels → `.`
- Medium pixels → `o`
- Dark pixels → `O`
- Very dark pixels → `@`

## Built-in Palettes

View all available palettes with:

```bash
gummyworm --list-palettes
```

| Palette | Characters | Best For |
|---------|------------|----------|
| `standard` | ` .:-=+*#%@` | General purpose, good balance |
| `detailed` | 72 ASCII chars | High-detail photos, portraits |
| `simple` | ` .oO@` | Quick previews, small sizes |
| `blocks` | ` ░▒▓█` | High contrast, bold images |
| `binary` | ` █` | Silhouettes, logos, line art |
| `dots` | ` ⠁⠃⠇⠿⣿` | Braille-style, compact art |
| `shades` | ` ░▒▓█` | Block shading |
| `retro` | ` .:░▒▓█` | Retro computing aesthetic |
| `matrix` | ` 01` | Matrix/hacker style |
| `emoji` | 🌑🌒🌓🌔🌕 | Fun social posts, moon phases |
| `stars` | ` ·✦★✷✸✹` | Dreamy, celestial effects |
| `hearts` | ` ♡♥❤💖💗` | Love-themed art |

### Usage Examples

```bash
# Standard palette (default)
gummyworm photo.jpg

# Block characters for bold output
gummyworm -p blocks landscape.jpg

# Emoji for fun social sharing
gummyworm -p emoji -w 40 cat.jpg

# High detail for portraits
gummyworm -p detailed -w 150 portrait.png

# Binary for logos and silhouettes
gummyworm -p binary logo.png

# Braille dots for compact art
gummyworm -p dots -w 60 photo.jpg
```

## Custom Palettes

### Inline Custom Palettes

Specify a custom character string directly on the command line:

```bash
# Simple custom palette
gummyworm -p " .oO0@#" photo.jpg

# Block-based custom
gummyworm -p " ░▒▓█" photo.jpg

# ASCII art style
gummyworm -p " .',:;!|[{#@" photo.jpg

# Minimal
gummyworm -p " *#" photo.jpg
```

**Rules for inline palettes:**
- Characters go from lightest to darkest
- Start with a space for white/bright areas
- Minimum 2 characters required
- Special characters may need quoting

### Palette Files

Create reusable palette files in the `palettes/` directory.

**File format:** `palettes/<name>.palette`

```
# Comment lines start with #
# Blank lines are ignored
# The palette string goes on its own line

 ~≈≋⌇░▒▓█
```

**Example: Creating a custom palette**

1. Create the file `palettes/ocean.palette`:
   ```
   # Ocean-themed palette
   # Waves from calm to stormy
    ~≈≋⌇░▒▓█
   ```

2. Use it:
   ```bash
   gummyworm -p ocean beach.jpg
   ```

**Example palette files:**

`palettes/arrows.palette`:
```
# Arrow-based palette
 ·→⇒▸▶►
```

`palettes/boxes.palette`:
```
# Box drawing characters
 ╌╎┆┊░▒▓█
```

`palettes/currency.palette`:
```
# Money-themed
 ·¢$€£¥₿
```

## Unicode and Emoji Considerations

### Terminal Support

Not all terminals render Unicode characters equally:

| Character Type | Support Level |
|----------------|---------------|
| Basic ASCII | Universal |
| Extended ASCII (░▒▓) | Most terminals |
| Unicode symbols (✦★●) | Modern terminals |
| Emoji (🌕❤️🔥) | Varies widely |
| Braille (⠁⠃⠇) | Good in modern terminals |

**Recommendation:** Test your palette in your target terminal before batch processing.

### Character Width

Some Unicode characters are "wide" (take 2 columns) while others are narrow (1 column). gummyworm handles this automatically when Python 3 is available.

**Characters that may cause alignment issues:**
- Most emoji (2 columns wide)
- CJK characters
- Some symbols

**Tip:** The `emoji` palette works best at smaller widths (`-w 40`) due to wide characters.

### Font Requirements

For best results with special characters:

| Palette Type | Recommended Fonts |
|--------------|-------------------|
| Block characters | Any monospace |
| Braille | DejaVu Sans Mono, Consolas |
| Emoji | Noto Color Emoji, Apple Color Emoji |
| Stars/Symbols | Fira Code, JetBrains Mono |

## Palette Selection Guide

### By Image Type

| Image Type | Recommended Palette |
|------------|---------------------|
| Portraits | `detailed`, `standard` |
| Landscapes | `blocks`, `shades` |
| Logos/Icons | `binary`, `simple` |
| Photos (general) | `standard`, `detailed` |
| Dark images | `blocks` + `-i` (invert) |
| Artistic/stylized | `emoji`, `stars`, `matrix` |

### By Output Purpose

| Purpose | Recommended Palette |
|---------|---------------------|
| Terminal display | `standard`, `blocks` |
| Text file | `standard`, `detailed` |
| HTML/Web | Any (colors preserved) |
| Social media | `emoji`, `blocks` |
| Print | `detailed`, `standard` |
| Code comments | `simple`, `binary` |

### By Size

| Output Width | Recommended Palette |
|--------------|---------------------|
| Small (< 40) | `simple`, `blocks`, `emoji` |
| Medium (40-100) | `standard`, `blocks` |
| Large (> 100) | `detailed`, `standard` |

## Advanced: Creating Effective Palettes

### Design Principles

1. **Start with space:** White/bright areas should be empty or near-empty
2. **Gradual progression:** Characters should increase in "visual density"
3. **Consistent width:** Stick to single-width or double-width characters (don't mix)
4. **Test visually:** What looks dense to humans matters more than technical measurements

### Visual Density Order

Common characters ordered by visual density:

```
Lightest: (space) . · ' ` , - ~ _ 
Light:    : ; ! i l | / \ ( ) 
Medium:   o O 0 c C { } [ ] + = * 
Dark:     # % @ & $ X W M 
Darkest:  █ ▓ ▒ (solid blocks)
```

### Testing Your Palette

```bash
# Quick test with a gradient image
gummyworm -p "your palette here" -w 60 gradient.png

# Test with color to see mapping
gummyworm -p "your palette" -c photo.jpg

# Compare palettes
for p in standard blocks detailed; do
  echo "=== $p ==="
  gummyworm -p "$p" -w 40 photo.jpg
done
```

## Troubleshooting

### Characters not displaying correctly

- Check terminal Unicode support: `echo "░▒▓█"`
- Try a different font
- Fall back to ASCII-only palettes: `standard`, `detailed`, `simple`

### Emoji showing as boxes or ?

- Install an emoji font (Noto Color Emoji)
- Use a terminal with emoji support (iTerm2, Windows Terminal, Kitty)
- Fall back to non-emoji palettes

### Output looks wrong / not enough contrast

- Try `-i` (invert) flag for dark images
- Use `blocks` palette for more contrast
- Adjust width: smaller = more detail sometimes

### Palette file not found

- Ensure file is in `palettes/` directory
- File must end with `.palette` extension
- Check filename matches exactly (case-sensitive)

---

← [CLI Reference](cli-reference.md) | [Export Formats](export-formats.md) →
