#!/usr/bin/env python3
"""Perceptual colour score for one render.

usage: colorscore.py <source> <render>

Both images are reduced to 24x24 in linear light, which is what the eye does
with a cell of glyphs and the dark space between them, then compared in OKLab.
Prints three numbers, tab separated:

  de      mean OKLab delta-E (x100) after matching the white point. Lower is
          better. Measures hue, saturation and relative contrast.
  gain    how many times brighter the source's highlights are than the render's
          (98th percentile of luminance, so a small bright area counts as much
          as a large one, and a mostly black image is not penalised). 1.0
          means as bright; 2.0 means the render is half as bright. This is not
          held against de, because a display cannot always reach the source's
          brightness, but it is reported so a dim engine cannot hide.
  chroma  mean chroma of the exposure-matched render over the source's. 1.0
          keeps the saturation; below 1.0 the colours have washed out.
"""
import re
import subprocess
import sys

SIZE = 24
PIXEL = re.compile(r"^\d+,\d+:\s*\(\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)")


def linear_pixels(path):
    out = subprocess.run(
        ["magick", path, "-background", "black", "-alpha", "remove", "-alpha", "off",
         "-colorspace", "sRGB", "-type", "TrueColor", "-colorspace", "RGB",
         "-filter", "Box", "-resize", f"{SIZE}x{SIZE}!", "-depth", "16", "txt:-"],
        check=True, capture_output=True, text=True).stdout
    px = []
    for line in out.splitlines():
        m = PIXEL.match(line)
        if m:
            px.append(tuple(float(v) / 65535.0 for v in m.groups()))
    return px


def oklab(rgb):
    r, g, b = rgb
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def luminance(rgb):
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]


def percentile(values, q=0.98):
    values = sorted(values)
    return values[min(len(values) - 1, int(q * len(values)))]


def main():
    src, ren = linear_pixels(sys.argv[1]), linear_pixels(sys.argv[2])
    n = min(len(src), len(ren))
    ys, yr = percentile([luminance(p) for p in src[:n]]), percentile([luminance(p) for p in ren[:n]])
    k = ys / yr if yr > 1e-9 else 1.0
    de = chroma_s = chroma_r = 0.0
    for a, b in zip(src[:n], ren[:n]):
        b = tuple(min(1.0, k * c) for c in b)
        la, lb = oklab(a), oklab(b)
        de += 100 * sum((x - y) ** 2 for x, y in zip(la, lb)) ** 0.5
        chroma_s += (la[1] ** 2 + la[2] ** 2) ** 0.5
        chroma_r += (lb[1] ** 2 + lb[2] ** 2) ** 0.5
    ratio = chroma_r / chroma_s if chroma_s > 1e-9 else 1.0
    print(f"{de / n:.3f}\t{k:.3f}\t{ratio:.3f}")


if __name__ == "__main__":
    main()
