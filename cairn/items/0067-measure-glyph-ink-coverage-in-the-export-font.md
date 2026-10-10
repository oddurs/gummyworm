---
id: 67
uid: 6bdd74bd-1a05-40fb-b72b-602c885e1be4
title: Measure glyph ink coverage in the export font
type: feature
status: done
milestone: v2.5.0
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p1
effort: s
area: color
---

Rasterise each printable ASCII glyph in the exporter's font and record its ink coverage of the cell. The colour engine needs it, and it is the data behind measured palette ramps (0046). Committed as a table with the script that regenerates it.

## 2026-10-09

First two measurements were wrong. Coverage is the mean LINEAR light of a white glyph at device resolution, averaged over a 10x5 block so cells land on different sub-pixel offsets. 'magick -colorspace Gray' re-encodes to gamma, so '-colorspace RGB -colorspace Gray' silently gave the encoded mean again; use '-colorspace RGB' then fx:mean.r. Thin strokes at 1x are mostly partial pixels, so the correct value for # is 0.047, not the 0.114 first measured. Typical values only: terminals use other fonts.
