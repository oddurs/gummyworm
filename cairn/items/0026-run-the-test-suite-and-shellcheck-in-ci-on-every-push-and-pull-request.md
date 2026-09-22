---
id: 26
title: Run the test suite and shellcheck in CI on every push and pull request
type: chore
status: done
milestone: v2.4.0
assignee: Oddur Sigurdsson
created: 2026-09-22
updated: 2026-09-22
priority: p1
effort: s
area: ci
---

## Why

`.github/workflows/deploy-docs.yml` is the only workflow, and it only fires on
`docs/**`. The 331 tests run nowhere but a developer's machine.

This session has shown what that costs. `run_all.sh` silently skipped three of
its suites for at least one release; a version assertion rotted for a whole
release cycle; and the runner itself was discarding 40% of assertions. Every
one was found by hand. A suite that is not run is not a safety net.

## Scope

- Run `tests/run_all.sh` on push to `main` and on every pull request
- Install what the suites need: ImageMagick, librsvg (PNG/GIF export), zsh
  (the zsh compatibility suite skips cleanly without it, but should run)
- Run shellcheck at error severity over `lib/`, `bin/` and `tests/`
- Run on macOS as well as Linux. macOS ships bash 3.2 and BSD userland, which
  is the compatibility target this project claims — Linux alone would not
  exercise it

## Known shellcheck false positives

Excluding these is expected, not a smell:

- `SC2296` — zsh-only `${(%):-%x}` expansions inside zsh-guarded branches
- `SC1071` — shellcheck does not parse zsh, so `test_zsh_compat.sh` is out of scope
- `SC1087` — `"$image[0]"` in `lib/image.sh` is ImageMagick frame syntax, intentional

## Acceptance criteria

- [x] A workflow runs `tests/run_all.sh` on push to main and on pull requests
- [x] It runs on both ubuntu and macOS runners
- [x] The macOS job runs the suite under the system bash 3.2, not a Homebrew bash
- [x] shellcheck runs at error severity and fails the build on a new finding
- [x] The README carries a status badge

## 2026-09-22

Written and verified locally as far as possible without pushing: the full suite passes under macOS /bin/bash 3.2 via the same PATH-shim the workflow uses; passes again with magick hidden so only convert/identify resolve, exercising the IM6 branch Ubuntu's imagemagick package takes; the exact shellcheck invocation exits 0; the YAML parses. Not verified: an actual Actions run, since that requires pushing. Setting it up surfaced two things: test_basic.sh used 'mktemp -t name' with no X's, which GNU mktemp rejects (the Ubuntu job would have died at setup) — fixed by consolidating into one scratch dir; and multi-byte palettes break under LC_ALL=C — filed as 0034, with the workflow pinning a UTF-8 locale meanwhile.
