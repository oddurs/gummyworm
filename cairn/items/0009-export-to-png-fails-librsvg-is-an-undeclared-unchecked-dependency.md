---
id: 9
title: 'Export to PNG fails: librsvg is an undeclared, unchecked dependency'
type: bug
status: done
assignee: Oddur Sigurdsson
created: 2026-09-19
updated: 2026-09-19
priority: p2
effort: s
area: export
---

## What happens

```
$ ./gummyworm circle.png -w 80 -q -f png -o out.png
✖ Error: Failed to convert SVG to PNG
```

No PNG is written. Found incidentally while measuring 0004, on a clean
`brew install imagemagick`.

The PNG path renders SVG first and hands it to ImageMagick, which cannot rasterise SVG
without a delegate — `librsvg`, or Inkscape. Homebrew's `imagemagick` formula does not
pull one in, so a straightforward install of the documented dependency produces a build
where `-f png` (and presumably `-f gif`) cannot work.

Unconfirmed: whether `-f gif` fails the same way, and whether the bundled
`imagemagick-full` formula includes a delegate — the caveat on install mentions extra
tools and libraries. Worth checking both before choosing a fix.

## What should happen

Either of:

- **Detect and say so.** The startup check already handles missing ImageMagick with a
  clear install hint; extend it to check for an SVG delegate when a raster format is
  requested, and name the fix (`brew install librsvg`) instead of failing with a generic
  message at the end of the work.
- **Avoid the delegate.** Draw the raster directly rather than routing through SVG.
  More work, but removes the dependency.

Detection is the smaller change and fixes the bad first-run experience, which is the
actual harm here. Either way `README.md` should list the requirement.

## Reproduction

1. `brew install imagemagick` (without `librsvg`)
2. `./gummyworm any.png -w 80 -f png -o out.png`
3. Fails with `Failed to convert SVG to PNG`

## Acceptance criteria

- [x] Confirm whether `-f gif` is affected
- [x] Missing delegate detected before work begins, with an actionable message
- [x] Dependency documented in `README.md`

## 2026-09-19

Confirmed -f gif is affected: same failure, reported as 'Failed to generate frame 0' because export_animated_gif renders each frame through export_png. Two separate faults, not one. (1) No SVG delegate: added image_check_raster_deps in lib/image.sh, called from main once the format is resolved so it also catches auto-detection from a .png/.gif output filename; names librsvg per platform and points at svg/html as delegate-free alternatives. (2) Installing librsvg did NOT fix it. Homebrew's ImageMagick is built without librsvg (magick -list format reports SVG via XML 2.9.13, not RSVG) and will not fall back to its own rsvg delegate because it believes it renders SVG natively; its built-in renderer then dies on the SVG's font-family with 'unable to read font'. export_png now calls rsvg-convert directly and keeps ImageMagick as fallback. PNG and GIF both produce square output for a square source (576x576, 288x288).
