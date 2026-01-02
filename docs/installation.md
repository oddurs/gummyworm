# Installation

This guide covers all methods for installing gummyworm on your system.

## Platform Compatibility

gummyworm is designed for maximum compatibility across Unix-like systems:

| Platform | Status | Shell Required |
|----------|--------|----------------|
| macOS 10.6+ | ✅ Tested | Bash 3.2+ (default) |
| Ubuntu/Debian | ✅ Tested | Bash 4+ |
| Fedora/RHEL | ✅ Tested | Bash 4+ |
| Arch Linux | ✅ Tested | Bash 5+ |
| FreeBSD | ✅ Compatible | Bash 3.2+ |
| Alpine Linux | ✅ Compatible | Bash 5+ |
| Windows (WSL) | ✅ Tested | Bash 4+ |
| Windows (Git Bash) | ⚠️ Limited | Bash 4+ |

**Note**: gummyworm specifically supports Bash 3.2 (the default macOS version) to ensure wide compatibility without requiring users to upgrade their shell.

## Quick Install (Homebrew)

The easiest way to install gummyworm on macOS or Linux:

```bash
# Add the tap (first time only)
brew tap oddurs/gummyworm

# Install gummyworm
brew install gummyworm
```

This automatically installs ImageMagick as a dependency.

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

| Dependency | Required | Purpose |
|------------|----------|---------|
| **Bash 3.2+** | Yes | Shell interpreter (macOS default works!) |
| **ImageMagick** | Yes | Image processing and pixel extraction |
| **Python 3** | No | Better Unicode/emoji character width detection |
| **curl or wget** | No | URL image downloads |

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
- **Bash version:** macOS ships with Bash 3.2 by default. gummyworm requires Bash 4.0+. If using manual installation, install a newer Bash:
  ```bash
  brew install bash
  # Then use /opt/homebrew/bin/bash (Apple Silicon) or /usr/local/bin/bash (Intel)
  ```

### Linux

- Works on any distribution with Bash 4.0+ and ImageMagick.
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

Run gummyworm in a container:

```dockerfile
FROM alpine:latest
RUN apk add --no-cache bash imagemagick curl
COPY . /opt/gummyworm
ENV PATH="/opt/gummyworm/bin:$PATH"
ENTRYPOINT ["gummyworm"]
```

```bash
docker build -t gummyworm .
docker run --rm -v "$(pwd)/images:/images" gummyworm /images/photo.jpg
```

## Verifying Installation

After installation, verify everything works:

```bash
# Check version
gummyworm --version
# Expected: gummyworm 2.0.0

# List available palettes
gummyworm --list-palettes

# Test with a sample image (if you have one)
gummyworm -w 40 photo.jpg

# Test with a URL
gummyworm -w 40 https://via.placeholder.com/150
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

---

← [Back to README](../README.md) | [CLI Reference](cli-reference.md) →
