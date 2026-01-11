# Homebrew Distribution

gummyworm is distributed via a Homebrew tap at [oddurs/homebrew-gummyworm](https://github.com/oddurs/homebrew-gummyworm).

## For Users

### Install

```bash
brew install oddurs/gummyworm/gummyworm
```

This installs:
- The `gummyworm` executable
- ImageMagick dependency
- Shell completions for bash and zsh

### Upgrade

```bash
brew update && brew upgrade gummyworm
```

### Uninstall

```bash
brew uninstall gummyworm
brew untap oddurs/gummyworm  # optional
```

## For Maintainers

### Release Workflow

When releasing a new version:

1. **Tag the release in the main repo:**
   ```bash
   git tag -a v2.1.1 -m "Release v2.1.1"
   git push origin v2.1.1
   ```

2. **Get the SHA256 of the tarball:**
   ```bash
   curl -sL https://github.com/oddurs/gummyworm/archive/refs/tags/v2.1.1.tar.gz | shasum -a 256
   ```

3. **Update the formula:**

   Edit `Formula/gummyworm.rb`:
   ```ruby
   url "https://github.com/oddurs/gummyworm/archive/refs/tags/v2.1.1.tar.gz"
   sha256 "<new-sha256>"
   version "2.1.1"
   ```

4. **Update the tap repository:**
   ```bash
   # Copy formula to tap
   cp Formula/gummyworm.rb /opt/homebrew/Library/Taps/oddurs/homebrew-gummyworm/Formula/

   # Commit and push
   cd /opt/homebrew/Library/Taps/oddurs/homebrew-gummyworm
   git add Formula/gummyworm.rb
   git commit -m "Update gummyworm to v2.1.1"
   git push
   ```

5. **Don't forget to update version in lib/config.sh**

### Testing

```bash
# Test from HEAD (latest git)
brew install oddurs/gummyworm/gummyworm --HEAD

# Run formula tests
brew test gummyworm

# Reinstall from release tarball
brew uninstall gummyworm
brew install oddurs/gummyworm/gummyworm
```

### Formula Details

The formula (`Formula/gummyworm.rb`):
- Downloads the release tarball from GitHub
- Installs `bin/gummyworm` to Homebrew's bin directory
- Installs library files to `libexec/lib/`
- Installs palette files to `libexec/palettes/`
- Installs shell completions for bash and zsh
- Injects `GUMMYWORM_ROOT` path for Homebrew's directory structure
- Declares ImageMagick as a dependency

### Tap Repository

The tap lives at: https://github.com/oddurs/homebrew-gummyworm

Structure:
```
homebrew-gummyworm/
├── Formula/
│   └── gummyworm.rb
└── README.md
```
