---
id: 69
uid: 2a0d7191-7ef7-45e1-a682-255252bce37e
title: 'Optical colour engine: choose glyph and foreground together'
type: feature
status: done
milestone: v2.5.0
depends_on:
- 66
- 67
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p1
effort: l
area: color
---

For each cell pick the glyph and the foreground colour so that glyph coverage times foreground, mixed with the assumed background, reproduces the target in linear light. Map the source into the range the display can reach, keep the foreground at least as bright as the background, and fall back to the plain engine for palettes without measured coverage, for --invert and for light backgrounds. Exposed as --color-engine plain|optical and the color_engine config key.

## 2026-10-09

Result on the 14-image corpus, 42 renders, plain -> optical: colour error 11.13 -> 9.74, brightness needed x23 -> x16, saturation kept 0.78 -> 0.92, SSIM 0.5792 -> 0.5838. Better on 28 of 42 and at every width. Worse on smooth grey gradients (radial 7.9 -> 8.9) and line art (6.6 -> 8.1); about even on logo, plasma, wizard, mona-lisa. Two corrections came from the benchmark: coverage had to be linear light (0067), and the enhance step lifts flat black to about 18/255, which the exact model reproduced as a speckle of dim dots, so cells at or below 20/255 are background. Not done: a light-background mode (falls back to plain), joint selection against the real terminal font, and a shadow-lift option.
