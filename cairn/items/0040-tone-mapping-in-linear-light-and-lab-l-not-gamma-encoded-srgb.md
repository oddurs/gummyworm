---
id: 40
uid: 0fb3ac14-3194-484c-bb5f-784e7ed62754
title: Tone mapping in linear light and Lab L*, not gamma-encoded sRGB
type: feature
status: doing
milestone: fidelity
depends_on:
- 38
created: 2026-10-09
updated: 2026-10-09
priority: p1
effort: m
area: rendering
---

Downscale with a proper filter in linear RGB and decide tone on perceptual lightness. Today the resize happens in encoded sRGB and luma uses Rec.601 weights on encoded values.

## 2026-10-09

Tried the resize half: downscaling in linear light (-colorspace RGB around -resize). Mean SSIM 0.5745 -> 0.5740, line art slightly worse. Not shipped. Likely because the rsvg rasteriser blends glyph coverage in encoded space, so encoded-space tone mapping is already what the score rewards; a real terminal may differ. The Lab L* mapping half is untried and should be judged against a terminal-faithful rasteriser first.
