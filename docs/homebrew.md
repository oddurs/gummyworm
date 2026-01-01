# Homebrew Distribution

This document explains how to distribute gummyworm via Homebrew.

## Option 1: Homebrew Tap (Recommended)

A Homebrew tap is a separate GitHub repository that contains your formula.

### Setup Your Tap

1. **Create a new GitHub repository** named `homebrew-gummyworm`
   - The repo must be named `homebrew-<something>` for Homebrew to recognize it

2. **Add the formula to your tap:**
   ```bash
   # Clone your tap repo
   git clone https://github.com/oddurs/homebrew-gummyworm.git
   cd homebrew-gummyworm
   
   # Create Formula directory
   mkdir -p Formula
   
   # Copy the formula
   cp /path/to/gummyworm/Formula/gummyworm.rb Formula/
   
   # Commit and push
   git add Formula/gummyworm.rb
   git commit -m "Add gummyworm formula"
   git push
   ```

3. **Users can then install with:**
   ```bash
   brew tap oddurs/gummyworm
   brew install gummyworm
   ```

### Creating a Release

1. **Tag a release in the main gummyworm repo:**
   ```bash
   cd gummyworm
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Create a GitHub Release:**
   - Go to your GitHub repo → Releases → Create new release
   - Choose the tag you just pushed
   - GitHub automatically creates a source tarball

3. **Get the SHA256:**
   ```bash
   # Download the tarball from GitHub
   curl -L -o gummyworm-1.0.0.tar.gz \
     https://github.com/oddurs/gummyworm/archive/refs/tags/v1.0.0.tar.gz
   
   # Calculate SHA256
   shasum -a 256 gummyworm-1.0.0.tar.gz
   ```

4. **Update the formula in your tap:**
   ```ruby
   class Gummyworm < Formula
     url "https://github.com/oddurs/gummyworm/archive/refs/tags/v1.0.0.tar.gz"
     sha256 "YOUR_ACTUAL_SHA256_HERE"
     # ...
   end
   ```

5. **Push the updated formula**

## Option 2: Local Development Testing

Test the formula locally before publishing:

```bash
# Install from local formula
brew install --formula ./Formula/gummyworm.rb

# Or install from HEAD (latest git)
brew install --HEAD ./Formula/gummyworm.rb

# Uninstall
brew uninstall gummyworm
```

## Option 3: Homebrew Core (Advanced)

For popular projects, you can submit to homebrew-core:

1. Fork https://github.com/Homebrew/homebrew-core
2. Add your formula to Formula/g/gummyworm.rb
3. Submit a pull request
4. Meet Homebrew's requirements (popularity, maintenance, etc.)

## Release Workflow

Use the included release script:

```bash
# Create a release
./scripts/release.sh 1.0.0

# This will:
# - Create a tarball
# - Calculate SHA256  
# - Update Formula/gummyworm.rb
```

Then follow the printed instructions to push tags and update your tap.

## Testing Your Formula

```bash
# Audit the formula for issues
brew audit --strict Formula/gummyworm.rb

# Test the formula
brew test gummyworm

# Check for style issues
brew style Formula/gummyworm.rb
```

## Formula Reference

The formula does the following:
- Downloads the release tarball
- Installs the `gummyworm` executable to `bin/`
- Installs library files to `libexec/lib/`
- Installs palettes to `libexec/palettes/`
- Rewrites paths so everything works from the installed location
- Declares ImageMagick as a dependency
