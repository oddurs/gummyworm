---
id: 45
uid: fa8e71b9-5144-4ad3-9418-50d30138a6b5
title: Check how alpha is handled in the pixel pipeline
type: chore
status: backlog
milestone: fidelity
created: 2026-10-09
updated: 2026-10-09
priority: p2
effort: s
area: rendering
---

The awk stage reads R,G,B and ignores A in (R,G,B,A). Establish what transparent pixels render as and whether they are composited onto the right background.
