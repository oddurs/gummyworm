---
id: 46
uid: d8e0e98a-cf62-43b9-b0a4-199a09a8ffa6
title: Build palette ramps from measured glyph coverage
type: feature
status: backlog
milestone: fidelity
depends_on:
- 38
created: 2026-10-09
updated: 2026-10-09
priority: p1
effort: m
area: rendering
---

Rasterize each glyph in a given font, measure its ink coverage, and choose and space glyphs for perceptually even steps. Exact for exports (we pick the font); table-driven for common terminal fonts.
