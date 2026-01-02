# Export Formats

gummyworm can export ASCII art in multiple formats for different use cases. This guide covers each format's features and best practices.

## Format Overview

| Format | Extension | Color Support | Use Case |
|--------|-----------|---------------|----------|
| `text` | .txt | No | Plain ASCII, maximum compatibility |
| `ansi` | .ans | Yes (256 or 24-bit) | Terminal display, sharing via paste |
| `html` | .html | Yes (full RGB) | Web pages, email, documents |
| `svg` | .svg | Yes (full RGB) | Scalable graphics, print, web |
| `png` | .png | Yes (full RGB) | Images, social media, sharing |

## Specifying Format

### Explicit Format Flag

Use `-f, --format` to specify the output format:

```bash
gummyworm -f html photo.jpg > art.html
gummyworm -f svg -o artwork.svg photo.jpg
gummyworm -f png -o poster.png photo.jpg
```

### Auto-Detection from Extension

When using `-o`, the format is automatically detected from the file extension:

```bash
gummyworm -o art.html photo.jpg   # → HTML
gummyworm -o art.svg photo.jpg    # → SVG
gummyworm -o art.png photo.jpg    # → PNG
gummyworm -o art.txt photo.jpg    # → Text
gummyworm -o art.ans photo.jpg    # → ANSI
```

## Text Format (Default)

Plain ASCII text output with no formatting or color codes.

```bash
gummyworm photo.jpg                    # To stdout
gummyworm -f text -o art.txt photo.jpg # To file
```

**Characteristics:**
- Maximum compatibility
- Works in any text editor
- No color information preserved
- Smallest file size
- Best for code comments, READMEs, plain text documents

**Example output:**
```
        .:::::..        
      .:::::::::::.     
    .:::.  @@  .:::.    
   :::.   @@@@   .:::   
  :::.   @@@@@@   .:::  
```

## ANSI Format

Text with ANSI escape codes for 256-color terminal display.

```bash
gummyworm -c photo.jpg                   # To stdout with color
gummyworm -f ansi -o art.ans photo.jpg   # To file
```

**Characteristics:**
- 256-color palette (6×6×6 color cube) by default
- True color (24-bit RGB) when `--truecolor` is used or auto-detected
- Works in most modern terminals
- Escape codes visible if opened in plain text editor
- Great for terminal display and sharing via paste services

**Color modes:**
```bash
# 256-color (default)
gummyworm -c -f ansi -o colored.ans photo.jpg

# True color (24-bit RGB) - preserves exact colors
gummyworm -c --truecolor -f ansi -o truecolor.ans photo.jpg

# Force 256-color even if terminal supports true color
gummyworm -c --no-truecolor -f ansi -o 256color.ans photo.jpg
```

**Viewing ANSI files:**
```bash
cat art.ans           # In terminal
less -R art.ans       # With pager
```

**Color mode is required:** The `-c` flag must be used for color output, or the ansi format will contain no color codes.

```bash
# With color
gummyworm -c -f ansi -o colored.ans photo.jpg

# Without color (just text with .ans extension)
gummyworm -f ansi -o plain.ans photo.jpg
```

## HTML Format

Complete HTML document with embedded CSS styling.

```bash
gummyworm -c -f html -o gallery.html photo.jpg
gummyworm -c -f html --background '#000000' -o dark.html photo.jpg
```

**Characteristics:**
- Self-contained HTML document
- Inline CSS for each colored character
- Responsive, centered layout
- Monospace font stack
- Full color preservation from original image
- Opens in any web browser

**Features:**
- **Responsive design:** Scales with browser width
- **Font stack:** Uses system monospace fonts
- **Background control:** Customizable via `--background`
- **Color accuracy:** Full RGB color from source image

**Example generated HTML structure:**
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { background: #1e1e1e; }
    pre { font-family: monospace; }
    /* ... */
  </style>
</head>
<body>
  <pre>
    <span style="color:#ff6b6b">@</span>
    <span style="color:#4ecdc4">#</span>
    <!-- ... -->
  </pre>
</body>
</html>
```

**Use cases:**
- Web galleries
- Email (inline in body)
- Documentation
- Blog posts
- Sharing with non-technical users

## SVG Format

Scalable Vector Graphics for high-quality, resolution-independent output.

```bash
gummyworm -c -f svg -o artwork.svg photo.jpg
gummyworm -c -f svg --background '#1a1a2e' -o styled.svg photo.jpg
```

**Characteristics:**
- Infinite scalability without pixelation
- Vector text elements
- Embedded font styles
- Full color support
- Editable in vector graphics software

**Advantages:**
- **Print-ready:** Scales to any size for printing
- **Web-friendly:** Small file size, sharp at any zoom
- **Editable:** Can be modified in Illustrator, Inkscape, etc.
- **Accessible:** Text remains selectable

**Example use cases:**
- Posters and prints
- Website graphics
- Presentations
- T-shirt designs
- High-DPI displays

**Opening SVG files:**
- Web browsers (Chrome, Firefox, Safari)
- Vector editors (Illustrator, Inkscape, Figma)
- Image viewers (Preview on macOS)

## PNG Format

Rasterized PNG image rendered from the ASCII art.

```bash
gummyworm -c -f png -o poster.png photo.jpg
gummyworm -c -w 100 -f png -o hires.png photo.jpg
```

**Characteristics:**
- High-quality rasterization via SVG conversion
- Fixed resolution (based on character dimensions)
- Full color support
- Universal image format compatibility
- Requires ImageMagick

**Best practices:**
- Use larger widths (`-w 100`+) for higher resolution output
- Consider `blocks` palette for bold, clear output
- Good for social media sharing

**Use cases:**
- Social media posts (Twitter, Instagram, etc.)
- Discord/Slack sharing
- Image galleries
- Thumbnails

## Background Color

Customize the background color for HTML, SVG, and PNG exports:

```bash
# Dark backgrounds
gummyworm -f html --background '#000000' -o black.html photo.jpg
gummyworm -f svg --background '#1a1a2e' -o navy.svg photo.jpg

# Light backgrounds
gummyworm -f html --background '#ffffff' -o white.html photo.jpg

# Colored backgrounds
gummyworm -f png --background '#2d3436' -o gray.png photo.jpg
```

**Default:** `#1e1e1e` (dark gray, easy on the eyes)

**Tips:**
- Dark backgrounds work best with color output
- Light backgrounds may need inverted images (`-i`)
- Match your website or presentation theme

## Batch Export

Export multiple images to a format:

### Single Output File (Appended)

```bash
# All images combined into one HTML file
gummyworm -c -f html -o gallery.html photos/*.jpg
```

### Separate Output Files

```bash
# Each image gets its own file
gummyworm -c -f html -d ./html-gallery/ photos/*.jpg
# Creates: html-gallery/photo1.html, html-gallery/photo2.html, etc.

gummyworm -c -f png -d ./png-output/ photos/*.jpg
# Creates: png-output/photo1.png, png-output/photo2.png, etc.
```

## Format Comparison

### File Size (approximate for 80x40 output)

| Format | Without Color | With Color |
|--------|---------------|------------|
| Text | ~3 KB | ~3 KB |
| ANSI | ~3 KB | ~15-25 KB |
| HTML | ~5 KB | ~50-100 KB |
| SVG | ~10 KB | ~100-200 KB |
| PNG | N/A | ~50-150 KB |

### Compatibility

| Format | Terminal | Browser | Editor | Image Viewer |
|--------|----------|---------|--------|--------------|
| Text | ✅ | ✅ | ✅ | ❌ |
| ANSI | ✅ | ❌ | ⚠️ | ❌ |
| HTML | ❌ | ✅ | ✅ | ❌ |
| SVG | ❌ | ✅ | ✅ | ✅ |
| PNG | ❌ | ✅ | ✅ | ✅ |

## Troubleshooting

### HTML colors look wrong

- Ensure `-c` (color) flag is used
- Check the source image isn't grayscale

### SVG text not rendering correctly

- Try opening in a different browser
- Check font availability on the system
- The SVG uses common monospace fonts

### PNG is blank or error

- Ensure ImageMagick is installed: `convert --version`
- Check ImageMagick has SVG support: `convert -list format | grep SVG`

### Output file is empty

- Check that the image file exists and is readable
- Verify ImageMagick can process the image: `identify photo.jpg`
- Look for error messages (remove `-q` flag)

---

← [Palettes Guide](palettes.md) | [Examples](examples.md) →
