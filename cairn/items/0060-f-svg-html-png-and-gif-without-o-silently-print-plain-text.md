---
id: 60
uid: 093f9c85-0124-4fae-ba83-318ad9a9135d
title: -f svg, html, png and gif without -o silently print plain text
type: bug
status: done
milestone: v2.5.0
created: 2026-10-09
updated: 2026-10-09
closed_at: 2026-10-09
priority: p1
effort: m
area: cli
---

The format is ignored when output goes to stdout, so 'gummyworm -f svg photo.jpg' prints ASCII and exits 0. Text-based formats should go to stdout; binary formats should refuse a terminal and otherwise write to the pipe.

## 2026-10-09

Text formats go to stdout via a temp file and export_content, so every format shares one code path. png/gif refuse a terminal. Verified under a pty, not just with pipes.
