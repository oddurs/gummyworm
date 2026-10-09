---
id: 43
uid: 873b1129-c1fd-47ba-81b7-394dea7bea24
title: Measure the cell pixel size instead of assuming an aspect of 2.2
type: feature
status: backlog
milestone: fidelity
created: 2026-10-09
updated: 2026-10-09
priority: p2
effort: s
area: rendering
---

Use TIOCGWINSZ pixel fields or the CSI 14t/18t queries to get the real cell aspect; fall back to the configured char_aspect.
