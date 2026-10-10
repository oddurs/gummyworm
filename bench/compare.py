#!/usr/bin/env python3
"""Build a self-contained HTML page comparing two benchmark runs.

usage: compare.py <corpus-dir> <before-run-dir> <after-run-dir> <out.html>

Each run directory holds scores.tsv (name, width, ssim) and NAME.WIDTH.txt
renders, as written by `bench.sh render`. The page shows, per corpus image, the
source beside both renders and the score change, regressions first.
"""
import base64
import html
import os
import re
import subprocess
import sys
from pathlib import Path


ANSI = re.compile(r"\x1b\[([0-9;]*)m")


def read_scores(run):
    """name, width -> dict(ssim, de, gain, chroma). Older runs have only SSIM."""
    scores = {}
    for line in (run / "scores.tsv").read_text().splitlines():
        f = line.split("\t")
        row = {"ssim": float(f[2])}
        if len(f) >= 6:
            row.update(de=float(f[3]), gain=float(f[4]), chroma=float(f[5]))
        scores[(f[0], int(f[1]))] = row
    return scores


def read_meta(run):
    ref = (run / "ref").read_text().strip() if (run / "ref").exists() else "?"
    commit = (run / "commit").read_text().strip() if (run / "commit").exists() else ""
    return {"label": run.name, "ref": ref, "commit": commit}


def thumb(path):
    """Source thumbnail as a data URI (JPEG, 480px wide at most)."""
    data = subprocess.run(
        ["magick", str(path), "-background", "black", "-alpha", "remove",
         "-resize", "480x480>", "-quality", "80", "-strip", "jpg:-"],
        check=True, capture_output=True).stdout
    return "data:image/jpeg;base64," + base64.b64encode(data).decode()


def ansi_to_html(text):
    """Truecolor ANSI text to HTML spans. Runs of one colour share a span."""
    out, color, buf = [], None, []

    def flush():
        if buf:
            chunk = html.escape("".join(buf))
            out.append(f'<span style="color:{color}">{chunk}</span>' if color else chunk)
            buf.clear()

    pos = 0
    for m in ANSI.finditer(text):
        buf.append(text[pos:m.start()])
        pos = m.end()
        codes = m.group(1).split(";")
        new = color
        if codes == ["0"] or codes == [""]:
            new = None
        elif codes[:2] == ["38", "2"] and len(codes) >= 5:
            new = "#%02x%02x%02x" % tuple(int(c) for c in codes[2:5])
        if new != color:
            flush()
            color = new
    buf.append(text[pos:])
    flush()
    return "".join(out)


def mean(xs):
    xs = list(xs)
    return sum(xs) / len(xs) if xs else float("nan")


def main():
    corpus, before_dir, after_dir, out = (Path(a) for a in sys.argv[1:5])
    before, after = read_scores(before_dir), read_scores(after_dir)
    meta_b, meta_a = read_meta(before_dir), read_meta(after_dir)
    sources = {p.stem: p for p in sorted(corpus.rglob("*"))
               if p.suffix in (".png", ".jpg")}
    keys = sorted(set(before) & set(after))
    # COMPARE_WIDTHS="40 80" keeps the page small: colour renders cost a span
    # per character, which adds up at 160 columns.
    only = os.environ.get("COMPARE_WIDTHS", "").split()
    if only:
        keys = [k for k in keys if str(k[1]) in only]
    widths = sorted({w for _, w in keys})
    names = sorted({n for n, _ in keys})
    has_color = all("de" in before[k] and "de" in after[k] for k in keys)

    def avg(scores, field, w=None):
        return mean(scores[k][field] for k in keys if w is None or k[1] == w)

    # Order by the headline measure: colour error if there is one, else SSIM.
    # Worst first, so a regression is the first thing on the page.
    def change(n, w=None):
        ws = [w] if w else widths
        if has_color:
            return mean(before[(n, x)]["de"] - after[(n, x)]["de"] for x in ws)  # positive = better
        return mean(after[(n, x)]["ssim"] - before[(n, x)]["ssim"] for x in ws)

    order = sorted(names, key=change)
    improved = sum(1 for n in names if change(n) > (0.05 if has_color else 0.0005))
    regressed = sum(1 for n in names if change(n) < -(0.05 if has_color else 0.0005))

    def cls(x):
        eps = 0.05 if has_color else 0.0005
        return "up" if x > eps else "down" if x < -eps else "flat"

    def fmt(x):
        return f"{x:+.2f}" if has_color else f"{x:+.3f}"

    def pane(run_dir, scores, name, w, which):
        sc = scores[(name, w)]
        ans = run_dir / f"{name}.{w}.ans"
        txt = (run_dir / f"{name}.{w}.txt").read_text()
        body = ansi_to_html(ans.read_text()) if has_color and ans.exists() else html.escape(txt)
        head = f'{which}<b>{sc["de"]:.1f}</b>' if has_color else f'{which}<b>{sc["ssim"]:.3f}</b>'
        return (f'<figure class="pane"><figcaption><span>{which}</span>'
                f'<b>{"ΔE " + format(sc["de"], ".1f") if has_color else format(sc["ssim"], ".3f")}</b></figcaption>'
                f'<pre style="--cols:{w}">{body}</pre></figure>')

    cards = []
    for n in order:
        views = []
        for w in widths:
            if (n, w) not in before or (n, w) not in after:
                continue
            d = change(n, w)
            extra = ""
            if has_color:
                b, a = before[(n, w)], after[(n, w)]
                extra = (f' · brightness needed ×{b["gain"]:.0f} → ×{a["gain"]:.0f}'
                         f' · saturation kept {b["chroma"]:.0%} → {a["chroma"]:.0%}')
            views.append(
                f'<div class="view w{w}"><div class="row">'
                f'{pane(before_dir, before, n, w, "before")}'
                f'{pane(after_dir, after, n, w, "after")}'
                f'</div><p class="d {cls(d)}">{"colour error" if has_color else "SSIM"} '
                f'{fmt(-d if has_color else d)} at {w} columns{extra}</p></div>')
        cards.append(
            f'<section class="card"><header><h2>{html.escape(n)}</h2>'
            f'<span class="badge {cls(change(n))}">{fmt(-change(n) if has_color else change(n))}</span></header>'
            f'<div class="body"><figure class="src"><img alt="{html.escape(n)} source" '
            f'src="{thumb(sources[n])}"><figcaption>source</figcaption></figure>'
            f'<div class="views">{"".join(views)}</div></div></section>')

    default_w = 80 if 80 in widths else widths[0]
    field = "de" if has_color else "ssim"
    buttons = "".join(
        f'<button data-w="{w}"{" class=on" if w == default_w else ""}>{w} cols'
        f'<small>{avg(before, field, w):.2f} → {avg(after, field, w):.2f}</small></button>' for w in widths)

    def ref_text(m):
        return f'{html.escape(m["ref"])}' + (f' <code>{m["commit"]}</code>' if m["commit"] else "")

    if has_color:
        stats = (
            ("colour error (ΔE, lower is better)", f'{avg(before, "de"):.1f} → {avg(after, "de"):.1f}', cls(avg(before, "de") - avg(after, "de"))),
            ("saturation kept", f'{avg(before, "chroma"):.0%} → {avg(after, "chroma"):.0%}', cls(avg(after, "chroma") - avg(before, "chroma"))),
            ("brightness needed", f'×{avg(before, "gain"):.0f} → ×{avg(after, "gain"):.0f}', cls(avg(before, "gain") - avg(after, "gain"))),
            ("images better", str(improved), "up"), ("images worse", str(regressed), "down"))
        sub = ("Colour error is the distance between source and render in OKLab after both are "
               "reduced to 24 by 24 in linear light and the render's white point is matched to the "
               "source. Brightness needed is how many times brighter the source's highlights are; "
               "a glyph covers only part of its cell, so every render is dimmer. Terminals below are "
               "black. Worst first.")
    else:
        stats = (
            ("mean SSIM", f'{avg(before, "ssim"):.3f} → {avg(after, "ssim"):.3f}', cls(avg(after, "ssim") - avg(before, "ssim"))),
            ("images better", str(improved), "up"), ("images worse", str(regressed), "down"))
        sub = "Score is SSIM against the source after both are reduced to 200 by 200 grey. Worst first."
    stat_html = "".join(f'<div class="stat"><span>{html.escape(l)}</span><b class="{c}">{v}</b></div>' for l, v, c in stats)

    page = TEMPLATE.format(
        before=ref_text(meta_b), after=ref_text(meta_a), sub=sub, stats=stat_html,
        buttons=buttons, cards="\n".join(cards), default_w=default_w)
    out.write_text(page)


TEMPLATE = """<title>Gummyworm Fidelity</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=IBM+Plex+Sans:wght@400;600&display=swap">
<style>
/* Layout: summary strip, sticky width switch, then one card per corpus image
   with the source on the left and before/after terminals side by side. */
:root{{--bg:#f6f6f4;--fg:#1d1f1e;--mut:#6b706d;--card:#fff;--line:#dedfdb;
--term:#101312;--termfg:#d8ddd9;--up:#17703a;--down:#b3261e;--flat:#6b706d;--acc:#2f6f5e;
--sans:"IBM Plex Sans",system-ui,sans-serif;--mono:"IBM Plex Mono",ui-monospace,Menlo,monospace}}
@media (prefers-color-scheme:dark){{:root:not([data-theme="light"]){{--bg:#0e1110;--fg:#e4e7e4;--mut:#9aa09c;
--card:#171b19;--line:#262c29;--term:#000;--termfg:#d8ddd9;--up:#5fd08a;--down:#ff8a80;--flat:#9aa09c;--acc:#6cc4a8;color-scheme:dark}}}}
:root[data-theme="dark"]{{--bg:#0e1110;--fg:#e4e7e4;--mut:#9aa09c;
--card:#171b19;--line:#262c29;--term:#000;--termfg:#d8ddd9;--up:#5fd08a;--down:#ff8a80;--flat:#9aa09c;--acc:#6cc4a8;color-scheme:dark}}
body{{background:var(--bg);color:var(--fg);font:15px/1.5 var(--sans)}}
main{{max-width:1180px;margin:0 auto;padding-inline:16px;padding-block:32px 64px}}
h1{{font-size:28px;margin:0 0 6px;text-wrap:balance}} h2{{font-size:17px;margin:0;font-family:var(--mono);font-weight:600}}
.sub{{color:var(--mut);margin:0 0 24px;max-width:70ch}}
code{{font:12px var(--mono)}}
.summary{{display:flex;flex-wrap:wrap;gap:12px;margin-bottom:20px}}
.stat{{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:12px 16px;min-width:150px}}
.stat b{{display:block;font:600 24px var(--mono);font-variant-numeric:tabular-nums}}
.stat span{{color:var(--mut);font-size:13px}}
.up{{color:var(--up)}} .down{{color:var(--down)}} .flat{{color:var(--flat)}}
.bar{{display:flex;gap:8px;flex-wrap:wrap;margin:8px 0 24px;position:sticky;top:env(safe-area-inset-top,0px);background:var(--bg);padding-block:8px;z-index:2}}
button{{font:inherit;background:var(--card);color:var(--fg);border:1px solid var(--line);border-radius:8px;
padding:6px 14px;cursor:pointer;text-align:left}}
button:focus-visible{{outline:2px solid var(--acc);outline-offset:2px}}
button small{{display:block;color:var(--mut);font:12px var(--mono);font-variant-numeric:tabular-nums}}
button.on{{border-color:var(--acc);box-shadow:0 0 0 1px var(--acc)}}
.card{{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:16px;margin-bottom:20px}}
.card header{{display:flex;align-items:center;gap:10px;margin-bottom:12px}}
.badge{{font:600 13px var(--mono);border:1px solid currentColor;border-radius:99px;padding:1px 9px}}
.body{{display:grid;grid-template-columns:200px minmax(0,1fr);gap:16px;align-items:start}}
.src img{{width:100%;border-radius:4px;display:block}}
figure{{margin:0}} figcaption{{color:var(--mut);font-size:12px;margin-bottom:4px;display:flex;justify-content:space-between}}
figcaption b{{color:var(--fg);font:600 12px var(--mono);font-variant-numeric:tabular-nums}}
.row{{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:12px}}
.pane{{container-type:inline-size;min-width:0}}
pre{{margin:0;background:var(--term);color:var(--termfg);border-radius:4px;padding:8px;overflow:hidden;
font-family:var(--mono);line-height:1.2;white-space:pre;
font-size:calc((100cqw - 16px) / (var(--cols) * 0.6))}}
.d{{margin:6px 0 0;font:13px var(--mono)}}
.view{{display:none}} main[data-w="40"] .w40,main[data-w="80"] .w80,main[data-w="160"] .w160{{display:block}}
@media(max-width:760px){{.body{{grid-template-columns:minmax(0,1fr)}} .src{{max-width:240px}}}}
</style>
<main data-w="{default_w}">
<h1>Rendering fidelity, before and after</h1>
<p class="sub">before: {before}. after: {after}. {sub}</p>
<div class="summary">{stats}</div>
<div class="bar">{buttons}</div>
{cards}
</main>
<script>
(function(){{
  var m=document.querySelector('main');
  document.querySelectorAll('.bar button').forEach(function(b){{
    b.addEventListener('click',function(){{
      m.dataset.w=b.dataset.w;
      document.querySelectorAll('.bar button').forEach(function(x){{x.classList.toggle('on',x===b)}});
    }});
  }});
}})();
</script>
"""

if __name__ == "__main__":
    main()
