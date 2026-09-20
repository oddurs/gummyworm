---
id: 6
title: SVG/HTML export hardcodes its own 7.2/14.4 font metrics, duplicating the aspect constant
type: bug
status: done
milestone: v2.3.0
assignee: Oddur Sigurdsson
depends_on:
- 4
created: 2026-09-19
updated: 2026-09-19
priority: p2
effort: s
area: export
---

## What happens

The converter and the exporter each carry their own idea of character cell shape, and
they disagree.

`lib/export.sh:255` — SVG:

```bash
# char_width=7.2, line_height=14.4
local char_width_x10=72    # 7.2 * 10
local line_height_x10=144  # 14.4 * 10
```

`lib/export.sh:132` — HTML:

```css
font-size: 12px;
line-height: 1.2;
```

Both come to exactly 2.0:1 (Courier New's 0.6em advance at 12px = 7.2px; 12 x 1.2 =
14.4px). The converter meanwhile builds the grid for 2.2:1 (0004). So the grid is
generated for one cell shape and painted at another, and every exported example is
wrong by that 10% — which is what makes the error visible on the website rather than
just in a terminal.

The export side is internally consistent and matches its own CSS. It is the converter
that is wrong. But the constant living in two places is what let them drift, and will
again.

## What should happen

One source of truth. Export derives its `line_height` from the same ratio value the
converter uses — `char_width * ratio` — rather than restating `14.4`. Once 0005 lands,
a non-default `--char-aspect` should change the exported SVG/HTML geometry too, so
terminal preview and exported file agree.

Note the HTML path expresses the ratio as a CSS `line-height` multiplier against
`font-size`, not as absolute pixels, so it needs `ratio * 0.6` rather than the ratio
directly. Worth a comment at both sites.

## Reproduction

1. `./gummyworm circle.png -w 80 -q -f svg -o out.svg`
2. SVG is 576.0 x 518.4 for a square source — should be square.

## Acceptance criteria

- [x] SVG line height derives from the shared ratio rather than a literal `14.4`
- [x] HTML `line-height` derives from the same value
- [x] `--char-aspect` changes exported geometry, not just terminal output
- [x] A round source exports to a canvas whose aspect matches the source within rounding

## 2026-09-19

Added a Shared Font Metrics block to lib/export.sh: EXPORT_FONT_SIZE, EXPORT_CHAR_WIDTH_EM (0.6em advance) and three derived helpers. SVG uses export_char_width/export_line_height; HTML uses export_css_line_height, which is ratio*0.6 because CSS line-height multiplies font-size rather than char width. Verified square source exports a square canvas: 576.0x576.0 at default (was 576.0x518.4), and geometry now tracks --char-aspect. HTML CSS confirmed at 1.2 default, 1.002 at 1.67.
