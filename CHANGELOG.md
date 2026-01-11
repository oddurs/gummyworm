# Changelog

All notable changes to gummyworm will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.0] - 2026-01-11

### Added
- **Configuration file support:** Set default options in `~/.gummywormrc`
- Load config from `~/.config/gummyworm/config`, `~/.gummywormrc`, or `./.gummywormrc`
- Project-specific configs override user defaults; CLI args override all
- Example config template at `.gummywormrc.example`
- 9 new configuration tests
- **Shell completions:** Tab completion for bash and zsh
- Completions for all CLI options, palettes, formats, and image files
- Automatic installation via Homebrew
- **Docsify documentation site** at GitHub Pages

## [2.1.0] - 2026-01-11

### Added
- **zsh support:** Full compatibility with zsh 5.0+ alongside bash 3.2+
- Shell detection utilities (`_is_bash()`, `_is_zsh()`) for portable scripting
- Portable `_script_source()` function replacing bash-specific `BASH_SOURCE`
- 15 new zsh-specific compatibility tests in `tests/test_zsh_compat.sh`
- **Modular palette system:** All 12 built-in palettes now stored as individual `.palette` files in `palettes/` folder
- **Palette metadata support:** `.palette` files support optional headers (`# Name:`, `# Description:`, `# Author:`, `# Tags:`)
- **Palette template:** New `palettes/_template.palette` as starting point for custom palettes
- **Palette documentation:** New `palettes/README.md` with format specification and examples
- `palette_get_metadata()` function for reading palette file headers
- `palette_description()` function for unified description access
- 10 new palette metadata tests
- **Image preprocessing options:** Adjust brightness, contrast, and gamma before conversion
- **`--brightness <N>` option:** Adjust image brightness from -100 (darker) to 100 (brighter)
- **`--contrast <N>` option:** Adjust image contrast from -100 (lower) to 100 (higher)
- **`--gamma <N>` option:** Apply gamma correction (e.g., 0.5, 1.0, 2.2) for non-linear brightness adjustment
- 9 new preprocessing-related unit tests
- **Animated GIF support:** Process animated GIFs frame-by-frame with new animation options
- **Terminal animation playback:** Play animated GIFs as ASCII art directly in the terminal with `-a` flag
- **GIF export format:** Export animated ASCII art as GIF files with `-f gif`
- **`-a, --animate` flag:** Enable animation processing for animated inputs
- **`--no-animate` flag:** Disable animation, use first frame only
- **`--frame-delay <N>` option:** Set delay between frames in milliseconds for playback/export
- **`--max-frames <N>` option:** Limit the number of frames to process
- **`--loops <N>` option:** Set loop count for animation playback/export (0 = infinite)
- Animation detection functions: `image_is_animated()`, `image_frame_count()`, `image_get_delays()`, `image_extract_frames()`
- Animated GIF export function: `export_animated_gif()`
- Frame extraction with `-coalesce` for proper frame handling
- Graceful Ctrl+C handling during animation playback
- Test fixture `tests/fixtures/animated_test.gif` for animation tests
- 12 new animation-related unit tests
- **True color (24-bit RGB) support:** New `--truecolor` flag enables full RGB color output (`\e[38;2;r;g;bm` sequences), preserving exact colors from the source image
- **Auto-detection of true color terminals:** When using `-c`, gummyworm automatically enables true color if `$COLORTERM` is set to `truecolor` or `24bit`
- **`--no-truecolor` flag:** Force 256-color mode even when terminal supports true color
- True color parsing in HTML and SVG exports for exact color reproduction
- Expanded documentation with linkable markdown files
- Documentation index at `docs/README.md`
- Installation guide (`docs/installation.md`)
- CLI reference (`docs/cli-reference.md`)
- Palettes guide (`docs/palettes.md`)
- Export formats guide (`docs/export-formats.md`)
- Examples collection (`docs/examples.md`)
- Troubleshooting guide (`docs/troubleshooting.md`)
- Architecture documentation (`docs/architecture.md`)
- Contributing guidelines (`CONTRIBUTING.md`)

### Changed
- Updated documentation to reflect zsh support alongside bash
- Replaced `[[:ascii:]]` regex patterns with portable byte-count comparisons
- Prioritized Python over awk for Unicode character splitting (fixes macOS awk UTF-8 issues)

## [2.0.0] - 2024-12-01

### Added
- **Multi-format export:** HTML, SVG, PNG output formats
- **Batch processing:** Process multiple files at once
- **Recursive directories:** `-r` flag to process folder trees
- **URL support:** Download and convert images from URLs
- **Stdin piping:** Pipe image data directly to gummyworm
- **Output directory:** `-d` flag for auto-named output files
- **Background color:** `--background` option for exports
- **Continue on error:** `--continue-on-error` for batch resilience
- **Format auto-detection:** Detect format from output file extension
- New palettes: `dots`, `stars`, `hearts`
- Modular architecture with separate library files
- Homebrew tap distribution

### Changed
- Complete rewrite with modular architecture
- Improved color accuracy in 256-color mode
- Better aspect ratio calculation
- Enhanced error messages and logging

### Fixed
- Unicode character width calculation
- Aspect ratio preservation for wide images
- Color output on various terminal emulators

## [1.0.0] - 2024-06-01

### Added
- Initial release
- Basic image to ASCII conversion
- 256-color ANSI output
- 9 built-in palettes (standard, detailed, simple, blocks, binary, shades, retro, matrix, emoji)
- Custom palette support (inline and file-based)
- Width and height control
- Aspect ratio preservation
- Invert mode for dark images
- File output with `-o` flag
- Quiet mode

### Dependencies
- Bash 4.0+
- ImageMagick

---

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| 2.2.0 | 2026-01-11 | Configuration files, shell completions, Docsify docs |
| 2.1.0 | 2026-01-11 | Animation, true color, zsh support, preprocessing, modular palettes |
| 2.0.0 | 2024-12-01 | Multi-format export, batch processing, modular rewrite |
| 1.0.0 | 2024-06-01 | Initial release |

[Unreleased]: https://github.com/oddurs/gummyworm/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/oddurs/gummyworm/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/oddurs/gummyworm/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/oddurs/gummyworm/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/oddurs/gummyworm/releases/tag/v1.0.0
