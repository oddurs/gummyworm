---
id: 25
uid: 6e6d7fd1-0ed6-4c37-952e-0a960413eab9
key: v2.5.0
title: Library boundaries
type: milestone
status: backlog
created: 2026-09-22
updated: 2026-09-22
priority: p2
---

Make `lib/` a library: functions that return errors, take their inputs
explicitly, and can be tested and reused without the CLI around them.

Today the library layer exits the process (`lib/cli.sh` alone has 37
`exit`/`die` sites) and writes directly to the terminal, so nothing can call it
and recover from a failure, and every test of it has to run in a subshell.
Layers talk through 65 global `ARG_*` / `CONFIG_*` / `DEFAULT_*` variables —
to the point that `parse_args` writes into the config layer's namespace so the
compute layer can see a CLI flag. And `bin/gummyworm` has grown into a
750-line controller whose functions take up to 13 positional parameters.

These are the larger, riskier refactors, deliberately kept apart from
v2.4.0. They depend on its CI and enforced dependency graph: changing how every
function reports failure is not something to do without a suite that runs on
every push.

Internal restructuring only. The CLI's observable behaviour — flags, output,
exit codes — must not change, and the suite is the proof.
