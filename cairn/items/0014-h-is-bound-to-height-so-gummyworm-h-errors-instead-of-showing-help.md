---
id: 14
uid: d5731291-5a13-4df5-8b60-0827aa325bc9
title: -h is bound to --height, so 'gummyworm -h' errors instead of showing help
type: bug
status: done
milestone: later
created: 2026-09-20
updated: 2026-10-09
closed_at: 2026-10-09
priority: p2
effort: s
area: cli
---

## What happens

`lib/cli.sh:205` binds `-h` to `--height`. Help is `--help` only (`lib/cli.sh:358`).

```sh
gummyworm -h
# ✖ Error: Option -h requires an argument
# exit 1
```

`-h` means help in essentially every CLI a user will have touched. Someone
reaching for it gets an error telling them to use `--help`.

## The tension

`-h` for height is existing documented behaviour — README, completions and the
docs site all list it. Rebinding it is a breaking change for anyone scripting
`-h 40`, which is why this is filed rather than fixed in passing.

Options:

1. Rebind `-h` to help, drop the short form for height. Breaking, but matches
   every user expectation.
2. Keep `-h` as height. Status quo.
3. Bare `-h` shows help, `-h 40` sets height. Not breaking, but one flag with
   two meanings is its own trap.

Leaning 1 for the next minor: the short form for height is the less valuable of
the two, and `--height` stays either way.

## Acceptance criteria

- [ ] A decision is recorded here with its reasoning
- [ ] The chosen behaviour is implemented and tested
- [ ] README, docs site, and both completion files agree with the code

## 2026-10-09

Being fixed under 0061: -h shows help, and '-h N' keeps working as a deprecated height with a warning.
