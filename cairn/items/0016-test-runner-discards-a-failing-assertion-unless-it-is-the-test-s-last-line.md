---
id: 16
uid: c300f954-2f97-4d57-987c-a4f7cf4c0340
title: Test runner discards a failing assertion unless it is the test's last line
type: bug
status: done
milestone: v2.3.1
assignee: Oddur Sigurdsson
created: 2026-09-20
updated: 2026-09-22
priority: p0
effort: m
area: tests
---

## What happens

`run_test` ran each test as `( set -e; "$func" )`, relying on errexit to abort
the subshell when an assertion returned non-zero. It never did.

`run_test_suite:612` calls `run_test ... || true`. Bash suppresses errexit for
the entire dynamic extent of a command in an `&&` / `||` list — including
subshells created inside it. The `set -e` in that subshell was silently ignored,
so the subshell's status came from the test function's *last* command only.

The result: a failing assertion that was not the last line of its test printed
`✗ ASSERTION FAILED` to the terminal and the test still reported **PASS**.

Reproduced directly:

```
CASE 1: runner called normally          subshell rc=1
CASE 2: runner called as 'runner h || true'   subshell rc=0
```

## Blast radius

230 test functions, 384 assertions. 78 functions hold more than one assertion,
so **154 assertions — 40% of the suite — were never enforced.**

This is what let `test_zsh_compat.sh` call `is_valid_hex_color`, a function that
exists nowhere in `lib/` or `bin/`, and still report PASS: the failing
`assert_true` was followed by an `assert_false` that "passed" because a
command-not-found is also non-zero.

## The fix

Assertions now record failures in `_TEST_ASSERT_FAILURES`; `run_test` resets it
per test and reads it, rather than depending on errexit propagating through a
caller's `||`. The subshell is kept for isolation. This is immune to the call-site
context and behaves the same under bash and zsh.

## Notes

Enabling real enforcement surfaced exactly one genuine failure across 290 tests —
the `is_valid_hex_color` call above. The other 153 unenforced assertions were
passing. The harness was the problem, not the code under test.

## Acceptance criteria

- [x] A failing assertion fails its test regardless of position in the function
- [x] The mechanism does not depend on errexit surviving the caller's `|| true`
- [x] All assertions in a failing test are reported, not just the first
- [x] The whole suite passes with enforcement on
