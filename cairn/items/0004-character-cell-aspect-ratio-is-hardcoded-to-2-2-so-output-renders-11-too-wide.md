---
id: 4
title: Character cell aspect ratio is hardcoded to 2.2, so output renders ~11% too wide
type: bug
status: done
milestone: v2.3.0
assignee: Oddur Sigurdsson
created: 2026-09-19
updated: 2026-09-19
priority: p1
effort: s
area: image
---

## What happens

`calc_dimensions()` in `lib/image.sh:190` divides by a hardcoded `22` — it assumes a
terminal character cell 2.2x taller than it is wide:

```bash
# Terminal chars are ~2:1 (height:width), compensate
out_h=$(( (target_w * orig_h * 10) / (orig_w * 22) ))
```

The comment above the line says 2:1. The code does 2.2:1. `git blame` puts both lines
in the initial commit `eac3b42`, so they have disagreed from the start.

Measured with a 400x400 source containing a true circle (disc diameter 360px, source
aspect exactly 1.000):

| | value |
|---|---|
| character grid | 80 cols x 36 rows |
| disc extent | 71 cols x 32 rows |
| SVG export canvas | 576.0 x 518.4 px |
| disc as rendered | 511.2 x 460.8 px |

The disc comes out at **1.109 — about 11% wider than tall**. Measuring the output
backwards recovers an assumed cell ratio of 2.219, which confirms the constant rather
than anything downstream.

Forcing the corrected row count shows the fix is purely this constant:

```
grid 80x36  disc 71 x 32 rows  ->  1.109 in a 2.0 terminal   (current)
grid 80x40  disc 71 x 35 rows  ->  1.014 in a 2.0 terminal   (corrected)
```

1.014 is as round as an 80-column grid gets; the residual is character quantisation,
not maths.

## What should happen

Default cell ratio 2.0 — both what the comment intends and what the exporter already
uses (see 0006).

The error direction flips with the terminal, so this is not purely cosmetic: at
iTerm2's default line-height of 1.0 (cell ~1.67:1) the same output renders at 1.33,
a third wider than tall.

## Reproduction

1. `magick -size 400x400 xc:white -fill black -draw "circle 200,200 200,20" circle.png`
2. `./gummyworm circle.png -w 80 -q`
3. Measure the blank disc: 71 cols across, 32 rows tall — should be ~71 x 35.

## Notes

Also switch the integer division to round-half-up. It currently truncates and can lose
most of a row: `800/22 = 36.36 -> 36`.

## Acceptance criteria

- [x] `calc_dimensions` takes the cell ratio as a parameter instead of hardcoding `22`
- [x] Default ratio is 2.0
- [x] Division rounds half-up rather than truncating
- [x] A round source image measures within one character of round at the default

## 2026-09-19

Fixed in lib/image.sh: calc_dimensions gains an optional 6th char_aspect param defaulting to CONFIG_CHAR_ASPECT (2.0). Maths moved to hundredths integers with round-half-up. Verified: 400x400 circle now renders an 80x40 grid, disc 71c x 35r, roundness 1.014 (was 1.109). The old behaviour is still reachable as --char-aspect 2.2, which reproduces the 36-row grid exactly. The --no-aspect branch now derives from the ratio too, which is a no-op at the 2.0 default (width/2) but correct at other ratios.
