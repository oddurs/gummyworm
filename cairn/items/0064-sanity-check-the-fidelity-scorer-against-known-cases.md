---
id: 64
uid: 7ceda23a-33ff-4626-a812-5728057e0a8b
title: Sanity-check the fidelity scorer against known cases
type: chore
status: backlog
milestone: fidelity
created: 2026-10-09
updated: 2026-10-09
priority: p2
effort: s
area: rendering
---

A plain horizontal gradient scores 0.52 SSIM at every scale tried, which is implausibly low for an easy image, and the score changes by a few thousandths between runs that look identical. Check the scorer against known cases (identical, blurred, offset, tone-shifted) before trusting small differences, and consider reporting a tone-only score beside the structure score.
