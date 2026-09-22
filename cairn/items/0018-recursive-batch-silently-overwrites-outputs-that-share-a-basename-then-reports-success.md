---
id: 18
title: Recursive batch silently overwrites outputs that share a basename, then reports success
type: bug
status: done
milestone: v2.3.0
assignee: Oddur Sigurdsson
created: 2026-09-21
updated: 2026-09-21
priority: p1
effort: m
area: cli
---

## What happens

Batch output is named from the input's basename alone, so two inputs in
different subdirectories that share a name write to the same file. The second
overwrites the first.

```sh
src/one/image.png   # a circle
src/two/image.png   # a filled square  (different file, different checksum)

gummyworm -w 10 -f html -r -d out/ src/
```

```
✔ Saved to: out/image.ascii.html
[2/2] Converting: image.png (30x30)
✔ Saved to: out/image.ascii.html
✔ Completed: 2 images processed successfully
exit 0
```

One file on disk. The tool reports two successes and exits 0.

## Why it matters

`-r` exists to walk a directory tree, which is exactly where repeated basenames
are normal — `2024/cover.jpg`, `2025/cover.jpg`, or a `thumbnail.png` per
album. The failure is silent and destroys output the user asked for, and the
success message actively says otherwise.

## Direction

Options, roughly in order of preference:

1. Mirror the input's directory structure under `--output-dir`. Preserves every
   output and is predictable, at the cost of creating subdirectories.
2. Disambiguate a collision by suffixing, and say so on stderr.
3. Detect the collision up front and refuse, naming the inputs that clash.

Whichever is chosen, the "N images processed successfully" line must not count
an image whose output was overwritten by a later one.

## Acceptance criteria

- [x] Two inputs with the same basename in different directories both produce output
- [x] No output file is overwritten without the user being told
- [x] The completion count reflects files actually written
- [x] A test covers the recursive same-basename case end to end

## 2026-09-21

Fixed in two parts: parse_args now records the directory argument each image was expanded from in ARG_IMAGE_ROOTS (index-aligned with ARG_IMAGES), so recursive batches mirror the input tree under --output-dir; and _unique_output_path guards every other case, warning and appending -2/-3 rather than overwriting. Mirroring alone was not enough — two files named directly from different directories have no root and still collided. _unique_output_path returns via _UNIQUE_OUTPUT_PATH rather than stdout because it appends to the caller's written_outputs array, and a command substitution would run it in a subshell where that append is discarded (this was caught in verification). Non-recursive directory input still lands flat, unchanged.
