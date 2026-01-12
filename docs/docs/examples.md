---
sidebar_position: 3
title: Examples
---

# Examples

A collection of practical examples showing gummyworm in action.

## Basic Usage

### Simple Conversion

```bash
# Convert an image to ASCII art (default 80 characters wide)
gummyworm photo.jpg
```

**Output:**

```
                    ..::::::..
                .::::::::::::::.
              .:::::.      .:::::.
            .::::.   @@@@@@   .::::.
           .:::.   @@@@@@@@@@   .:::.
          .:::.   @@@@@@@@@@@@   .:::.
          .:::   @@@@@@@@@@@@@@   :::.
          .:::   @@@@@@@@@@@@@@   :::.
          .:::.   @@@@@@@@@@@@   .:::.
           .:::.   @@@@@@@@@@   .:::.
            .::::.   @@@@@@   .::::.
              .:::::.      .:::::.
                .::::::::::::::.
                    ..::::::..
```

### Adjusting Width

```bash
# Narrow output for quick preview
gummyworm -w 40 photo.jpg

# Wide output for more detail
gummyworm -w 150 photo.jpg

# Match terminal width
gummyworm -w $(tput cols) photo.jpg
```

### Color Output

```bash
# Enable 256-color ANSI output
gummyworm -c sunset.png

# Color with wider width for detail
gummyworm -c -w 120 landscape.jpg
```

## Palette Examples

### Block Characters (High Contrast)

```bash
gummyworm -p blocks mountain.jpg
```

Best for landscapes and images with strong contrast.

### Emoji Art

```bash
gummyworm -p emoji -w 40 cat.jpg
```

Fun for social sharing! Use smaller widths since emoji are double-width.

### Detailed Photos

```bash
gummyworm -p detailed -w 150 portrait.png
```

The `detailed` palette has 72 characters for fine gradation.

### Matrix Style

```bash
gummyworm -p matrix -c hacker.jpg
```

Binary 0s and 1s with green color for that hacker aesthetic.

### Braille Dots

```bash
gummyworm -p dots -w 60 photo.jpg
```

Compact output using Unicode Braille patterns.

## Working with Colors

### Full Color Photo

```bash
gummyworm -c -w 100 -p standard vacation.jpg
```

### Inverted for Dark Images

```bash
# Original image has dark background
gummyworm -c -i logo-dark.png

# Invert brightness mapping
gummyworm -i -p blocks night-photo.jpg
```

### Color + Block Characters

```bash
gummyworm -c -p blocks -w 80 cityscape.jpg
```

## Export Examples

### HTML Gallery

```bash
# Single image to HTML
gummyworm -c -f html -o art.html photo.jpg

# With custom dark background
gummyworm -c -f html --background '#000000' -o dark-art.html photo.jpg

# Batch: all photos to one HTML file
gummyworm -c -f html -o gallery.html photos/*.jpg
```

### SVG for Print

```bash
# High-quality SVG for printing
gummyworm -c -w 120 -p blocks -f svg -o poster.svg landscape.jpg

# Custom background
gummyworm -c -f svg --background '#1a1a2e' -o styled.svg photo.jpg
```

### PNG for Social Media

```bash
# Create shareable image
gummyworm -c -w 80 -p blocks -f png -o share.png photo.jpg

# Emoji art as PNG
gummyworm -c -p emoji -w 30 -f png -o emoji-art.png cat.jpg
```

### Plain Text for README

```bash
# Generate ASCII art for documentation
gummyworm -w 60 -p simple logo.png > logo.txt
```

## Batch Processing

### Multiple Files

```bash
# Convert several images
gummyworm photo1.jpg photo2.png photo3.gif

# Using glob patterns
gummyworm photos/*.jpg
gummyworm images/**/*.png  # with recursive globbing
```

### Output to Directory

```bash
# Each file gets its own output
gummyworm -d ./ascii-output/ photos/*.jpg

# With format specification
gummyworm -c -f html -d ./html-gallery/ photos/*.jpg
```

### Recursive Directory Processing

```bash
# Process all images in folder and subfolders
gummyworm -r -d ./output/ ~/Pictures/

# With error handling for batch jobs
gummyworm -r --continue-on-error -d ./output/ ~/Pictures/
```

## Animation Examples

gummyworm can convert animated GIFs to ASCII animations for terminal playback or re-export as ASCII GIFs.

### Terminal Playback

```bash
# Play animation in terminal (with color)
gummyworm -a -c animation.gif

# Slower playback (default is 100ms between frames)
gummyworm -a -c --frame-delay 200 animation.gif

# Play 3 times then stop (default is infinite)
gummyworm -a -c --loops 3 animation.gif

# Preview first 10 frames only
gummyworm -a -c --max-frames 10 long-animation.gif
```

Press `Ctrl+C` to stop playback at any time.

### Export as ASCII GIF

```bash
# Basic conversion
gummyworm -a -c -f gif -o ascii.gif animation.gif

# Customize timing
gummyworm -a --frame-delay 150 -f gif -o slow.gif animation.gif

# Smaller file size (fewer frames, smaller dimensions)
gummyworm -a -w 40 --max-frames 30 -f gif -o compact.gif animation.gif

# Limited loops for smaller file
gummyworm -a --loops 1 -f gif -o single-loop.gif animation.gif
```

### Static from Animated

```bash
# Extract first frame only (no animation)
gummyworm --no-animate animation.gif

# Save first frame as PNG
gummyworm --no-animate -c -f png -o frame1.png animation.gif
```

### Animation Tips

| Goal               | Recommendation                       |
| ------------------ | ------------------------------------ |
| Smaller file size  | Use `-w 40-60`, `--max-frames 20-50` |
| Smoother animation | Use `--frame-delay 50-100`           |
| Better visibility  | Use `-p blocks` palette              |
| Quick preview      | Use `--max-frames 5` first           |

See also: [Animation CLI Options](cli-reference.md#animation-options) | [GIF Export Format](export-formats.md#gif-format)

## URL and Stdin

### From URL

```bash
# Download and convert
gummyworm https://example.com/image.jpg

# With options
gummyworm -c -w 100 "https://example.com/photo.png?size=large"
```

### Piping from curl

```bash
# Pipe image data
curl -s https://example.com/image.png | gummyworm -c -w 60

# Save result
curl -s https://example.com/image.png | gummyworm -w 80 > art.txt
```

### From Other Commands

```bash
# Screenshot to ASCII (macOS)
screencapture -x /tmp/screen.png && gummyworm -w 120 /tmp/screen.png

# From clipboard (macOS)
pngpaste - | gummyworm -c -w 80
```

## Creative Uses

### ASCII Banner Generator

```bash
# Convert logo to ASCII for terminal banner
gummyworm -w 60 -p simple logo.png > ~/.banner.txt
echo 'cat ~/.banner.txt' >> ~/.bashrc
```

### Git Commit Art

```bash
# Add ASCII art to git commit message
echo "feat: new feature" > /tmp/commit.txt
echo "" >> /tmp/commit.txt
gummyworm -w 40 -p simple feature-icon.png >> /tmp/commit.txt
git commit -F /tmp/commit.txt
```

### Email Signature

```bash
# Generate HTML signature
gummyworm -c -w 30 -f html -p blocks avatar.jpg > signature.html
```

### Slack/Discord Message

````bash
# Generate code block ASCII
echo '```'
gummyworm -w 50 -p blocks photo.jpg
echo '```'
````

### Watch Directory for New Images

```bash
# Using fswatch (macOS) or inotifywait (Linux)
fswatch -0 ~/Pictures/new/ | while read -d "" file; do
  gummyworm -c -w 80 "$file"
done
```

## Comparison Script

Compare different palettes on the same image:

```bash
#!/bin/bash
image="$1"
palettes=(standard detailed blocks dots emoji binary)

for p in "${palettes[@]}"; do
  echo "═══════════════════════════════════════"
  echo "Palette: $p"
  echo "═══════════════════════════════════════"
  gummyworm -p "$p" -w 40 "$image"
  echo ""
done
```

Save as `compare-palettes.sh` and run:

```bash
chmod +x compare-palettes.sh
./compare-palettes.sh photo.jpg
```

## Quick Reference

| Goal             | Command                                    |
| ---------------- | ------------------------------------------ |
| Basic conversion | `gummyworm photo.jpg`                      |
| Color output     | `gummyworm -c photo.jpg`                   |
| Wider output     | `gummyworm -w 120 photo.jpg`               |
| Block style      | `gummyworm -p blocks photo.jpg`            |
| Emoji art        | `gummyworm -p emoji -w 40 photo.jpg`       |
| Save to file     | `gummyworm -o art.txt photo.jpg`           |
| Export HTML      | `gummyworm -c -o art.html photo.jpg`       |
| Export PNG       | `gummyworm -c -f png -o art.png photo.jpg` |
| From URL         | `gummyworm https://example.com/img.jpg`    |
| Batch process    | `gummyworm -d ./out/ photos/*.jpg`         |
