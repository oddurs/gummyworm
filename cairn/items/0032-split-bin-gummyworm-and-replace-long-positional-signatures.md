---
id: 32
uid: aa2ba436-c0e1-480f-9e1f-430dc105e9c4
title: Split bin/gummyworm and replace long positional signatures
type: chore
status: backlog
milestone: v2.5.0
depends_on:
- 31
created: 2026-09-22
updated: 2026-09-22
priority: p3
effort: l
area: architecture
---

## What happens

`bin/gummyworm` is the largest file in the project at 750 lines. It holds
per-image orchestration, output routing, terminal animation playback, export
content selection, and batch output naming.

Seven of its functions take ten or more positional parameters, and two more in
`lib/converter.sh` do too. `get_export_content` takes 13, with defaults at
positions 10–13:

```sh
get_export_content "$output_format" "$result" "$resolved_image" \
    "$ARG_WIDTH" "$ARG_HEIGHT" "$palette" "$ARG_INVERT" "$ARG_COLOR" \
    "$ARG_PRESERVE_ASPECT" "$ARG_TRUECOLOR" "$ARG_BRIGHTNESS" "$ARG_CONTRAST" "$ARG_GAMMA"
```

Swap two of those and nothing fails — the output is just wrong.

## Direction

- Move animation playback and export routing out of `bin/` into `lib/`,
  leaving `bin/gummyworm` as argument handling plus a loop.
- Once the global-state item has settled how resolved settings travel, pass a
  settings bundle rather than a long positional list. In bash 3.2 without
  namerefs, the pragmatic shape is probably a small set of well-named
  variables resolved once and passed by name, rather than thirteen positionals.

Deliberately last in this milestone: the right signature depends on how
settings end up being carried, which is the global-state item's decision.

## Acceptance criteria

- [ ] bin/gummyworm holds argument handling and orchestration only
- [ ] Animation playback and export routing live in lib/
- [ ] No function takes more than 6 positional parameters
- [ ] CLI behaviour is unchanged, verified by the suite
