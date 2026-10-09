---
id: 15
uid: 650bf135-bee3-4f6a-8b91-1f577c8e8d37
title: Add test_cli.sh covering the argument parser directly
type: chore
status: done
milestone: v2.3.1
assignee: Oddur Sigurdsson
created: 2026-09-20
updated: 2026-09-22
priority: p1
effort: m
area: tests
---

## Why

`lib/cli.sh` is 425 lines and holds every flag's validation, the config/CLI
precedence rules, and directory expansion. No test file targets it — it is only
exercised incidentally through end-to-end runs in `test_basic.sh`, which assert
on final output and cannot distinguish a parser bug from a rendering one.

Two bugs found by reading it in one sitting (unvalidated `--background`, `-h`
bound to height) suggest reading is doing work that tests should do.

## Scope

Direct tests for `parse_args`:

- Each validated flag accepts a good value and rejects a bad one: width, height,
  brightness, contrast, gamma, padding, format, frame-delay, max-frames, loops,
  char-aspect
- Boundary values, since several ranges are inclusive: gamma 0.1/10.0,
  char-aspect 0.5/5.0, brightness and contrast -100/100
- Every flag missing its argument produces a usage error, not a crash
- Unknown options are rejected
- Precedence: default < config file < CLI argument
- `--truecolor` implicitly enables color; `--no-truecolor` does not disable it
- Positional arguments collect into ARG_IMAGES in order

## Acceptance criteria

- [x] `tests/test_cli.sh` exists and is listed in `run_all.sh`
- [x] Every flag with a validation rule has a positive and a negative case
- [x] Inclusive range boundaries are asserted at both ends
- [x] The config/CLI precedence chain is asserted
- [x] The suite passes
