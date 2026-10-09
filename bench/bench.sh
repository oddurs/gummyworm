#!/usr/bin/env bash
# ============================================================================
# gummyworm/bench/bench.sh - Rendering fidelity benchmark
# ============================================================================
# Renders a fixed corpus, scores each render against its source, and compares
# two runs side by side so a change to the renderer can be judged by eye and by
# number.
#
#   bench.sh corpus                       build the synthetic part of the corpus
#   bench.sh render <label> [--ref REF]   render + score; REF is a git ref to
#                                         render with instead of the working tree
#   bench.sh compare <before> <after> [out.html]
#
# Score is SSIM between the source and the render rasterised back to an image,
# both reduced to 200x200 greyscale so it measures what survives at a glance,
# not glyph-level pixel alignment. 1.0 is identical.
# ============================================================================
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$BENCH_DIR/.." && pwd)"
CORPUS="$BENCH_DIR/corpus"
OUT="$BENCH_DIR/out"
WIDTHS="${BENCH_WIDTHS:-40 80 160}"
# Extra gummyworm flags for a run, e.g. BENCH_FLAGS="--enhance off". Unquoted on
# purpose so several flags split; the corpus paths never go through it.
FLAGS="${BENCH_FLAGS:-}"

die() { echo "bench: $*" >&2; exit 1; }

cmd_corpus() {
    local d="$CORPUS/synthetic"
    mkdir -p "$d"
    magick -size 640x400 gradient:black-white "$d/gradient.png"
    magick -size 640x400 radial-gradient:white-black "$d/radial.png"
    magick -size 640x400 pattern:checkerboard -scale 400% "$d/checker.png"
    magick -seed 3 -size 640x400 plasma:fractal -colorspace sRGB "$d/plasma.png"
    magick -size 640x400 xc:black -fill white -stroke white -strokewidth 6 \
        -draw "circle 320,200 320,60" -draw "line 40,360 600,40" \
        -fill none -draw "rectangle 60,60 220,180" -draw "ellipse 470,290 120,60 0,360" \
        "$d/lineart.png"
    # text.png is committed rather than generated: it needs a system font, so
    # rebuilding it would change the corpus from one machine to the next.
    magick rose: -resize 640x -filter Lanczos -level 35%,65% "$d/low-contrast.png"
    magick rose: -resize 640x -filter Lanczos "$d/rose.png"
    magick logo: "$d/logo.png"
    magick wizard: "$d/wizard.png"
    echo "corpus: $(find "$CORPUS" -type f \( -name '*.png' -o -name '*.jpg' \) | wc -l | tr -d ' ') images"
}

corpus_files() {
    find "$CORPUS" -type f \( -name '*.png' -o -name '*.jpg' \) | sort
}

# SSIM of two images after reducing both to 200x200 greyscale.
ssim() {
    local a="$1" b="$2" v
    v=$(magick compare -metric SSIM \
            \( "$a" -background black -alpha remove -colorspace Gray -resize 200x200! \) \
            \( "$b" -background black -alpha remove -colorspace Gray -resize 200x200! \) \
            null: 2>&1 | sed -n 's/.*(\(.*\)).*/\1/p')
    awk -v d="${v:-1}" 'BEGIN { printf "%.4f", 1 - d }'
}

cmd_render() {
    local label="${1:-}" ref="" worktree="" gw
    [[ -n "$label" ]] || die "render needs a label"
    shift
    if [[ "${1:-}" == "--ref" ]]; then
        ref="${2:-}"; [[ -n "$ref" ]] || die "--ref needs a git ref"
        worktree="$(mktemp -d)"
        git -C "$ROOT" worktree add --detach "$worktree/wt" "$ref" >/dev/null 2>&1 \
            || die "cannot check out $ref"
        # shellcheck disable=SC2064
        trap "git -C '$ROOT' worktree remove --force '$worktree/wt' >/dev/null 2>&1; rm -rf '$worktree'" EXIT
        gw="$worktree/wt/bin/gummyworm"
    else
        gw="$ROOT/bin/gummyworm"
    fi

    local dir="$OUT/$label"
    rm -rf "$dir"; mkdir -p "$dir"
    printf '%s\n' "${ref:-working tree}${FLAGS:+ ($FLAGS)}" > "$dir/ref"
    git -C "$ROOT" rev-parse --short "${ref:-HEAD}" > "$dir/commit" 2>/dev/null || true
    : > "$dir/scores.tsv"

    local f name w
    while IFS= read -r f; do
        name="$(basename "$f")"; name="${name%.*}"
        for w in $WIDTHS; do
            "$gw" -q -w "$w" $FLAGS -- "$f" > "$dir/$name.$w.txt" 2>/dev/null \
                || { echo "bench: render failed: $name @ $w" >&2; continue; }
            "$gw" -q -w "$w" $FLAGS -f png --background '#000000' --padding 0 \
                -o "$dir/$name.$w.png" -- "$f" >/dev/null 2>&1 \
                || { echo "bench: raster failed: $name @ $w" >&2; continue; }
            printf '%s\t%s\t%s\n' "$name" "$w" "$(ssim "$f" "$dir/$name.$w.png")" >> "$dir/scores.tsv"
        done
        echo "  rendered $name" >&2
    done < <(corpus_files)

    awk -F'\t' '{ s += $3; n++ } END { printf "mean SSIM %.4f over %d renders\n", s/n, n }' "$dir/scores.tsv"
}

cmd_compare() {
    local before="${1:-}" after="${2:-}" html="${3:-$OUT/compare.html}"
    [[ -d "$OUT/$before" && -d "$OUT/$after" ]] || die "both runs must be rendered first"
    python3 "$BENCH_DIR/compare.py" "$CORPUS" "$OUT/$before" "$OUT/$after" "$html"
    echo "wrote $html"
}

case "${1:-}" in
    corpus)  shift; cmd_corpus "$@" ;;
    render)  shift; cmd_render "$@" ;;
    compare) shift; cmd_compare "$@" ;;
    *) sed -n '3,20p' "${BASH_SOURCE[0]}"; exit 2 ;;
esac
