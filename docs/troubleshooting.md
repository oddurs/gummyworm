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

### Bash version too old

**Cause:** gummyworm requires Bash 4.0+, but macOS ships with Bash 3.2.

**Solution:**
```bash
# Install newer Bash
brew install bash

# Check version
/opt/homebrew/bin/bash --version  # Apple Silicon
/usr/local/bin/bash --version     # Intel Mac

# Either run gummyworm with newer bash explicitly
/opt/homebrew/bin/bash /path/to/gummyworm photo.jpg

# Or add newer bash to PATH first
export PATH="/opt/homebrew/bin:$PATH"
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

### Output looks distorted or wrong aspect ratio

**Cause:** Terminal font isn't truly monospace, or aspect calculation is off.

**Solutions:**

1. **Use a proper monospace font:** Consolas, Fira Code, JetBrains Mono, etc.

2. **Try `--no-aspect`:**
   ```bash
   gummyworm --no-aspect -w 80 -h 40 photo.jpg
   ```

3. **Adjust dimensions manually:**
   ```bash
   # Terminal characters are typically ~2:1 height:width
   gummyworm -w 80 -h 40 photo.jpg
   ```

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

### PNG export fails

**Cause:** ImageMagick SVG support missing.

**Solutions:**

1. **Check ImageMagick has SVG support:**
   ```bash
   convert -list format | grep SVG
   ```

2. **Reinstall ImageMagick with SVG:**
   ```bash
   # macOS
   brew reinstall imagemagick
   
   # Ubuntu
   sudo apt install imagemagick librsvg2-bin
   ```

3. **Export to SVG and convert separately:**
   ```bash
   gummyworm -c -f svg -o art.svg photo.jpg
   convert art.svg art.png
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

---

← [Examples](examples.md) | [Architecture](architecture.md) →
