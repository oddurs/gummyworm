---
id: 18
title: Recursive batch silently overwrites outputs that share a basename, then reports success
type: bug
status: backlog
milestone: v2.3.0
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

- [ ] Two inputs with the same basename in different directories both produce output
- [ ] No output file is overwritten without the user being told
- [ ] The completion count reflects files actually written
- [ ] A test covers the recursive same-basename case end to end
