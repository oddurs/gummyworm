---
id: 56
uid: ffb1ba75-6fcb-4818-8097-72c7ad93c986
title: Usage errors exit 1, the same as runtime failures
type: chore
status: done
milestone: cli-polish
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p2
effort: s
area: cli
---

Scripts cannot tell a bad invocation from a failed conversion. Usage errors should exit 2, with the shell's convention for the rest. Includes running with no input on a terminal.
