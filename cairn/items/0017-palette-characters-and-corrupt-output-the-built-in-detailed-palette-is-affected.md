---
id: 17
uid: 5010e3fc-c122-46e8-9076-e758e7441b63
title: Palette characters | and \ corrupt output; the built-in 'detailed' palette is affected
type: bug
status: done
milestone: v2.3.1
assignee: Oddur Sigurdsson
created: 2026-09-21
updated: 2026-09-22
priority: p1
effort: m
area: converter
---

## What happens

`convert_to_ascii` joins the palette's characters into one string separated by
`|` (`lib/converter.sh:112-118`) and hands it to awk, which splits it back on
`|` (`lib/converter.sh:133`). Any `|` *in* the palette is therefore
indistinguishable from a separator. Separately, `awk -v` processes escape
sequences in the value it is given, so a backslash in the palette is eaten
before awk ever sees it.

The brightness-to-character index is computed from `palette_len`, counted in
bash, while the array awk indexes into comes from its own `split`. When the two
disagree, characters map to the wrong brightness band and some bands map to an
empty string, which emits nothing.

Measured on the shipped `detailed` palette:

```
bash palette_len      : 71
awk split element cnt : 72
mismatch              : 1 element(s)
empty elements in awk : 3   (each renders as a missing character)
```

## Why it matters

This is not only a custom-palette edge case. `palettes/detailed.palette` ships
with both characters:

```
 .'°`^",:;Il!i><~+_-?][}{1)(|\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$
```

so `gummyworm -p detailed` produces structurally broken output. Rows are ragged
where every row should be exactly the requested width:

```
-w 20, char widths per row
  standard   [20]
  detailed   [19, 20]     <- ragged
  blocks     [20]
  simple     [20]
```

A custom palette shows it more starkly — `-p " .|oO@"` at `-w 14` gives rows of
10, 12, 12, 14, 13, 12 and 8 characters, and never emits `@` at all.

There is no error and no warning; the output is simply wrong.

`--palette` is documented as accepting "any string of characters"
(`lib/cli.sh:155-156`), so `|` and `\` are within the contract.

## Measuring this

Count characters, not bytes. `detailed` contains `°` and `blocks` is made of
multi-byte block characters, so `awk length()` and `wc -c` both overstate row
width and make correct palettes look broken. `blocks` is fine.

## Direction

The separator has to be one that cannot occur in a palette, or the encoding has
to stop being ambiguous — passing the characters to awk through a file or as
`ENVIRON` avoids both the delimiter collision and `-v` escape processing.
Whatever is chosen, awk's element count and bash's `palette_len` must be the
same number, and it is worth asserting that they are.

## Acceptance criteria

- [x] A palette containing `|` renders every row at the requested width
- [x] A palette containing `\` renders every row at the requested width
- [x] `-p detailed` renders every row at the requested width
- [x] No palette character is silently dropped
- [x] Tests cover `|`, `\`, and the `detailed` built-in, counting characters rather than bytes

## 2026-09-21

Two independent root causes, not one. First, the |-joined string passed to awk with -v: | is ambiguous when the palette contains it, and awk -v processes escape sequences so backslashes were eaten before awk saw them. Fixed by handing the palette to awk as a file, one character per line, and indexing off awk's own count with a mismatch guard. Second, the rendered art was printed with 'echo -e' in 5 places in bin/gummyworm and 6 in lib/export.sh, which reinterpreted any backslash the palette produced. convert_to_ascii already emits real ESC bytes (verified with od -c: zero literal backslash-033), so -e was pure liability; all 11 sites now use printf '%s\n'. Fixing only the first left custom backslash palettes still ragged, which is how the second was found.
