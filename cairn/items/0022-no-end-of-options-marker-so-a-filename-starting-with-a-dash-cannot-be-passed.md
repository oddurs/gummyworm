---
id: 22
title: No -- end-of-options marker, so a filename starting with a dash cannot be passed
type: bug
status: backlog
milestone: later
created: 2026-09-21
updated: 2026-09-21
priority: p3
effort: s
area: cli
---

## What happens

```sh
cd images && gummyworm -w 10 -- -cover.png
✖ Error: Unknown option: --
exit 1
```

`parse_args` has no `--` case, so the marker itself is caught by the `-*` arm
and rejected as an unknown option (`lib/cli.sh:365-367`). Without it there is no
way to name a file whose first character is `-` by a bare relative path.

## Workaround

`./-cover.png` or an absolute path both work today, so this is a papercut
rather than a blocker.

## Acceptance criteria

- [ ] `--` stops option parsing; everything after it is treated as a filename
- [ ] A test covers a file whose name begins with a dash
