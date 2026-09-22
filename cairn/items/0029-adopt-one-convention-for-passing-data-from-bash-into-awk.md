---
id: 29
title: Adopt one convention for passing data from bash into awk
type: chore
status: backlog
milestone: v2.4.0
depends_on:
- 26
created: 2026-09-22
updated: 2026-09-22
priority: p2
effort: m
area: architecture
---

## What happens

awk is the compute kernel for conversion and export, and data reaches it
several different ways:

- `awk -v name="$value"` — awk processes escape sequences in the value, so a
  backslash in data is consumed or reinterpreted
- delimiter-joined strings split inside awk — ambiguous whenever the data can
  contain the delimiter
- awk source built inside a double-quoted shell string, so the shell expands
  `$` and backticks in the program text before awk sees it —
  `$AWK_ANSI256_TO_RGB` is interpolated this way into several programs in
  `lib/export.sh`

## Why it matters

The first two each produced a shipped bug, both in `0017`: the `detailed`
palette's `\` was eaten by `-v` and its `|` collided with the delimiter.
`0017` fixed the palette by passing it through a file, but that closed one
instance, not the class. Every other `-v` carrying data is the same hazard
waiting for an input that exercises it.

## Direction

- **Data** reaches awk through a file or `ENVIRON`, never `-v`. `-v` is fine for
  values the program controls — numbers, flags, format names — and nothing else.
- **Programs** are single-quoted so the shell never touches them. Shared awk
  helpers like `AWK_ANSI256_TO_RGB` go in via `-f` with a helper file, or are
  concatenated before a single-quoted body, rather than expanded inside one.

Write the rule down at the top of `lib/converter.sh` and `lib/export.sh`, where
the next person adding an awk call will see it.

## Acceptance criteria

- [ ] Every awk call is audited and listed with how each input arrives
- [ ] No user- or file-derived data is passed with `-v`
- [ ] No awk program is built inside a double-quoted shell string
- [ ] The convention is documented where awk is used
- [ ] Tests push `\`, `|`, `$` and a backtick through each awk-backed path
