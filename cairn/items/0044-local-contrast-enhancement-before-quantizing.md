---
id: 44
uid: 938b7dfa-a4a6-4590-8645-75b20b9f5585
title: Local contrast enhancement before quantizing
type: feature
status: doing
milestone: fidelity
depends_on:
- 38
created: 2026-10-09
updated: 2026-10-09
priority: p2
effort: m
area: rendering
---

With 10-70 tones, global contrast is not enough. Try CLAHE-style local contrast and judge it on the corpus.

## 2026-10-09

Shipped a first cut in image_extract_pixels: -contrast-stretch 1%x1% plus -clahe 12x12%+128+3 (clahe only where ImageMagick supports it). Sweep: stretch alone 0.5764, clahe alone 0.5775, both 0.5805 (that run also had the linear-light resize); final tree 0.5792 vs 0.5745 baseline. Biggest gains on mona-lisa/hubble/checker at 160 columns; rose and 40-column line art got slightly worse. It is on by default with no opt-out flag yet, which still needs deciding.

## 2026-10-09

Made it a choice, per the owner: --enhance <off|stretch|full> and config key enhance (default full), validated like every other option, with completions (bash, zsh), .gummywormrc.example, cli-reference, configuration, README and CHANGELOG entries, and tests. bench.sh takes BENCH_FLAGS so a run can be 'off' vs 'full'. Default stays full, so output changes for existing invocations; flipping it to off is a one-line change to DEFAULT_ENHANCE in lib/config.sh.
