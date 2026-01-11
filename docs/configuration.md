# Configuration

gummyworm supports configuration files for setting default options. This saves you from typing the same flags repeatedly.

## Config File Locations

Config files are loaded in order (later files override earlier):

1. `~/.config/gummyworm/config` — XDG-style config
2. `~/.gummywormrc` — User defaults
3. `./.gummywormrc` — Project-specific (current directory)

CLI arguments always take precedence over config file settings.

## File Format

Simple `key=value` format, one setting per line:

```bash
# Comments start with #
width=120
palette=blocks
color=true
```

Values can be quoted or unquoted:

```bash
background=#1e1e1e
background="#1e1e1e"
background='#1e1e1e'
```

## Available Settings

### Dimensions

| Key | Default | Description |
|-----|---------|-------------|
| `width` | 80 | Output width in characters |
| `height` | 0 | Output height (0 = auto from aspect ratio) |
| `preserve_aspect` | true | Maintain image aspect ratio |

### Palette

| Key | Default | Description |
|-----|---------|-------------|
| `palette` | standard | Palette name or custom characters |

### Color

| Key | Default | Description |
|-----|---------|-------------|
| `color` | false | Enable 256-color output |
| `truecolor` | false | Enable 24-bit true color |
| `invert` | false | Invert brightness mapping |

### Image Preprocessing

| Key | Default | Description |
|-----|---------|-------------|
| `brightness` | 0 | Adjust brightness (-100 to 100) |
| `contrast` | 0 | Adjust contrast (-100 to 100) |
| `gamma` | 1.0 | Adjust gamma (0.1 to 10.0) |

### Export

| Key | Default | Description |
|-----|---------|-------------|
| `format` | text | Output format (text, ansi, html, svg, png, gif) |
| `background` | #1e1e1e | Background color for exports |
| `padding` | 0 | Padding in pixels for exports |

### Animation

| Key | Default | Description |
|-----|---------|-------------|
| `animate` | auto | Animation mode (auto, true, false) |
| `frame_delay` | 100 | Milliseconds between frames |
| `max_frames` | 0 | Max frames to process (0 = all) |
| `loops` | 0 | Loop count (0 = infinite) |

### Other

| Key | Default | Description |
|-----|---------|-------------|
| `quiet` | false | Suppress info messages |

## Example Configurations

### Color Photography Workflow

For photographers who regularly convert images:

```bash
# ~/.gummywormrc
width=120
color=true
truecolor=true
palette=detailed
brightness=10
contrast=15
```

### Terminal Art Profile

For creating ASCII art in terminals:

```bash
# ~/.gummywormrc
width=80
palette=blocks
color=true
background=#000000
```

### Web Export Workflow

For generating HTML galleries:

```bash
# ~/.gummywormrc
format=html
width=100
color=true
padding=20
background=#1a1a2e
```

### Project-Specific Config

Create `.gummywormrc` in a project directory:

```bash
# ./project/.gummywormrc
width=60
palette=simple
quiet=true
```

## Getting Started

1. Copy the example config:
   ```bash
   cp /path/to/gummyworm/.gummywormrc.example ~/.gummywormrc
   ```

2. Edit to your preferences:
   ```bash
   # ~/.gummywormrc
   width=100
   color=true
   palette=blocks
   ```

3. Run gummyworm — your defaults are applied:
   ```bash
   gummyworm photo.jpg  # Uses width=100, color, blocks palette
   ```

4. Override any setting with CLI flags:
   ```bash
   gummyworm -w 60 photo.jpg  # Uses width=60, but keeps other config
   ```

## Tips

- Use `~/.gummywormrc` for your personal preferences
- Use `./.gummywormrc` in project directories for project-specific settings
- Settings not in your config file use the built-in defaults
- CLI arguments always win over config file settings
