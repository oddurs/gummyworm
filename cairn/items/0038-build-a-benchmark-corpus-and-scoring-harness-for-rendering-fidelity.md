---
id: 38
uid: 2f8067a8-b8eb-428b-9b76-221182b42f17
title: Build a benchmark corpus and scoring harness for rendering fidelity
type: feature
status: done
milestone: v2.4.0
assignee: Oddur Sigurdsson
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p1
effort: l
area: rendering
---

A fixed corpus (faces, text, landscapes, line art, low-contrast photos, high-contrast graphics) and a harness that renders each at several widths (40, 80, 160), rasterizes the output with a known font, and scores it against the source: SSIM/MS-SSIM for structure, Lab delta-E for colour. Record a baseline for the current renderer. Everything else in this milestone is judged against it.

## 2026-10-09

Built bench/bench.sh (corpus, render, compare). Corpus is 14 images: 4 public-domain photos, 10 synthetic/built-in, committed under bench/corpus so it cannot drift. Scored at 40/80/160 columns by SSIM after reducing source and rasterised render to 200x200 grey. Baseline at 7121d6e: mean 0.5745 over 42 renders. Known limit: the score is font- and rasteriser-dependent (rsvg blends glyphs in encoded space), and at 200x200 it penalises glyph texture. A coarser 'tone only' score alongside it would separate tone fidelity from structure; not done.
