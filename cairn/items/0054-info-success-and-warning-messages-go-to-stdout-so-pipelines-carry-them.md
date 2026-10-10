---
id: 54
uid: ffe2a18d-88c4-4cf6-bc81-c69a42b5778a
title: Info, success and warning messages go to stdout, so pipelines carry them
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

log_info, log_success and log_warn write to stdout. 'gummyworm photo.jpg | pbcopy' copies the 'Converting:' line, and -f/-o output interleaves with them. Diagnostics belong on stderr.
