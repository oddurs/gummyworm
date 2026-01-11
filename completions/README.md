# Shell Completions for gummyworm

Tab completion scripts for bash and zsh.

## Features

- Complete all command-line options
- Complete built-in palette names with descriptions
- Complete output formats with descriptions
- Complete image files (jpg, png, gif, bmp, tiff, webp)
- Complete directories for `-d`/`--output-dir`
- Suggest common values for `--brightness`, `--contrast`, `--gamma`, `--background`

## Installation

### Bash

**Option 1: Source in your shell config**

Add to `~/.bashrc` or `~/.bash_profile`:

```bash
source /path/to/gummyworm/completions/gummyworm.bash
```

**Option 2: System-wide installation**

```bash
# Linux
sudo cp completions/gummyworm.bash /etc/bash_completion.d/gummyworm

# macOS (with bash-completion installed)
cp completions/gummyworm.bash $(brew --prefix)/etc/bash_completion.d/
```

**Option 3: Homebrew (automatic)**

If you installed via Homebrew, completions are automatically available.

### Zsh

**Option 1: Add to fpath**

Add to `~/.zshrc` **before** `compinit`:

```zsh
fpath=(/path/to/gummyworm/completions $fpath)
autoload -Uz compinit && compinit
```

**Option 2: System-wide installation**

```bash
# Linux
sudo cp completions/_gummyworm /usr/local/share/zsh/site-functions/

# macOS
cp completions/_gummyworm $(brew --prefix)/share/zsh/site-functions/
```

**Option 3: Oh My Zsh**

```bash
cp completions/_gummyworm ~/.oh-my-zsh/completions/
```

Then add to `~/.zshrc`:

```zsh
autoload -Uz compinit && compinit
```

**Option 4: Homebrew (automatic)**

If you installed via Homebrew, completions are automatically available.

## Verifying Installation

After installation, open a new terminal and try:

```bash
gummyworm --<TAB>      # Should show all options
gummyworm -p <TAB>     # Should show palette names
gummyworm -f <TAB>     # Should show format options
gummyworm photo.<TAB>  # Should complete image files
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
   [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && \
       source "/opt/homebrew/etc/profile.d/bash_completion.sh"
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
