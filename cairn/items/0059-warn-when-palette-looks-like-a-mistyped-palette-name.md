---
id: 59
uid: ed780800-2894-485f-aec5-7f8e205d24bc
title: Warn when --palette looks like a mistyped palette name
type: feature
status: done
milestone: cli-polish
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p3
effort: s
area: cli
---

Any string is accepted as literal characters, so '-p blokcs' silently renders with the letters b, l, o, k, c, s. Warn on stderr when the value is a plain word of four or more letters that names no palette.
