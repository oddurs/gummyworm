---
id: 39
uid: 1529be87-a4fe-4f6e-91ac-d4b99c275de3
title: Before/after comparison of renders across the whole corpus
type: feature
status: done
milestone: v2.4.0
assignee: Oddur Sigurdsson
depends_on:
- 38
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p1
effort: m
area: rendering
---

Render the corpus with a baseline (a saved snapshot or a git ref) and with the working tree, then show them side by side per image, with the score delta for each and the biggest regressions and improvements first. Output as a terminal view and as a single HTML page. The point is debugging: change the renderer, see at once which images moved and by how much.

## 2026-10-09

bench/bench.sh compare <before> <after> writes one self-contained HTML page: source beside both renders per image, per-width SSIM, regressions first, width switch. 'render --ref REF' renders a git ref in a temporary worktree so the 'before' is exactly a commit. Terminal view not done; the HTML page is the only output.
