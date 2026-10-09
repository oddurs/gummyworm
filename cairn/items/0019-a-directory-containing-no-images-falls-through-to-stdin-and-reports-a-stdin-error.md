---
id: 19
uid: d0a537ee-d52d-4884-9474-d5ee50f39e43
title: A directory containing no images falls through to stdin and reports a stdin error
type: bug
status: done
milestone: v2.3.1
assignee: Oddur Sigurdsson
created: 2026-09-21
updated: 2026-09-22
priority: p2
effort: s
area: cli
---

## What happens

```sh
mkdir empty && gummyworm -w 10 empty
```

```
⚠ No images found in directory: .../empty
✖ Error: Stdin does not contain valid image data
exit 1
```

Same for a directory holding only non-image files.

## Why

`parse_args` expands a directory argument into image paths
(`lib/cli.sh:389-397`). When it finds none it logs a warning and leaves
`ARG_IMAGES` empty. The next block treats an empty `ARG_IMAGES` as "no input
was given" and reads an image from stdin (`lib/cli.sh:408-417`).

The user named a directory explicitly. Falling back to stdin diagnoses a
problem they do not have, and the warning that says what actually went wrong is
buried above a louder error that contradicts it.

## What should happen

An explicit input argument that yields no images is an error about that
argument. Stdin is for when no input argument was given at all.

Exit 1 is already right; only the diagnosis is wrong.

## Acceptance criteria

- [x] A directory with no images errors about the directory, not about stdin
- [x] Piped stdin still works when no input argument is given
- [x] A test covers both

## 2026-09-22

Fixing this exposed a latent test defect: test_cli.sh used a relative DUMMY_IMAGE, and an earlier run had left an empty ./dummy.png directory in the repo root (created by parse_args' mkdir -p for -d). Every 'accepts' test had been expanding that directory, finding nothing, and passing only via the stdin fallthrough this item removes. Removed the directory and made test_cli.sh run in a private scratch cwd.
