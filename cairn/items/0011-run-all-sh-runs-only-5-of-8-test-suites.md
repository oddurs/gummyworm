---
id: 11
title: run_all.sh runs only 5 of 8 test suites
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

`tests/run_all.sh:97-105` lists five suites. Three are never run:

- `test_basic.sh` (60 tests)
- `test_config.sh` (9 tests)
- `test_zsh_compat.sh` (15 tests)

So the headline "206/206 passed, 5/5 suites" understates coverage by 84 tests,
and a failing suite can sit green indefinitely — which is exactly what happened
to the stale version assertion in `test_zsh_compat.sh`.

This is the same class of gap as the aspect-ratio bug: the test that would have
caught it was not being exercised.

## Notes

`test_zsh_compat.sh` needs a zsh interpreter, so the runner has to invoke it
with `zsh`, not `bash`, and skip it gracefully where zsh is absent.

## Acceptance criteria

- [x] `test_basic.sh` and `test_config.sh` run as part of `run_all.sh`
- [x] `test_zsh_compat.sh` runs under zsh, and is skipped with a clear message when zsh is unavailable
- [x] `bash tests/run_all.sh` reports every suite and passes

## 2026-09-20

Also fixed a latent bug in run_suite: it executed every suite twice — once to display results, once to re-parse them for the totals. With 3 more suites added that would have run 290 tests twice. It now runs each suite once and reuses the captured output. VERBOSE mode echoes the captured output rather than re-running.
