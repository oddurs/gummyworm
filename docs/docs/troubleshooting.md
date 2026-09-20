---
sidebar_position: 8
title: Troubleshooting
---

# Troubleshooting

Common issues and solutions when using gummyworm.

## Installation Issues

### "command not found: gummyworm"

**Cause:** gummyworm is not in your PATH.

**Solutions:**

1. **If installed via Homebrew:**

   ```bash
   brew link gummyworm
   # Or reinstall
   brew reinstall gummyworm
   ```

2. **If installed manually:**

   ```bash
   # Add to PATH in ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/gummyworm/bin"
   source ~/.bashrc
   ```

3. **Run with full path:**
   ```bash
   /path/to/gummyworm/bin/gummyworm --version
   ```

### "ImageMagick not found" / "convert: command not found"

**Cause:** ImageMagick is not installed or not in PATH.

**Solutions:**

```bash
# macOS
brew install imagemagick

# Ubuntu/Debian
sudo apt install imagemagick

# Fedora
sudo dnf install ImageMagick

# Verify installation
convert --version
```

### "bash: ./gummyworm: Permission denied"

**Cause:** Script is not executable.

**Solution:**

```bash
chmod +x gummyworm bin/gummyworm
```

### "bash: ./gummyworm: /bin/bash: bad interpreter"

**Cause:** Wrong line endings (Windows CRLF instead of Unix LF).

**Solution:**

```bash
# Convert to Unix line endings
sed -i 's/\r$//' gummyworm bin/gummyworm lib/*.sh

# Or using dos2unix
dos2unix gummyworm bin/gummyworm lib/*.sh
```

### Shell version too old

**Cause:** gummyworm requires Bash 3.2+ or zsh 5.0+.

**Check your version:**

```bash
# Check Bash version
bash --version

# Check zsh version
zsh --version
```

**Solution for very old systems:**

```bash
# Install newer Bash (macOS)
brew install bash

# Or use zsh (macOS default shell since Catalina)
zsh /path/to/gummyworm photo.jpg
```

## Image Processing Issues

### "Not a valid image file"

**Cause:** The file is not a supported image format or is corrupted.

**Solutions:**

1. **Check file type:**

   ```bash
   file photo.jpg
   # Should show: JPEG image data, ...
   ```

2. **Verify ImageMagick can read it:**

   ```bash
   identify photo.jpg
   ```

3. **Supported formats:** JPEG, PNG, GIF, BMP, TIFF, WebP, and most formats ImageMagick supports.

### "Failed to download image from URL"

**Cause:** Network issues, invalid URL, or server blocking requests.

**Solutions:**

1. **Check URL is accessible:**

   ```bash
   curl -I "https://example.com/image.jpg"
   ```

2. **Download manually first:**

   ```bash
   curl -o image.jpg "https://example.com/image.jpg"
   gummyworm image.jpg
   ```

3. **Check for URL encoding issues:**
   ```bash
   # Quote URLs with special characters
   gummyworm "https://example.com/path/image%20name.jpg"
   ```

### Output looks squashed or stretched

**Cause:** Your terminal's character cell is a different shape than gummyworm
assumes. It defaults to cells 2.0x taller than wide; if your line spacing
differs, everything comes out proportionally wrong by that difference.

**Solution:** Set [`--char-aspect`](cli-reference.md#--char-aspect) to match
your terminal.

```bash
# Output too wide / squashed flat? Your cells are less tall than assumed
gummyworm --char-aspect 1.67 photo.jpg

# Output too tall / stretched? Raise it
gummyworm --char-aspect 2.2 photo.jpg
```

To find your value, render something you know is round and adjust until it
looks round:

```bash
# A test circle
magick -size 400x400 xc:white -fill black -draw "circle 200,200 200,20" circle.png
gummyworm circle.png -w 60
```

Once it looks right, make it permanent with `char_aspect` in your
[config file](configuration.md).

:::note
Before v2.3.0 the assumed ratio was 2.2, which rendered most output about 11%
wider than it should be. If you had compensated for that by hand, you can
restore the old behaviour with `--char-aspect 2.2`.
:::

**Still distorted?** Check your terminal is using a genuinely monospace font —
Consolas, Fira Code, JetBrains Mono. A proportional font cannot be corrected
with any ratio, because its glyph widths vary.

### Image is too dark or too light

**Solutions:**

1. **Try inverting:**

   ```bash
   gummyworm -i photo.jpg
   ```

2. **Use a higher contrast palette:**

   ```bash
   gummyworm -p blocks photo.jpg
   gummyworm -p binary photo.jpg
   ```

3. **Pre-process the image:**
   ```bash
   # Increase contrast with ImageMagick
   convert photo.jpg -contrast-stretch 2%x2% enhanced.jpg
   gummyworm enhanced.jpg
   ```

## Display Issues

### Unicode/emoji characters showing as boxes or ?

**Cause:** Terminal or font doesn't support the characters.

**Solutions:**

1. **Use ASCII-only palette:**

   ```bash
   gummyworm -p standard photo.jpg
   gummyworm -p detailed photo.jpg
   ```

2. **Install emoji font:**
   - macOS: Apple Color Emoji (built-in)
   - Linux: `sudo apt install fonts-noto-color-emoji`
   - Windows: Segoe UI Emoji (built-in)

3. **Use a modern terminal:**
   - macOS: iTerm2, Kitty
   - Linux: GNOME Terminal, Konsole, Kitty
   - Windows: Windows Terminal

4. **Check terminal encoding:**
   ```bash
   echo $LANG
   # Should include UTF-8, e.g., en_US.UTF-8
   ```

### Colors not showing in terminal

**Cause:** Terminal doesn't support 256 colors, or colors are disabled.

**Solutions:**

1. **Check terminal color support:**

   ```bash
   echo $TERM
   # Should be xterm-256color or similar

   # Test 256 colors
   for i in {0..255}; do printf "\e[38;5;${i}m%3d " $i; done; echo
   ```

2. **Set correct TERM:**

   ```bash
   export TERM=xterm-256color
   ```

3. **Ensure `-c` flag is used:**
   ```bash
   gummyworm -c photo.jpg
   ```

### ANSI codes visible as text (e.g., `[38;5;196m`)

**Cause:** Viewing ANSI output in a context that doesn't interpret escape codes.

**Solutions:**

1. **View in terminal:**

   ```bash
   cat output.ans
   less -R output.ans
   ```

2. **Export to HTML instead:**
   ```bash
   gummyworm -c -f html -o output.html photo.jpg
   ```

### Emoji output misaligned

**Cause:** Emoji are typically double-width characters.

**Solutions:**

1. **Use smaller width:**

   ```bash
   gummyworm -p emoji -w 40 photo.jpg
   ```

2. **Use a terminal with good emoji support:** iTerm2, Windows Terminal

## Export Issues

### HTML/SVG looks wrong in browser

**Solutions:**

1. **Check the file was saved completely:**

   ```bash
   head -20 output.html  # Should show DOCTYPE
   tail -5 output.html   # Should show closing tags
   ```

2. **Ensure color mode was enabled:**
   ```bash
   gummyworm -c -f html -o output.html photo.jpg
   ```

### PNG or GIF export fails

**Cause:** No SVG renderer installed. Both formats are produced by rendering
SVG and rasterising it, and ImageMagick cannot rasterise SVG on its own —
installing ImageMagick does not bring a renderer with it.

Since v2.3.0 gummyworm checks for this before doing any work and tells you so.
Older versions failed at the end with `Failed to convert SVG to PNG`.

**Solution:** Install `librsvg`, which provides `rsvg-convert`.

```bash
# macOS
brew install librsvg

# Ubuntu / Debian
sudo apt install librsvg2-bin

# Fedora
sudo dnf install librsvg2-tools

# Arch
sudo pacman -S librsvg
```

:::warning
Reinstalling ImageMagick does **not** fix this, and `magick -list format | grep SVG`
is not a useful check — it reports SVG as supported either way. Homebrew's
ImageMagick is built without librsvg linked in, so it renders SVG with its own
built-in renderer, which fails on the font. `rsvg-convert` is what actually
does the work.
:::

**Alternatives that need no renderer:** `svg` and `html` export are pure text
and always work.

```bash
gummyworm -c -f svg -o art.svg photo.jpg
```

### Output file is empty

**Cause:** Error during processing, or wrong output path.

**Solutions:**

1. **Check for errors (remove quiet mode):**

   ```bash
   gummyworm photo.jpg  # Look for error messages
   ```

2. **Verify image is valid:**

   ```bash
   identify photo.jpg
   ```

3. **Check output path is writable:**
   ```bash
   touch /path/to/output.txt  # Test write permission
   ```

## Performance Issues

### Processing is very slow

**Cause:** Very large images or complex processing.

**Solutions:**

1. **Reduce output dimensions:**

   ```bash
   gummyworm -w 60 huge-image.jpg
   ```

2. **Pre-resize the image:**

   ```bash
   convert huge.jpg -resize 800x800 smaller.jpg
   gummyworm smaller.jpg
   ```

3. **Skip color processing:**
   ```bash
   gummyworm photo.jpg  # Without -c flag
   ```

### High memory usage with batch processing

**Solutions:**

1. **Process files one at a time:**

   ```bash
   for f in photos/*.jpg; do
     gummyworm -o "output/$(basename "$f" .jpg).txt" "$f"
   done
   ```

2. **Use `--continue-on-error` to avoid stopping on failures:**
   ```bash
   gummyworm --continue-on-error -d ./output/ photos/*.jpg
   ```

## Getting Help

### Debug Mode

Get more verbose output for troubleshooting:

```bash
# Check dependencies
gummyworm --version
which convert
convert --version

# Test with a simple image
gummyworm -w 20 -p simple test.jpg
```

### Reporting Issues

When reporting a bug, include:

1. gummyworm version: `gummyworm --version`
2. OS and version: `uname -a`
3. Bash version: `bash --version`
4. ImageMagick version: `convert --version`
5. The exact command that failed
6. The full error message
7. A sample image (if possible)

File issues at: https://github.com/oddurs/gummyworm/issues
