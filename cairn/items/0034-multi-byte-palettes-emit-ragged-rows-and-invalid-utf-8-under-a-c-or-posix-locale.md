---
id: 34
uid: 5caabbb8-4fb2-4678-ac7e-54048c941e15
title: Multi-byte palettes emit ragged rows and invalid UTF-8 under a C or POSIX locale
type: bug
status: backlog
milestone: later
created: 2026-09-22
updated: 2026-09-22
priority: p2
effort: m
area: palettes
---

## What happens

```
LC_ALL=en_US.UTF-8  -p blocks  -> widths [20]              valid UTF-8
LC_ALL=C.UTF-8      -p blocks  -> widths [20]              valid UTF-8
LC_ALL=C            -p blocks  -> widths [16,17,18,19,20]  invalid UTF-8
LC_ALL=POSIX        -p blocks  -> widths [16,17,18,19,20]  invalid UTF-8
```

Under a non-UTF-8 locale, multi-byte palettes (`blocks`, the emoji palettes)
produce ragged rows, and the output contains split byte sequences that are not
valid UTF-8.

## Why

`palette_to_array` (`lib/palettes.sh`) picks its fast path by comparing a byte
count to `${#palette}`. bash computes `${#palette}` in the current locale: under
C or POSIX it counts bytes, so the two match, the palette is judged pure ASCII,
and it is split one *byte* at a time. Other width calculations that use
`${#...}` or `wc -m` share the same locale dependence.

## Why it matters

C/POSIX is the default in cron, many Docker base images, CI containers, and SSH
sessions that do not forward `LANG`. Those are exactly the batch and scripted
contexts the tool's `-d` / `-r` features are for.

## Found while

Setting up CI (`0026`). The workflow pins a UTF-8 locale so the suite tests the
configuration an interactive user has; this item is the product fix, and should
remove that pin's necessity by adding a C-locale job.

## Direction

Decide ASCII-ness from bytes (`LC_ALL=C grep` for any byte >= 0x80) rather than
from `${#palette}`, and split non-ASCII palettes with a locale-independent tool
— Python 3.7+ enables UTF-8 mode under the C locale, so the existing Python
path already does this once it is reached.

## Acceptance criteria

- [ ] `-p blocks` renders uniform rows and valid UTF-8 under LC_ALL=C and LC_ALL=POSIX
- [ ] ASCII palettes are unaffected in every locale
- [ ] A test runs a multi-byte palette under LC_ALL=C
- [ ] CI gains a C-locale job
