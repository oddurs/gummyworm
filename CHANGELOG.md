# Changelog

All notable changes to gummyworm will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
| 2.0.0 | 2024-12-01 | Multi-format export, batch processing, modular rewrite |
| 1.0.0 | 2024-06-01 | Initial release |

[Unreleased]: https://github.com/oddurs/gummyworm/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/oddurs/gummyworm/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/oddurs/gummyworm/releases/tag/v1.0.0
