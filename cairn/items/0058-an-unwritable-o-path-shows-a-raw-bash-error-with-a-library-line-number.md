---
id: 58
uid: 442f5980-89d8-444e-9fd9-81155e402eaf
title: An unwritable -o path shows a raw bash error with a library line number
type: bug
status: done
milestone: v2.5.0
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p2
effort: s
area: cli
---

'-o /nonexistent/dir/x.txt' prints 'lib/export.sh: line 659: ... No such file' instead of an error message.
