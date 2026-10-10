---
id: 70
uid: 2eb6e3ce-e551-4148-9820-4b351a1c0c69
title: A --classic switch for the previous rendering
type: feature
status: done
milestone: color-engine
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p1
effort: s
area: cli
---

One switch that restores the pre-2.4 look for people who prefer it: --enhance off plus --color-engine plain. Config key classic. Explicit --enhance and --color-engine still win, on the command line and in the config file.

## 2026-10-09

Four-way benchmark (42 renders): classic off+plain SSIM 0.5745 dE 11.25 gain x37 chroma 0.74; off+optical 0.5765 / 8.90 / x20 / 0.87; full+plain 0.5792 / 11.13 / x23 / 0.78; default full+optical 0.5838 / 9.74 / x16 / 0.92. Default is best on structure, brightness and saturation; off+optical is best on colour error, because dE is measured against the unenhanced source and so charges the enhance step for changing tones on purpose. Explicit enhance/color_engine beat classic in either order, on the command line and in config files.
