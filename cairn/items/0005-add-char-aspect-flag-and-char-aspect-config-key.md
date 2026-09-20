---
id: 5
title: Add --char-aspect flag and char_aspect config key
type: feature
status: done
milestone: v2.3.0
assignee: Oddur Sigurdsson
depends_on:
- 4
created: 2026-09-19
updated: 2026-09-19
priority: p2
effort: s
area: cli
---

## Problem

No single default is right for every terminal. The cell ratio depends on the font's
advance width and the terminal's line height, and the spread in practice is wide:

| setup | approx cell ratio |
|---|---|
| iTerm2, line-height 1.0 | ~1.67 |
| Courier New / most monospace at line-height 1.2 | 2.00 |
| looser line spacing | 2.2+ |

A default of 2.0 (0004) is right for the common case but leaves the tails visibly off.
People running a tight or loose line-height need to say so.

## Proposal

`--char-aspect <N>` on the CLI, plus a `char_aspect` key in `.gummywormrc`, threaded
into the parameter `calc_dimensions` grows in 0004. Float accepted, e.g. `1.67`.

Config plumbing follows the existing pattern in `lib/config.sh`: a `DEFAULT_CHAR_ASPECT`
alongside `DEFAULT_WIDTH`/`DEFAULT_HEIGHT`, a `CONFIG_CHAR_ASPECT`, a parse arm in the
rc reader near `preserve_aspect`, and an entry in the `export` list.

Document it in `--help` and in `.gummywormrc.example`, with the table above or similar,
since the number is meaningless without knowing what it describes.

## Acceptance criteria

- [x] `--char-aspect <N>` accepted and validated (reject <= 0 and non-numeric)
- [x] `char_aspect` readable from `.gummywormrc`
- [x] CLI flag overrides the config file
- [x] Documented in `--help` and `.gummywormrc.example`

## 2026-09-19

Flag lands in lib/cli.sh with the same validate-then-range-check-in-awk shape as --gamma; range 0.5-5.0. Config key wired through lib/config.sh (DEFAULT_CHAR_ASPECT / CONFIG_CHAR_ASPECT / rc parse arm / export). Rather than thread a 12th positional through convert_to_ascii, parse_args publishes the resolved value back to CONFIG_CHAR_ASPECT, which calc_dimensions and the exporter already read. Verified precedence: default 40 rows, rc 1.67 gives 48, CLI 2.2 overrides rc to 36.
