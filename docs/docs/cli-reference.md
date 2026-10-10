---
sidebar_position: 4
title: CLI Reference
---

# CLI Reference

Complete command-line reference for gummyworm.

## Synopsis

```bash
gummyworm [OPTIONS] [--] <image_file> [image_file2 ...]
gummyworm [OPTIONS] <url>
gummyworm [OPTIONS] - < image_data
cat image.png | gummyworm [OPTIONS]
```

## Input Methods

### File Input

Convert one or more image files:

```bash
# Single file
gummyworm photo.jpg

# Multiple files
gummyworm photo1.jpg photo2.png photo3.gif

# Glob patterns
gummyworm photos/*.jpg
gummyworm **/*.png  # with recursive globbing enabled
```

A file whose name starts with `-` would be read as an option. Put `--` before
it to end option parsing — everything after `--` is treated as an input:

```bash
gummyworm -w 60 -- -cover.png
```

### URL Input

Download and convert an image from a URL:

```bash
gummyworm https://example.com/image.jpg
gummyworm "https://example.com/path/to/image.png?size=large"
```

### Stdin Input

Pipe image data directly:

```bash
# From curl
curl -s https://example.com/image.png | gummyworm

# From another command
cat photo.jpg | gummyworm -w 60

# From file redirection
gummyworm < photo.jpg
```

A lone `-` names standard input explicitly. It can be combined with files, and
it is how you read stdin when something else is also on the command line:

```bash
curl -s https://example.com/image.png | gummyworm -w 60 -
```

Run with no input and a terminal on stdin, gummyworm prints a short usage line
and exits with status 2 rather than waiting for you to type.

## Options Reference

### Dimension Options

#### `-w, --width <N>`

Set the output width in characters.

|             |                  |
| ----------- | ---------------- |
| **Default** | 80               |
| **Type**    | Positive integer |

```bash
# Narrow output
gummyworm -w 40 photo.jpg

# Wide output for detail
gummyworm -w 200 landscape.jpg

# Match terminal width
gummyworm -w $(tput cols) photo.jpg
```

#### `-H, --height <N>`

Set the output height in lines.

|             |                                             |
| ----------- | ------------------------------------------- |
| **Default** | Auto-calculated from width and aspect ratio |
| **Type**    | Positive integer                            |

```bash
# Fixed height
gummyworm -H 30 photo.jpg

# Both dimensions specified
gummyworm -w 100 -H 50 photo.jpg
```

> **Changed:** `-h` used to mean `--height`. It now shows help, as in
> most command-line tools, and the height flag is `-H`. A number straight after
> `-h` (`-h 30`) still works as a height for now, with a deprecation warning, so
> existing scripts keep running.

#### `--no-aspect`

Disable aspect ratio preservation. The image will be stretched to fill the specified dimensions.

```bash
# Stretch to exact dimensions
gummyworm -w 80 -H 40 --no-aspect photo.jpg
```

#### `--char-aspect`

The shape of your terminal's character cell, as height divided by width.

|             |                  |
| ----------- | ---------------- |
| **Default** | 2.0              |
| **Type**    | Number, 0.5–5.0  |

A character cell is taller than it is wide, so gummyworm divides the row count
by this ratio to keep proportions true. Get it wrong and a circle comes out as
an ellipse — too wide if the value is too high, too tall if it is too low.

The default of 2.0 suits most setups: a monospace font advancing 0.6em per
glyph at a line-height of 1.2. It is also what HTML and SVG exports render at,
so exported files match what you saw in the terminal.

Adjust it if your terminal's line spacing differs:

| Line spacing                          | Try  |
| ------------------------------------- | ---- |
| Tight (e.g. iTerm2 at line-height 1.0) | 1.67 |
| Typical                               | 2.0  |
| Loose                                 | 2.2  |

```bash
# Output looks squashed? Your cells are less tall than assumed
gummyworm --char-aspect 1.67 photo.jpg

# Output looks stretched? Raise it
gummyworm --char-aspect 2.2 photo.jpg
```

Set it permanently with `char_aspect` in your config file — see
[Configuration](configuration.md).

### Palette Options

#### `-p, --palette <name|string>`

Select a character palette for ASCII rendering.

|             |                                               |
| ----------- | --------------------------------------------- |
| **Default** | standard                                      |
| **Type**    | Palette name, custom string, or file basename |

**Using built-in palettes:**

```bash
gummyworm -p blocks photo.jpg
gummyworm -p emoji cat.jpg
gummyworm -p detailed portrait.png
```

**Using inline custom palette:**

```bash
# Characters from light to dark
gummyworm -p " .oO0@#" photo.jpg
gummyworm -p " ░▒▓█" photo.jpg
```

**Using palette files:**

```bash
# Uses palettes/waves.palette
gummyworm -p waves ocean.jpg
```

See [Palettes Guide](palettes.md) for complete palette documentation.

#### `-l, --list-palettes`

Display all available palettes with their character sets.

```bash
gummyworm --list-palettes
```

### Color Options

#### `-c, --color`

Enable 256-color ANSI output. Colors are mapped from the original image.

```bash
gummyworm -c sunset.png
gummyworm --color photo.jpg
```

> **Note:** Color output only works in terminals that support 256 colors. When saving to file, use `--format ansi` to preserve colors.

#### `--truecolor`

Enable true color (24-bit RGB) output. Preserves exact colors from the original image without mapping to a 256-color palette.

```bash
gummyworm --truecolor photo.jpg
gummyworm -c --truecolor landscape.png
```

> **Auto-detection:** When `-c` is used, gummyworm automatically enables true color if your terminal supports it (detected via `$COLORTERM=truecolor` or `$COLORTERM=24bit`).

#### `--no-truecolor`

Disable true color auto-detection and force 256-color mode.

```bash
# Force 256-color even if terminal supports true color
gummyworm -c --no-truecolor photo.jpg
```

#### `-i, --invert`

Invert the brightness mapping. Useful for images with dark backgrounds or when your terminal has a light theme.

```bash
# For images with dark backgrounds
gummyworm -i logo-dark-bg.png

# Combined with color
gummyworm -c -i photo.jpg
```

### Image Preprocessing Options

#### `--enhance <mode>`

Spread the image's tones across the whole palette before they are turned into
characters.

|             |                           |
| ----------- | ------------------------- |
| **Default** | `full`                    |
| **Type**    | `off`, `stretch` or `full` |

A photograph rarely uses the full range from black to white. Most of its tones
sit in the middle, and a palette of ten characters then spends most of its
steps on tones the image does not have, so the output lands on two or three
characters and looks flat. Enhancement fixes that first.

| Mode      | What it does                                                         |
| --------- | -------------------------------------------------------------------- |
| `off`     | Use the image as it is.                                              |
| `stretch` | Spread the tonal range, clipping the darkest and lightest 1%.        |
| `full`    | `stretch`, then adaptive local contrast (CLAHE), which lifts detail in flat areas. Needs ImageMagick 7.0.8 or newer; on older versions it behaves like `stretch`. |

```bash
# Keep a logo's exact tones
gummyworm --enhance off logo.png

# Spread the range but skip local contrast
gummyworm --enhance stretch photo.jpg
```

Which mode to choose:

- **Photographs:** leave it at `full`. On the benchmark corpus, `full` raised
  the mean SSIM (a structural similarity score, where 1.0 is identical) from
  0.5745 to 0.5792, with the largest gains on photos and at wider output.
- **Logos, flat graphics and line art:** use `off`. Their tones are already
  deliberate, and enhancement can shift them. Thin line art at narrow widths
  scored slightly worse with it on.
- **Images that are already high contrast:** `off` and `stretch` look nearly
  the same.

Enhancement runs before `--brightness`, `--contrast` and `--gamma`, so those
still apply on top of it. Set it permanently with `enhance` in your config
file — see [Configuration](configuration.md).

#### `--brightness <N>`

Adjust image brightness before conversion.

|             |                          |
| ----------- | ------------------------ |
| **Default** | 0 (no change)            |
| **Type**    | Integer from -100 to 100 |

```bash
# Brighten a dark image
gummyworm --brightness 30 dark-photo.jpg

# Darken a bright image
gummyworm --brightness -20 bright-photo.jpg
```

#### `--contrast <N>`

Adjust image contrast before conversion.

|             |                          |
| ----------- | ------------------------ |
| **Default** | 0 (no change)            |
| **Type**    | Integer from -100 to 100 |

```bash
# Increase contrast for more dramatic output
gummyworm --contrast 40 photo.jpg

# Decrease contrast for softer output
gummyworm --contrast -20 photo.jpg
```

#### `--gamma <N>`

Adjust image gamma (midtone brightness) before conversion.

|             |                                  |
| ----------- | -------------------------------- |
| **Default** | 1.0 (no change)                  |
| **Type**    | Positive number from 0.1 to 10.0 |

```bash
# Lighten midtones
gummyworm --gamma 1.5 photo.jpg

# Darken midtones
gummyworm --gamma 0.7 photo.jpg

# Combine all preprocessing options
gummyworm --brightness 10 --contrast 20 --gamma 1.2 photo.jpg
```

### Output Options

#### `-f, --format <type>`

Specify the output format.

| Format | Description                         |
| ------ | ----------------------------------- |
| `text` | Plain ASCII text (default)          |
| `ansi` | ANSI colored text with escape codes |
| `html` | Styled HTML document                |
| `svg`  | Scalable Vector Graphics            |
| `png`  | PNG image                           |
| `gif`  | Animated GIF (for animated inputs)  |

```bash
gummyworm -f html photo.jpg > art.html
gummyworm -f svg -o artwork.svg photo.jpg
gummyworm -f png -o poster.png photo.jpg
gummyworm -f gif -o animation.gif animated.gif
```

Without `-o`, the result goes to standard output. That works for every
format; `png` and `gif` are binary, so gummyworm refuses to write them to a
terminal and writes them to a pipe or redirect:

```bash
gummyworm -f svg photo.jpg | pbcopy
gummyworm -f png photo.jpg > poster.png
```

See [Export Formats](export-formats.md) for detailed format documentation.

#### `-o, --output <FILE>`

Save output to a file instead of stdout.

|              |                                        |
| ------------ | -------------------------------------- |
| **Default**  | stdout                                 |
| **Behavior** | Appends when processing multiple files |

```bash
# Single file
gummyworm -o art.txt photo.jpg

# Multiple files (all appended to one file)
gummyworm -o gallery.html photos/*.jpg

# Format auto-detected from extension
gummyworm -o art.html photo.jpg  # Outputs HTML
gummyworm -o art.svg photo.jpg   # Outputs SVG
```

#### `-d, --output-dir <DIR>`

Save each output to a directory with auto-generated filenames.

```bash
# Each file gets its own output
gummyworm -d ./ascii-art/ photos/*.jpg
# Creates: ./ascii-art/photo1.txt, ./ascii-art/photo2.txt, etc.

# With format specification
gummyworm -d ./html-gallery/ -f html photos/*.jpg
# Creates: ./html-gallery/photo1.html, ./html-gallery/photo2.html, etc.
```

#### `--background <color>`

Set background color for HTML, SVG, and PNG exports.

|             |                     |
| ----------- | ------------------- |
| **Default** | #1e1e1e (dark gray) |
| **Type**    | Hex color code      |

```bash
gummyworm -f html --background '#000000' -o dark.html photo.jpg
gummyworm -f svg --background '#ffffff' -o light.svg photo.jpg
gummyworm -f png --background '#1a1a2e' -o styled.png photo.jpg
```

#### `--padding <N>`

Set padding in pixels around the ASCII art for HTML, SVG, PNG, and GIF exports.

|             |                      |
| ----------- | -------------------- |
| **Default** | 0                    |
| **Type**    | Non-negative integer |

```bash
# Add 20px padding around the art
gummyworm -f png --padding 20 -o padded.png photo.jpg
gummyworm -f html --padding 40 -o spaced.html photo.jpg

# Combine with background color
gummyworm -f svg --background '#000000' --padding 30 -o art.svg photo.jpg
```

### Animation Options

For complete animation and GIF export examples, see [GIF Export](export-formats.md#gif-format).

#### `-a, --animate`

Enable animation processing for animated GIF inputs. When this is set, animated GIFs will be processed frame-by-frame.

```bash
# Play animation in terminal
gummyworm -a -c animation.gif

# Export as animated ASCII GIF
gummyworm -a -f gif -o ascii-animation.gif animation.gif
```

> **Auto-detection:** By default (`auto` mode), animation is automatically enabled for multi-frame images.

#### `--no-animate`

Disable animation processing. Only the first frame of animated images will be used.

```bash
# Use first frame only
gummyworm --no-animate animation.gif
```

#### `--frame-delay <N>`

Set the delay between frames in milliseconds for terminal playback and GIF export.

|             |                                        |
| ----------- | -------------------------------------- |
| **Default** | 100ms (or original timing from source) |
| **Type**    | Positive integer                       |

```bash
# Slower playback (200ms between frames)
gummyworm -a -c --frame-delay 200 animation.gif

# Fast animation (50ms)
gummyworm -a --frame-delay 50 -f gif -o fast.gif animation.gif
```

#### `--max-frames <N>`

Limit the maximum number of frames to process.

|             |                      |
| ----------- | -------------------- |
| **Default** | 0 (no limit)         |
| **Type**    | Non-negative integer |

```bash
# Process only first 10 frames
gummyworm -a --max-frames 10 animation.gif

# Extract just 5 frames as PNGs
gummyworm -a --max-frames 5 -f png -d ./frames/ animation.gif
```

#### `--loops <N>`

Set the number of loops for terminal playback or GIF export.

|             |                      |
| ----------- | -------------------- |
| **Default** | 0 (infinite)         |
| **Type**    | Non-negative integer |

```bash
# Play animation 3 times
gummyworm -a -c --loops 3 animation.gif

# Export GIF that loops 5 times
gummyworm -a --loops 5 -f gif -o limited.gif animation.gif
```

### Batch Processing Options

#### `-r, --recursive`

Process directories recursively, finding all image files.

```bash
# Process all images in photos/ and subdirectories
gummyworm -r photos/

# With output directory
gummyworm -r -d ./output/ photos/
```

#### `--continue-on-error`

Continue processing remaining files if one fails (useful for batch operations).

```bash
# Don't stop on errors
gummyworm --continue-on-error photos/*.jpg
```

### Informational Options

#### `-q, --quiet`

Suppress informational messages. Only errors and actual output are shown.

```bash
gummyworm -q photo.jpg > art.txt
```

#### `-h, --help`

Display help message with usage information.

```bash
gummyworm --help
```

#### `-V, --version`

Display version information.

```bash
gummyworm --version
# Output: gummyworm version 2.4.0
```

## Streams, Colour and Exit Status

gummyworm follows the usual command-line conventions, so it behaves in
pipelines and scripts.

**Standard output carries only the art** (or the exported file, when no `-o` is
given). Progress, success and warning messages go to standard error, so
`gummyworm photo.jpg | pbcopy` copies the picture and nothing else. Output sent
to a pipe or file has no blank padding lines and no banner; those are added only
on a terminal.

**Colour is for terminals.** Help and messages use colour only when the stream
is a terminal and the `NO_COLOR` environment variable is unset
([no-color.org](https://no-color.org)). Colour in the *art* is a separate choice
made with `-c` or `--truecolor`.

**Exit status**

| Status | Meaning                                                              |
| ------ | -------------------------------------------------------------------- |
| `0`    | Success, including `--help` and `--version`                          |
| `1`    | A runtime failure: a missing or unreadable image, a failed conversion |
| `2`    | A usage error: an unknown option, a bad value, no input              |

## Common Command Combinations

### High-Quality Color Output

```bash
gummyworm -c -w 120 -p detailed photo.jpg
```

### Web Gallery Export

```bash
gummyworm -c -w 100 -f html -d ./gallery/ photos/*.jpg
```

### Social Media Ready PNG

```bash
gummyworm -c -w 80 -p blocks -f png -o post.png photo.jpg
```

### Quick Preview

```bash
gummyworm -w 40 -p simple photo.jpg
```

### Process Entire Photo Library

```bash
gummyworm -r -d ./ascii/ --continue-on-error ~/Pictures/
```

### Pipe Chain

```bash
curl -s https://example.com/photo.jpg | gummyworm -c -w 60 | less -R
```

## Exit Codes

| Code | Meaning                                                |
| ---- | ------------------------------------------------------ |
| 0    | Success                                                |
| 1    | General error (invalid arguments, missing files, etc.) |
| 2    | Missing dependencies (ImageMagick not installed)       |

## Configuration Files

Set default options in a config file instead of typing them every time.

**Locations (loaded in order, later overrides earlier):**

1. `~/.config/gummyworm/config`
2. `~/.gummywormrc`
3. `./.gummywormrc` (project-specific)

**Example `~/.gummywormrc`:**

```bash
width=120
color=true
palette=blocks
```

CLI arguments always override config file settings.

See [Configuration](configuration.md) for full documentation.

## Environment Variables

| Variable         | Description                              |
| ---------------- | ---------------------------------------- |
| `GUMMYWORM_ROOT` | Override the installation root directory |
| `NO_COLOR`       | If set, disables colored log output      |
