---
id: 24
uid: 92b6e339-b56e-4ce2-a80e-5ae799385b2e
key: v2.4.0
title: Foundations
type: milestone
status: backlog
created: 2026-09-22
updated: 2026-09-22
priority: p2
---

Fix the connective tissue between modules, and put a safety net under it.

The module decomposition is sound — config, utils, palettes, image, converter,
export and cli are the right seams. The weaknesses are in how they connect:

- **Dependencies are declared in comments and never enforced.** Only
  `bin/gummyworm` sources anything, in a hand-maintained order, and
  `config.sh` does work at source time with no include guard.
- **Data crosses from bash to awk two incompatible ways**, `-v` and
  delimiter-joined strings, and both produced shipped bugs.
- **The export layer spawns two processes per output row**, re-solving a
  problem the converter already solved with a single awk pass. SVG export is
  5.9x slower than text at `-w 200`, and the gap widens with height.
- **Nothing runs the tests.** 331 tests exist and run only on a developer's
  machine.

CI comes first within this milestone: every other item here is a change to
load order, data plumbing or the render path, and should land behind a suite
that runs on every push.

Interfaces stay the same. This is internal, plus one additive CLI option (`--`).
