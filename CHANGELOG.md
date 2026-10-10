# Changelog

All notable changes to gummyworm will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

The command now behaves the way command-line tools are expected to when piped,
scripted or run without a terminal. **Several behaviours change**; each is
listed under Changed.

### Changed
- **`-h` shows help; the height flag is now `-H`** (`--height` is unchanged).
  `-h <number>` still sets the height for now, with a deprecation warning, so
  existing scripts keep working.
- **Progress, success and warning messages go to standard error.** They used to
  go to standard output, so `gummyworm photo.jpg | pbcopy` copied the
  `Converting:` line along with the art. Standard output is now the art alone.
- **Usage errors exit with status 2**; runtime failures (a missing image, a
  failed conversion) still exit 1. Running with no input and a terminal on
  stdin prints a short usage line and exits 2 instead of dumping the help.
- **Piped output has no blank padding lines and no banner.** Those appear only
  on a terminal, so `gummyworm img > art.txt` is the art and nothing else, and
  `--list-palettes` is greppable.
- **Colour in help and messages follows the terminal and `NO_COLOR`.** Errors
  piped to a file no longer contain escape codes.

### Added
- `-V` as a short form of `--version`, and `-` to read the image from standard
  input.

### Fixed
- **`-f svg`, `html`, `ansi`, `png` and `gif` without `-o` printed plain text**
  and exited 0. They now write the requested format to standard output; `png`
  and `gif` refuse a terminal and write to a pipe or redirect.
- An unwritable `-o` path reported a raw bash redirection error with a library
  line number. It is now checked up front and reported plainly.
- A mistyped palette name such as `-p blokcs` silently rendered with its own
  letters. A plain word that names no palette now warns on standard error.

## [2.4.0] - 2026-10-09

Adds a way to measure how faithfully gummyworm renders an image, and the first
change made against that measurement. **Default output changes** for photos:
see `--enhance`. Also the first release to include the work after 2.3.1 that
had not been pushed: CI, `--` support and the module-loading rework below.

### Added
- **`--enhance <off|stretch|full>` and the `enhance` config key.** Before
  characters are chosen, the image's tones are now spread across the palette.
  Photos rarely use the full light-to-dark range, so they used to land on two
  or three characters. `full` (the default) stretches the range and then applies
  adaptive local contrast; `stretch` skips the local contrast; `off` restores
  the previous behaviour. Measured by the new `bench/` suite, `full` raises mean
  SSIM over the corpus from 0.5745 to 0.5792. It is not a win everywhere: flat
  graphics and thin line art can come out slightly worse, so use `--enhance off`
  for those. **Output for existing invocations changes** unless you set
  `enhance=off`.
- **`bench/`**, a rendering fidelity benchmark: a fixed 14-image corpus, an SSIM
  score per render, and a before/after comparison page.
- `--` ends option parsing, so a file named `-cover.png` can be passed. Everything
  after it is an input.
- CI runs the suite and shellcheck on every push to main and every pull request,
  on Ubuntu (ImageMagick 6) and macOS (the system bash 3.2).

### Fixed
- `calc_dimensions` no longer dies with a raw `division by 0` when ImageMagick
  reports an empty or zero source size. It reports the problem and returns, and
  `convert_to_ascii` passes that on. Not reachable from the CLI today, which
  validates images first.

### Changed
- Every module now loads its own dependencies, so any one of them can be sourced
  alone in a fresh shell, and sourcing `lib/config.sh` no longer reads the
  user's config files. `bin/gummyworm` and the tests share `lib/all.sh`. No
  change for people running the command.

## [2.3.1] - 2026-09-22

A security and correctness release. **Upgrade if you run gummyworm inside
directories you did not create** — see Security. Nothing here changes an
interface; every entry is a fix or a test.

### Security
- **A project `.gummywormrc` could execute arbitrary commands.** Config files
  are read from the current directory, and every value except `background` was
  used without validation. Numeric values reach shell arithmetic, where bash
  evaluates a variable's value as an expression — including array subscripts,
  which undergo command substitution. Running gummyworm inside a cloned
  repository or unpacked archive whose `.gummywormrc` contained, for example,
  `width=HOME[$(command)]` ran `command`. Exploitable through `width`,
  `height`, `padding`, `frame_delay` and `max_frames`; affects 2.2.0 through
  2.3.0. Every config value is now validated against the same rule as its
  command-line flag, and an invalid value is ignored with a warning.
- **`--background` could inject markup into exported HTML and SVG**, including
  from a config file. See Fixed.

### Fixed
- **Palette characters `|` and `\` no longer corrupt the output.** The palette
  was handed to awk as a `|`-joined string that awk split back on `|`, so a `|`
  in the palette was indistinguishable from a separator; `awk -v` also
  processes escape sequences, so a backslash was eaten before awk saw it. On
  top of that, the rendered art was printed with `echo -e`, which reinterpreted
  any backslash that did survive. The shipped `detailed` palette contains both
  characters, so `-p detailed` produced ragged rows — 19 and 20 characters wide
  where every row should have been 20 — and silently dropped three brightness
  bands. The palette now reaches awk as a file, one character per line, and the
  eleven `echo -e` calls that carried rendered art use `printf` instead.
- **Batch output no longer overwrites itself.** Output was named from the input
  basename alone, so two images called `image.png` in different directories
  both wrote to `out/image.ascii.html`. The run reported "2 images processed
  successfully" and exited 0 with one file on disk. A recursive batch now
  mirrors the input tree under `--output-dir`, and any remaining collision —
  two files named directly from different directories, say — is reported and
  written as `image-2.ascii.html` rather than silently replacing the first.
  A directory walked non-recursively still lands flat, as before.
- **`--background` is validated and escaped.** Any string was previously
  accepted and interpolated straight into the generated SVG and HTML. A value
  carrying markup ended up in the exported file verbatim. The value now has to
  be a hex colour (`#RGB` or `#RRGGBB`) or a known colour name, and both
  exporters escape it regardless — so a caller that skips validation cannot
  reintroduce the problem. This also applies to the `background=` key in a
  config file, which matters more: `./.gummywormrc` travels with a cloned
  repository, so that value does not come from the person running the command.
- **The test runner discarded most failing assertions.** A test was judged by
  errexit inside a subshell, but the suite calls each test as
  `run_test ... || true`, and bash suppresses errexit for everything inside an
  `&&`/`||` list. A failing assertion that was not the last line of its test
  printed `ASSERTION FAILED` and the test still reported PASS. 154 of the
  suite's 384 assertions — 40% — were never enforced. Assertions now record
  failures in a counter the runner reads, which does not depend on the call
  site. Turning enforcement on surfaced exactly one real failure, fixed below.
- `is_valid_hex_color` was called by the zsh compatibility suite but defined
  nowhere in `lib/` or `bin/`. It now exists, alongside `is_valid_color`.
- **An input that yields no images is reported as such.** A directory argument
  containing no images fell through to the stdin path and failed with
  "Stdin does not contain valid image data". It now fails with "No images
  found in the given input". Stdin is used only when no input is named.
- **`scripts/release.sh` hashes the file the formula actually downloads.** It
  built its own tarball from the working tree and hashed that, then wrote the
  hash beside GitHub's archive URL — so the formula it produced could never
  pass Homebrew's checksum. It now requires the tag to be pushed, hashes
  GitHub's archive for it, and refuses rather than guessing.
- **The Homebrew formula is current.** It was still pinned to v2.2.0, so
  `brew install` did not deliver v2.3.0. It now points at v2.3.0; run
  `scripts/release.sh 2.3.1` once this release's tag is pushed.

### Added
- `tests/test_cli.sh`: 21 tests covering `parse_args` directly — per-flag
  validation, inclusive range boundaries at both ends, missing arguments,
  unknown options, config/CLI precedence, and positional collection. The
  425-line parser previously had no dedicated tests.
- Background colour validation and escaping tests in the config and export
  suites.
- 12 regression tests covering palette character preservation (by character,
  not byte — several palettes are multi-byte UTF-8) and batch output naming.
- `tests/test_release.sh`: offline tests for every case `release.sh` must
  refuse.
- Config validation tests for every key, including an end-to-end test that
  runs the binary against a malicious `.gummywormrc`.

The suite now runs 10 files and 346 tests, all enforced.

## [2.3.0] - 2026-09-20

### Fixed
- **Output proportions.** Character cell aspect was hardcoded to 2.2:1, so
  output rendered about 11% wider than it should be — a circle came out as a
  flattened ellipse. The assumed ratio is now 2.0:1, matching a typical
  monospace cell. A 400×400 circle at `-w 80` was an 80×36 grid and is now
  80×40.
- Row count now rounds half up instead of truncating, which silently dropped
  most of a row.
- HTML and SVG export no longer carry their own separate `7.2`/`14.4` font
  metrics. Both derive from the same ratio as the conversion, so exported files
  match the terminal. A square source now exports a square canvas (576×576,
  previously 576×518.4).
- **PNG and GIF export.** These render SVG and rasterise it, which needs a
  renderer ImageMagick does not install alongside itself. gummyworm now checks
  before doing any work and names the fix, instead of failing at the end with
  `Failed to convert SVG to PNG`. Rasterisation calls `rsvg-convert` directly,
  which also fixes an `unable to read font` failure on stock macOS ImageMagick.

### Added
- **`--char-aspect <N>` option** and `char_aspect` config key: set the terminal
  cell height:width ratio to match your terminal. Try `1.67` for tight line
  spacing, `2.2` for loose. Range 0.5–5.0, default 2.0. Applies to exports too.
- Shell completions for `--char-aspect` in bash and zsh.
- 4 new dimension tests, including ones pinning the default ratio and the
  rounding behaviour — the previous tests asserted only that height was
  positive, which is why the wrong ratio went unnoticed.

### Changed
- Default output dimensions change for every image. Output is roughly 11%
  taller in rows than before at the same width. Pass `--char-aspect 2.2` to
  restore the previous behaviour exactly.
- Documented `librsvg` as an optional dependency for `png` and `gif` export.

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
| 2.4.0 | 2026-10-09 | `--enhance` tone enhancement (default changes output for photos), `bench/` fidelity benchmark, `--` support, CI |
| 2.3.1 | 2026-09-22 | Security: config command injection, background escaping; palette, batch and test runner fixes |
| 2.3.0 | 2026-09-20 | Correct output proportions, `--char-aspect`, PNG/GIF export fixes |
| 2.2.0 | 2026-01-11 | Configuration files, shell completions, Docsify docs |
| 2.1.0 | 2026-01-11 | Animation, true color, zsh support, preprocessing, modular palettes |
| 2.0.0 | 2024-12-01 | Multi-format export, batch processing, modular rewrite |
| 1.0.0 | 2024-06-01 | Initial release |

[Unreleased]: https://github.com/oddurs/gummyworm/compare/v2.4.0...HEAD
[2.4.0]: https://github.com/oddurs/gummyworm/compare/v2.3.1...v2.4.0
[2.3.1]: https://github.com/oddurs/gummyworm/compare/v2.3.0...v2.3.1
[2.3.0]: https://github.com/oddurs/gummyworm/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/oddurs/gummyworm/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/oddurs/gummyworm/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/oddurs/gummyworm/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/oddurs/gummyworm/releases/tag/v1.0.0
