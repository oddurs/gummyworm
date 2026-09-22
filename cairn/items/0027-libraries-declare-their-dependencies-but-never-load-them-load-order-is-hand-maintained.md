---
id: 27
title: Libraries declare their dependencies but never load them; load order is hand-maintained
type: chore
status: backlog
milestone: v2.4.0
depends_on:
- 26
created: 2026-09-22
updated: 2026-09-22
priority: p1
effort: m
area: architecture
---

## What happens

Every library states its dependencies in a header comment:

```
lib/cli.sh:6        # Requires: lib/config.sh, lib/utils.sh, lib/palettes.sh
lib/converter.sh:6  # Requires: lib/config.sh, lib/utils.sh, lib/palettes.sh, lib/image.sh
lib/export.sh:6     # Requires: lib/config.sh, lib/utils.sh
```

No `lib/*.sh` sources anything. Only `bin/gummyworm:69-88` does, in an order
someone has to keep correct by hand — and `tests/test_runner.sh:92-100`
duplicates that order separately.

Two aggravating details:

- `config.sh` is the only module with **no include guard** — the other six all
  have `_GUMMYWORM_*_LOADED`.
- `config.sh` also **does work at source time**: it loads config files at
  `config.sh:272-274`, partway through its own definitions. Anything it calls
  there has to be defined earlier in the same file.

## Why it matters

This produced a real bug during the `--background` fix. `is_valid_color` went
into `utils.sh`, where it belongs, and was invisible to `config.sh` because
`utils.sh` loads second — so every config background, valid ones included,
was silently rejected. The fix moved the code into `config.sh` to satisfy load
order rather than cohesion. That trade will keep recurring, and each time it
pulls unrelated code into `config.sh`.

## Direction

1. Give each module a small `_require <module>` that sources a dependency
   through the include guards that already exist. The guards make repeated
   requires free, which is exactly what they are for.
2. Add an include guard to `config.sh`.
3. Move config-file loading out of source time into an explicit call made by
   `bin/gummyworm`, so sourcing a module never has side effects.
4. Once (3) is done, `is_valid_color` can move back to `utils.sh`.

`test_runner.sh` should then source only what each test needs, instead of a
second copy of the order.

## Acceptance criteria

- [ ] Each lib sources its own declared dependencies
- [ ] config.sh has an include guard
- [ ] Sourcing any single lib in a fresh shell works without sourcing anything else first
- [ ] Sourcing a module has no side effects; config loading is an explicit call
- [ ] The load order no longer lives in two places
- [ ] A test sources each lib alone and asserts it loads
