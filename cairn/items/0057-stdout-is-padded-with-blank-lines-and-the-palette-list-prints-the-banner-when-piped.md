---
id: 57
uid: 9e78b1d9-6ab9-4aca-933c-acee77d1685b
title: stdout is padded with blank lines and the palette list prints the banner when piped
type: bug
status: done
milestone: cli-polish
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p2
effort: s
area: cli
---

Every render is wrapped in an empty line before and after, and -l prints the banner, so 'gummyworm img > out.txt' is not the art alone. Pad and decorate only on a terminal.
