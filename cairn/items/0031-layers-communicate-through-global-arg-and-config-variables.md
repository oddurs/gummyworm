---
id: 31
uid: 2284ef52-91c5-4315-a112-ac34c0e07eeb
title: Layers communicate through global ARG_ and CONFIG_ variables
type: chore
status: backlog
milestone: v2.6.0
depends_on:
- 27
created: 2026-09-22
updated: 2026-09-22
priority: p2
effort: l
area: architecture
---

## What happens

The interface between layers is 65 global variables: 26 `ARG_*`, 19 `CONFIG_*`,
20 `DEFAULT_*`. Functions read whichever they happen to need from the global
scope rather than taking inputs as arguments.

The code already documents where this breaks down (`lib/cli.sh:376-380`):

> The character aspect is read deep in the dimension maths and again by the
> exporter, neither of which sees `ARG_*`. Publish the resolved value
> (default < config file < CLI) as the config global both already read.

So the CLI layer writes into the config layer's namespace so the compute layer
can see a flag. That is a layering inversion, and every future option the
compute layer needs will need the same move.

## What is sound, and should survive

The precedence chain — default < config file < CLI — is correct and tested
(`test_cli_overrides_config`, `test_config_used_when_flag_absent`). The problem
is how the resolved values are delivered, not how they are resolved.

## Direction

Resolve precedence once, into one set of settings, at the edge. Pass what each
function needs as arguments from there. The compute layer (`image.sh`,
`converter.sh`, `export.sh`) should read no `ARG_*` or `CONFIG_*` global at all.

`calc_dimensions` already takes `char_aspect` as an optional sixth argument and
only falls back to the global — so the target shape is partly there.

## Acceptance criteria

- [ ] image.sh, converter.sh and export.sh read no ARG_ or CONFIG_ global
- [ ] parse_args no longer writes into CONFIG_ to reach lower layers
- [ ] Precedence is resolved in exactly one place
- [ ] The precedence tests still pass unchanged
