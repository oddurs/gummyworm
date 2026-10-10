---
id: 66
uid: c78f568d-834e-4e63-9f66-eb126d246d26
title: Perceptual colour score in the benchmark
type: feature
status: done
milestone: v2.5.0
assignee: Oddur Sigurdsson
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p1
effort: m
area: color
---

Reduce source and render to 64x64 in linear light and compare in OKLab. Report delta-E after matching overall exposure, the exposure gain itself (how much dimmer the render is), and the chroma ratio (how much saturation survives). The SSIM score only sees luma. Show colour renders in the comparison page.

## 2026-10-09

colorscore.py reduces source and render to 24x24 in linear light and compares in OKLab after matching the 98th-percentile luminance (white point). First version matched the mean and used 64x64: on mostly black images the gain blew up and clipped, and at 64x64 the score saw individual glyph texture. Both were scorer faults, found because the new engine looked worse on text and line art for no good reason. 'bench.sh rescore' recomputes scores from saved renders so a scorer change needs no new renders.
