---
sidebar_position: 2
title: Installation
---

# Installation

This guide covers all methods for installing gummyworm on your system.

## Platform Compatibility

gummyworm is designed for maximum compatibility across Unix-like systems:

| Platform           | Status        | Shell Required        |
| ------------------ | ------------- | --------------------- |
| macOS 10.6+        | ✅ Tested     | Bash 3.2+ or zsh 5.0+ |
| Ubuntu/Debian      | ✅ Tested     | Bash 4+ or zsh 5.0+   |
| Fedora/RHEL        | ✅ Tested     | Bash 4+ or zsh 5.0+   |
| Arch Linux         | ✅ Tested     | Bash 5+ or zsh 5.0+   |
| FreeBSD            | ✅ Compatible | Bash 3.2+ or zsh 5.0+ |
| Alpine Linux       | ✅ Compatible | Bash 5+ or zsh 5.0+   |
| Windows (WSL)      | ✅ Tested     | Bash 4+ or zsh 5.0+   |
| Windows (Git Bash) | ⚠️ Limited    | Bash 4+               |

**Note**: gummyworm supports both Bash 3.2+ and zsh 5.0+ for maximum compatibility. macOS ships with both shells by default.

## Quick Install (Homebrew)

The easiest way to install gummyworm on macOS or Linux:

```bash
# Add the tap and install (one command)
brew install oddurs/gummyworm/gummyworm

# Or separately:
brew tap oddurs/gummyworm
brew install gummyworm
```

This automatically installs:

- ImageMagick (required dependency)
- Shell completions for bash and zsh

**Upgrade to latest version:**

```bash
brew update && brew upgrade gummyworm
```

**Uninstall:**

```bash
brew uninstall gummyworm
brew untap oddurs/gummyworm  # optional: remove the tap
```

## Manual Installation

### Prerequisites

| Dependency                | Required | Purpose                                        |
| ------------------------- | -------- | ---------------------------------------------- |
| **Bash 3.2+ or zsh 5.0+** | Yes      | Shell interpreter (macOS has both!)            |
| **ImageMagick**           | Yes      | Image processing and pixel extraction          |
| **Python 3**              | No       | Better Unicode/emoji character width detection |
| **curl or wget**          | No       | URL image downloads                            |

### Installing ImageMagick

#### macOS

```bash
# Using Homebrew (recommended)
brew install imagemagick

# Using MacPorts
sudo port install ImageMagick
```

#### Ubuntu / Debian

```bash
sudo apt update
sudo apt install imagemagick
```

#### Fedora / RHEL / CentOS

```bash
sudo dnf install ImageMagick

# On older systems with yum
sudo yum install ImageMagick
```

#### Arch Linux

```bash
sudo pacman -S imagemagick
```

#### Alpine Linux

```bash
apk add imagemagick bash  # bash is not installed by default on Alpine
```

#### FreeBSD

```bash
pkg install ImageMagick7 bash
```

#### Windows (WSL)

```bash
# In your WSL distribution (Ubuntu, Debian, etc.)
sudo apt update
sudo apt install imagemagick
```

### Verifying Prerequisites

```bash
# Check Bash version (need 3.2+ for macOS, 4+ for Linux)
bash --version
# Expected: GNU bash, version 3.2.57 or higher

# Check ImageMagick is installed
convert --version
# or for ImageMagick 7:
magick --version

# Check optional Python 3 (for better emoji support)
python3 --version
```

### Install from Source

1. **Clone the repository:**

   ```bash
   git clone https://github.com/oddurs/gummyworm.git
   cd gummyworm
   ```

2. **Make scripts executable:**

   ```bash
   chmod +x gummyworm bin/gummyworm
   ```

3. **Test the installation:**

   ```bash
   ./gummyworm --version
   ./gummyworm --help
   ```

4. **Add to PATH (choose one method):**

   **Option A: Symlink to /usr/local/bin (recommended)**

   ```bash
   sudo ln -s "$(pwd)/bin/gummyworm" /usr/local/bin/gummyworm
   ```

   **Option B: Add directory to PATH**

   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/gummyworm/bin"
   ```

   **Option C: Create an alias**

   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   alias gummyworm='/path/to/gummyworm/bin/gummyworm'
   ```

5. **Reload your shell:**
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

## Platform-Specific Notes

### macOS

- **Apple Silicon (M1/M2/M3):** Fully supported. Homebrew installs native ARM binaries.
- **Intel Macs:** Fully supported.
- **Shell:** Works with the default shells. macOS includes Bash 3.2 and zsh 5.x (default since Catalina). Both are fully supported.

### Linux

- Works on any distribution with Bash 3.2+/zsh 5.0+ and ImageMagick.
- For headless servers, ensure ImageMagick is built with PNG/JPEG support.

### Windows (WSL)

gummyworm works in Windows Subsystem for Linux:

1. **Install WSL:**

   ```powershell
   wsl --install
   ```

2. **Inside WSL (Ubuntu):**
   ```bash
   sudo apt update
   sudo apt install imagemagick git
   git clone https://github.com/oddurs/gummyworm.git
   cd gummyworm && chmod +x gummyworm bin/gummyworm
   ```

### Docker

Run gummyworm in a container without installing dependencies on your host system.

#### Quick Run (No Build Required)

```bash
# One-liner using Alpine (downloads ~50MB first time)
docker run --rm -v "$(pwd):/work" -w /work alpine:latest sh -c \
  "apk add --no-cache bash imagemagick curl && \
   wget -qO- https://github.com/oddurs/gummyworm/archive/refs/heads/main.tar.gz | tar xz && \
   gummyworm-main/bin/gummyworm photo.jpg"
```

#### Build Custom Image

Create a `Dockerfile`:

```dockerfile
FROM alpine:latest

# Install dependencies
RUN apk add --no-cache \
    bash \
    imagemagick \
    curl \
    python3

# Install gummyworm
COPY . /opt/gummyworm
ENV PATH="/opt/gummyworm/bin:$PATH"
ENV GUMMYWORM_ROOT="/opt/gummyworm"

WORKDIR /work
ENTRYPOINT ["gummyworm"]
CMD ["--help"]
```

Build and use:

```bash
# Build the image
docker build -t gummyworm .

# Convert local image
docker run --rm -v "$(pwd):/work" gummyworm photo.jpg

# Convert with options
docker run --rm -v "$(pwd):/work" gummyworm -c -w 100 -p blocks photo.jpg

# Save output to file
docker run --rm -v "$(pwd):/work" gummyworm -c -f html photo.jpg > art.html

# Interactive shell for debugging
docker run --rm -it -v "$(pwd):/work" --entrypoint bash gummyworm
```

#### Docker Compose

For frequent use, create `docker-compose.yml`:

```yaml
version: '3'
services:
  gummyworm:
    build: .
    volumes:
      - ./images:/work
```

```bash
docker-compose run --rm gummyworm photo.jpg
docker-compose run --rm gummyworm -c -w 80 -p blocks photo.jpg
```

#### Volume Mounting Tips

| Host Path    | Container Path | Purpose                    |
| ------------ | -------------- | -------------------------- |
| `$(pwd)`     | `/work`        | Current directory          |
| `~/Pictures` | `/images:ro`   | Read-only access to photos |

```bash
# Access multiple directories
docker run --rm \
  -v "$(pwd):/work" \
  -v "$HOME/Pictures:/images:ro" \
  gummyworm /images/vacation/photo.jpg
```

## Verifying Installation

After installation, verify everything works:

```bash
# Check version
gummyworm --version
# Expected: gummyworm 2.1.1

# List available palettes
gummyworm --list-palettes

# Test with a sample image (if you have one)
gummyworm -w 40 photo.jpg

# Test with a URL
gummyworm -w 40 https://via.placeholder.com/150
```

## Shell Completions

gummyworm includes tab completion for bash and zsh.

### Homebrew Users

Completions are installed automatically. Just restart your shell or run:

```bash
# Bash
source $(brew --prefix)/etc/bash_completion.d/gummyworm

# Zsh (usually automatic)
autoload -Uz compinit && compinit
```

### Manual Installation

**Bash:**

```bash
# Add to ~/.bashrc
source /path/to/gummyworm/completions/gummyworm.bash
```

**Zsh:**

```zsh
# Add to ~/.zshrc (BEFORE compinit)
fpath=(/path/to/gummyworm/completions $fpath)
autoload -Uz compinit && compinit
```

See [Shell Completions](shell-completions.md) for more installation options.

### Test Completions

```bash
gummyworm --<TAB>     # Shows all options
gummyworm -p <TAB>    # Shows palette names
gummyworm -f <TAB>    # Shows format options
```

## Troubleshooting

### "command not found: gummyworm"

- Ensure gummyworm is in your PATH
- Try running with full path: `/path/to/gummyworm/bin/gummyworm`
- Reload your shell: `source ~/.bashrc`

### "ImageMagick not found" or "convert: command not found"

- Install ImageMagick for your platform (see above)
- Verify with: `which convert` or `convert --version`

### "bash: ./gummyworm: Permission denied"

- Make the script executable: `chmod +x gummyworm bin/gummyworm`

### Unicode/emoji palettes show wrong characters

- Ensure your terminal supports Unicode (UTF-8)
- Install Python 3 for better unicode width detection
- Use a font with emoji support (e.g., Noto Color Emoji)

See [Troubleshooting](troubleshooting.md) for more solutions.
