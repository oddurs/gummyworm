---
id: 55
uid: e7055c93-1fcf-47bb-a54a-7a266864fa9c
title: Colour codes ignore NO_COLOR and whether the stream is a terminal
type: bug
status: done
milestone: cli-polish
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p1
effort: s
area: cli
---

Errors and help emit ANSI escapes into pipes and log files, and NO_COLOR is not read. Colour only when the stream is a terminal and NO_COLOR is unset.

## 2026-10-09

Two sets: COLOR_* follows stdout (help, palette list), ERR_* follows stderr (diagnostics). Both empty when NO_COLOR is set, TERM=dumb, or the stream is not a terminal.
