---
id: 30
uid: 36db627e-25ea-4156-a6c4-a10d73d3b983
title: Library functions exit the process instead of returning errors
type: chore
status: backlog
milestone: v2.6.0
depends_on:
- 26
- 27
created: 2026-09-22
updated: 2026-09-22
priority: p2
effort: l
area: architecture
---

## What happens

The library layer terminates the process and writes to the terminal itself:

```
exit/die/die_usage sites     UI output sites (log_*, echo -e)
  lib/cli.sh        37         lib/cli.sh        26
  lib/image.sh       8         lib/utils.sh      15
  lib/utils.sh       8         lib/export.sh     10
  lib/config.sh      3
  lib/converter.sh   2
```

A function that exits cannot report failure to its caller; the caller never
gets control back to decide what to do.

## Why it matters

- **Testing.** Every helper in `tests/test_cli.sh` has to wrap `parse_args` in a
  subshell because `die_usage` exits. That works, but it is a workaround for a
  library that will not return.
- **Batch behaviour.** `--continue-on-error` exists because one bad image
  should not stop the run, but anything deep in the stack that calls `die`
  still takes the whole batch down.
- **Reuse.** Nothing other than this CLI can call `lib/` and survive a failure.

## Direction

- Library functions return a status and leave a message in a known variable
  (or print it to stderr) — they never `exit`.
- `die` and `die_usage` are called only from `bin/gummyworm`, which is the one
  place entitled to decide the process is over.
- `log_*` UI helpers either move to `bin/` or become quiet by default in `lib/`,
  with the caller deciding what the user sees.

`parse_args` is the largest single case at 37 sites and a reasonable first slice.

## Acceptance criteria

- [ ] No function in lib/ calls exit, die or die_usage
- [ ] Exit codes seen from the CLI are unchanged, verified by the suite
- [ ] test_cli.sh calls parse_args directly, without subshells, for its rejection cases
- [ ] --continue-on-error survives a failure raised anywhere in the per-image path
