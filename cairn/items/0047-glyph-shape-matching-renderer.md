---
id: 47
uid: ae7c4a73-4f00-430d-acee-8fe7cac5bec3
title: Glyph shape-matching renderer
type: feature
status: backlog
milestone: fidelity
depends_on:
- 37
- 46
created: 2026-10-09
updated: 2026-10-09
priority: p1
effort: xl
area: rendering
---

For each cell, compare the image patch against rasterized glyph bitmaps and pick the glyph with least error, preserving edges and lines. Too slow for awk, so this is the Rust core renderer and the reason to rewrite.
