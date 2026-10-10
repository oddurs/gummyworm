---
id: 61
uid: 97b5b9a2-2786-4261-884b-0ea24612a6df
title: -h should show help; add -V and accept - for stdin
type: feature
status: done
milestone: cli-polish
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p1
effort: s
area: cli
---

The short flag -h is bound to --height, so 'gummyworm -h' errors (see 0014). -V is unknown. '-' is rejected as an unknown option instead of meaning stdin. Keep '-h N' working as a deprecated height with a warning so existing scripts do not break.
