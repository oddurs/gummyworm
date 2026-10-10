---
id: 41
uid: 7b091591-4383-4030-b810-9199688c1d16
title: 256-colour mode picks the nearest palette colour, not a truncated cube index
type: bug
status: done
milestone: v2.5.0
depends_on:
- 38
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p2
effort: s
area: rendering
---

rgb_to_ansi truncates (r*5/255) and never uses the greyscale ramp 232-255. Pick the nearest of the cube and greyscale colours in a perceptual space.

## 2026-10-09

Folded into 0068 under the colour engine milestone.
