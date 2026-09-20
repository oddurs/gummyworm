---
id: 12
title: CHANGELOG version history table missing the 2.3.0 row
type: docs
status: done
milestone: v2.3.0
assignee: Oddur Sigurdsson
created: 2026-09-20
updated: 2026-09-20
priority: p2
effort: s
area: docs
part_of:
- 1
---

## What happens

`CHANGELOG.md:160` has a "Version History Summary" table that starts at 2.2.0.
The 2.3.0 release notes and the `[2.3.0]` compare link are both present and
correct; only the summary row was missed.

The 2.3.0 entry is also dated 2026-09-19, which should match the day the tag
actually lands.

## Acceptance criteria

- [x] The table carries a 2.3.0 row with its date and a one-line highlight
- [x] The 2.3.0 heading date matches the release date
