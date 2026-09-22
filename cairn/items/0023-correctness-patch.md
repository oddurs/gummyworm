---
id: 23
key: v2.3.1
title: Correctness patch
type: milestone
status: done
created: 2026-09-22
updated: 2026-09-22
priority: p2
due: 2026-09-22
---

Ship the fixes that landed after the v2.3.0 tag, and make the release installable.

Everything already done here is a user-facing correctness fix: `--background`
markup injection into exported HTML/SVG, the shipped `detailed` palette
rendering ragged rows, recursive batch silently overwriting its own output,
and a test runner that was not enforcing 40% of its assertions. None of that
should wait on refactoring.

The release is only useful if people can install it. `Formula/gummyworm.rb`
is still pinned to v2.2.0, and `scripts/release.sh` writes a SHA256 that can
never match the URL it points at — both are in here so v2.3.1 is the first
release that `brew install` actually delivers.

No behaviour changes beyond bug fixes. Anything that alters an interface goes
in a minor release.

## 2026-09-22

Cut as v2.3.1 on 2026-09-22 (local tag; push is the owner's call). All 7 items done.
