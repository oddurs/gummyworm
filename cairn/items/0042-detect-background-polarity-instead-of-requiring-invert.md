---
id: 42
uid: 52bfde56-617e-43a4-a402-ffe0ba3ffe8c
title: Detect background polarity instead of requiring --invert
type: feature
status: backlog
milestone: fidelity
depends_on:
- 38
created: 2026-10-09
updated: 2026-10-09
priority: p1
effort: s
area: rendering
---

Query the terminal background (OSC 11) and choose the ramp direction automatically. Wrong polarity yields a negative image, the worst comprehension failure. Keep --invert as an override.
