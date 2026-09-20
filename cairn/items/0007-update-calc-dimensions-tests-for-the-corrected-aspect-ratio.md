---
id: 7
title: Update calc_dimensions tests for the corrected aspect ratio
type: chore
status: done
milestone: v2.3.0
assignee: Oddur Sigurdsson
depends_on:
- 4
created: 2026-09-19
updated: 2026-09-19
priority: p2
effort: s
area: tests
---

Seven assertions in `tests/test_image.sh:111-170` hardcode heights derived from the 2.2
divisor and will fail once 0004 lands:

```
test_calc_dimensions_basic            calc_dimensions 100 100 50 0 true
test_calc_dimensions_wide_image       calc_dimensions 200 100 80 0 true
test_calc_dimensions_tall_image       calc_dimensions 100 200 80 0 true
test_calc_dimensions_square_image     calc_dimensions 100 100 40 0 true
test_calc_dimensions_explicit_height  calc_dimensions 100 100 80 40 true
test_calc_dimensions_no_aspect        calc_dimensions 100 100 80 0 false
test_calc_dimensions_minimum_height   calc_dimensions 1000 1 50 0 true
```

Expected values need recomputing against 2.0 and round-half-up. Two of these are not
just arithmetic updates and should be checked rather than mechanically bumped:

- `explicit_height` passes a non-zero target height, which bypasses the ratio branch
  entirely. It should be unaffected — confirm that, it is the regression guard for the
  fix not leaking into the explicit path.
- `minimum_height` exercises the `out_h < 1` floor with an extreme 1000:1 source. Under
  round-half-up the floor may now be reached at a different input, so verify it still
  tests the clamp.

Worth adding while here: a case pinning the ratio itself (square source, known width,
assert exact height), so the constant cannot drift silently again — which is how 0004
survived since `eac3b42`.

## Acceptance criteria

- [x] All seven assertions updated and passing
- [x] `explicit_height` confirmed unchanged by the fix
- [x] `minimum_height` still exercises the clamp
- [x] A test pins the default ratio directly
- [x] `tests/run_all.sh` passes

## 2026-09-19

Correction: this item's premise was wrong. The seven assertions did not hardcode heights derived from the 2.2 divisor -- they asserted only that height was positive and, in one case, less than width. Nothing failed after 0004; all 37 tests in test_image.sh passed unchanged. That looseness is the actual finding, and it is why the wrong constant survived from eac3b42 to now: no assertion could tell 2.2 from 2.0. Rewrote them to assert exact grids, and added four: default_ratio (pins DEFAULT_CHAR_ASPECT and its output), custom_ratio (1.67/2.0/2.2 give 48/40/36 rows), rounds_half_up (two exact .5 cases truncation would get wrong), invalid_ratio_falls_back (non-numeric, zero, empty). explicit_height and no_aspect now also assert against a custom ratio, so the two branches that must ignore or follow the ratio each have a guard. 41/41 in test_image.sh.

## 2026-09-19

Full suite green once 0009 landed: 206/206, 5/5 suites. The one failure before that was the pre-existing PNG export bug, not a regression from this work.
