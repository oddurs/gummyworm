---
id: 28
title: SVG and HTML export spawn two processes per output row
type: chore
status: backlog
milestone: v2.4.0
depends_on:
- 26
created: 2026-09-22
updated: 2026-09-22
priority: p2
effort: m
area: export
---

## What happens

`convert_to_ascii` makes a single awk pass over every pixel, which is why text
output is fast. The export layer then walks the rendered art one row at a time
and spawns processes per row:

- `lib/export.sh:314` — `printf | sed` per row, just to strip ANSI for a width count
- `lib/export.sh:370` — `_svg_render_line` runs `printf | awk` per row

That is two subprocesses per row, so export time grows linearly with height.

## Measured

400x400 source, `-c` so no re-conversion is involved:

```
width  rows   text(ms)  svg(ms)   svg/text
   25    13        76      175     2.3x
   50    25        91      277     3.0x
  100    50        98      435     4.4x
  200   100       178     1045     5.9x
```

Text grows ~2.3x for 8x the pixels. SVG grows ~6x for 8x the rows, and the
ratio widens monotonically — the signature of per-row process spawning.

## The double conversion, for scale

`get_export_content` (`bin/gummyworm:200`) re-runs `convert_to_ascii` with
colour on for graphical formats when `-c` was not given, so the image is
converted twice. That is real but costs ~85ms of 509ms at `-w 100`. The
per-row spawning is the dominant cost; fix that first, and fold the double
conversion in only if it stays simple — for instance by always converting
with colour and stripping for text.

## Direction

The converter already shows the pattern: one awk program over the whole
rendered art, computing max width and emitting every `<text>` element in a
single pass.

## Acceptance criteria

- [ ] SVG and HTML export make a constant number of subprocess calls regardless of row count
- [ ] SVG export at `-w 200` is within 2x of text output time on the same image
- [ ] Output is byte-identical to the current exporter for the existing export tests
- [ ] A test pins the subprocess count or the timing ratio so a regression is caught
