---
id: 8
title: Regenerate README and website examples after the aspect fix
type: docs
status: done
milestone: v2.3.0
assignee: Oddur Sigurdsson
depends_on:
- 4
- 6
created: 2026-09-19
updated: 2026-09-19
priority: p2
effort: m
area: docs
---

Every checked-in example was generated under the 2.2 assumption, so until they are
regenerated the fix is invisible to anyone who has not built from source — and the
website keeps demonstrating the bug it fixed.

Covers the ASCII samples in `README.md`, anything under `examples/`, and the showcase
on the Docusaurus site in `docs/`.

Two things to get right rather than regenerating blindly:

- Any example whose ASCII is pasted into a Markdown fence renders at the *browser's*
  line-height, not the terminal's. Check what the site's CSS actually applies to `pre`
  before assuming 2.0 is the right ratio for those. If the site's `pre` line-height is
  not 1.2, the pasted samples need a different `--char-aspect` than the exported SVGs
  to look right on the page.
- `docs/` has a note in the repo history about ASCII showcase overflow styling
  (`f19c2d0`). Taller output means more rows, so re-check that at narrow viewports.

## Acceptance criteria

- [x] `README.md` samples regenerated
- [x] `examples/` regenerated
- [x] Website showcase regenerated
- [x] Site `pre` line-height checked against the ratio used for pasted samples
- [x] Showcase still fits at mobile width

## 2026-09-19

Correction: the premise was largely wrong. Nothing checked in was generated from an image under the 2.2 assumption. examples/ holds only .gitkeep; the README block and the site showcase are both box-drawing wordmarks, unaffected by cell ratio. So there was nothing to regenerate. Two real problems turned up instead. (1) The site CSS concern was right: .ascii-showcase pre used line-height 1.15 (cell ratio ~1.92), so default-generated art pasted there would have been ~4% off. Set to 1.2 to match the 2.0 default, with a comment tying the two together. (2) docs/docs/examples.md and export-formats.md presented hand-drawn symmetric illustrations as 'Output:' of real commands -- fabricated, and never real output at any ratio. Replaced both with genuine gummyworm output from a 600x600 source, and stated the dimensions so the squareness is checkable. Also documented --char-aspect in cli-reference.md and configuration.md, which 0005 left to --help and the rc example only. Site builds clean with no broken links. Showcase width is unchanged, so the mobile fit is as before.
