---
sidebar_position: 12
title: Shell Completions
---

# Shell Completions

Tab completion for bash and zsh makes using gummyworm faster and helps discover options.

## Features

- Complete all command-line options (`--<TAB>`)
- Complete built-in palette names (`-p <TAB>`)
- Complete output formats (`-f <TAB>`)
- Complete image files (jpg, png, gif, bmp, tiff, webp)
- Complete directories for `-d`/`--output-dir`
- Suggest common values for `--brightness`, `--contrast`, `--gamma`, `--background`

## Quick Setup

### Homebrew Users (Automatic)

If you installed via `brew install oddurs/gummyworm/gummyworm`, completions are already available. Just restart your terminal or run:

```bash
# Bash
source $(brew --prefix)/etc/bash_completion.d/gummyworm

# Zsh (usually automatic)
autoload -Uz compinit && compinit
```

### Manual Installation

**Bash:**

Add to `~/.bashrc` or `~/.bash_profile`:

```bash
source /path/to/gummyworm/completions/gummyworm.bash
```

Or install system-wide:

```bash
# Linux
sudo cp completions/gummyworm.bash /etc/bash_completion.d/gummyworm

# macOS (with bash-completion installed)
cp completions/gummyworm.bash $(brew --prefix)/etc/bash_completion.d/
```

**Zsh:**

Add to `~/.zshrc` **before** `compinit`:

```zsh
fpath=(/path/to/gummyworm/completions $fpath)
autoload -Uz compinit && compinit
```

Or install system-wide:

```bash
# Linux
sudo cp completions/_gummyworm /usr/local/share/zsh/site-functions/

# macOS
cp completions/_gummyworm $(brew --prefix)/share/zsh/site-functions/
```

**Oh My Zsh:**

```bash
cp completions/_gummyworm ~/.oh-my-zsh/completions/
```

## Verify It Works

After installation, open a new terminal and try:

```bash
gummyworm --<TAB>      # Shows all options
gummyworm -p <TAB>     # Shows palette names
gummyworm -f <TAB>     # Shows format options
gummyworm photo.<TAB>  # Completes image files
```

## Troubleshooting

### Bash completions not working

1. Ensure bash-completion is installed:

   ```bash
   # macOS
   brew install bash-completion@2

   # Ubuntu/Debian
   sudo apt install bash-completion
   ```

2. Ensure it's sourced in your shell config:
   ```bash
   # Add to ~/.bashrc
   [[ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]] && \
       source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
   ```

### Zsh completions not working

1. Ensure compinit is initialized:

   ```zsh
   autoload -Uz compinit && compinit
   ```

2. Rebuild completion cache:

   ```zsh
   rm -f ~/.zcompdump && compinit
   ```

3. Check fpath includes the completions directory:
   ```zsh
   echo $fpath | tr ' ' '\n' | grep gummyworm
   ```
