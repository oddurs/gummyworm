---
id: 10
title: Stale version assertion in test_zsh_compat.sh pins 2.1.0
type: bug
status: done
milestone: v2.3.0
assignee: Oddur Sigurdsson
created: 2026-09-20
updated: 2026-09-20
priority: p1
effort: s
area: tests
part_of:
- 1
---

## What happens

`tests/test_zsh_compat.sh:126` asserts the `--version` output contains the literal
string `2.1.0`. The version is now `2.3.0`, so the suite reports 14/15 under zsh.

The assertion has been wrong since the 2.2.0 release. It went unnoticed because
`run_all.sh` never runs this suite — see the sibling item on suite coverage.

## What should happen

The test asserts against the version the code actually reports, so it cannot
drift again at the next release.

## Acceptance criteria

- [x] The test derives the expected version from `GUMMYWORM_VERSION` rather than a hardcoded literal
- [x] `zsh tests/test_zsh_compat.sh` passes 15/15
