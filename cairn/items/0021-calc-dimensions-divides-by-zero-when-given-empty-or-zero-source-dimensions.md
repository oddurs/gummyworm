---
id: 21
title: calc_dimensions divides by zero when given empty or zero source dimensions
type: bug
status: backlog
milestone: v2.4.0
created: 2026-09-21
updated: 2026-09-22
priority: p3
effort: s
area: image
---

## What happens

```
calc_dimensions "" "" 80 0 true
lib/image.sh:260: (numerator + denominator / 2) / denominator : division by 0
rc=1
```

Same for `calc_dimensions 0 0 80 0 true`. `denominator` is
`orig_w * aspect_x100`, so an `orig_w` of zero — or empty, which bash evaluates
as zero — kills the shell arithmetic.

`orig_w` comes from `image_dimensions`, which is `identify -format "%w"` with
stderr discarded (`lib/image.sh:188-190`). It returns empty on any failure.

## Not currently reachable from the CLI

`bin/gummyworm` validates the image before conversion, so a corrupt, empty or
truncated file is rejected earlier with `Invalid image: <path>` and exit 1.
Verified against a text file renamed `.png`, a zero-byte `.png`, and a
truncated PNG header — all three error correctly.

Filed as p3 for that reason: this is a library function that is unsafe on its
own terms, not a user-facing failure today. It becomes one the moment anything
calls `calc_dimensions` without the validation in front of it, and
`char_aspect_hundredths` already guards its own divisor
(`lib/image.sh:214-216`), so the surrounding code sets the expectation that
this one should too.

## Acceptance criteria

- [ ] `calc_dimensions` fails with a clear message rather than a shell arithmetic error when a source dimension is zero or empty
- [ ] A test covers zero and empty source dimensions
