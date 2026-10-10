---
id: 68
uid: f4cea187-d616-4110-a78d-17cc82b9f09e
title: 256-colour mode snaps to the nearest colour in the real palette
type: bug
status: done
milestone: color-engine
depends_on:
- 66
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p2
effort: s
area: color
---

rgb_to_ansi and the awk path map each channel to int(c*5/255), but the cube levels are 0,95,135,175,215,255, not evenly spaced, and the grey ramp is never used. Snap to the nearest of cube and grey by a perceptual distance. Supersedes 0041.

## 2026-10-09

rgb_to_ansi in converter.sh still truncates but is unused outside its own tests; the awk path used by every render now uses snap256 (cube or grey ramp, redmean distance).
