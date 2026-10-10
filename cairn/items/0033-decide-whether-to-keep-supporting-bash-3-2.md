---
id: 33
uid: 369ec7d7-81cf-4e9f-8405-0a5f71cec61f
title: Decide whether to keep supporting bash 3.2
type: chore
status: backlog
milestone: later
created: 2026-09-22
updated: 2026-09-22
priority: p3
effort: s
area: architecture
---

## The question

gummyworm supports bash 3.2+ and zsh 5.0+. bash 3.2 is what macOS still ships
as `/bin/bash`, so supporting it means the tool runs on a stock Mac with no
setup. That is a real benefit, and this is not a proposal to drop it — it is a
decision worth making deliberately rather than by inertia.

## What it costs

Shim sites: 17 in `lib/config.sh`, 6 in `lib/palettes.sh`, plus scattered
others. bash 3.2 has no associative arrays and no namerefs, which forces:

- `eval "$arr_name+=(...)"` for array append in `palette_to_array`
- flat parallel arrays such as `ARG_IMAGE_ROOTS` alongside `ARG_IMAGES`, kept
  index-aligned by hand
- palettes and colour tables encoded as delimited strings

The second-order cost is the interesting one. No associative arrays is *why*
the palette was passed around as a delimited string, which is *why* `0017`
existed. The constraint shapes the data model, and the data model is where
bugs have come from.

It also bounds the v2.5.0 refactors. A settings bundle is natural with
associative arrays or namerefs and awkward without them.

## Options

1. **Keep 3.2.** Zero-setup on stock macOS. Accept the constraints; lean on
   files and awk for structured data.
2. **Require bash 4+, keep zsh.** Unlocks associative arrays and namerefs. Most
   Mac users running a CLI from Homebrew already have a modern bash; the
   formula can depend on `bash` and point the shebang at it.
3. **Require zsh only.** Default login shell on macOS since Catalina, but most
   Linux systems do not ship it.

## Worth knowing before deciding

- The Homebrew formula is the main install path, and it can declare
  `depends_on "bash"` — so option 2 need not cost Homebrew users anything.
- Worth checking how people install it outside Homebrew before assuming.

## Acceptance criteria

- [ ] A decision is recorded here with its reasoning
- [ ] If support changes, the minimum version check in config.sh, the README and the formula agree
