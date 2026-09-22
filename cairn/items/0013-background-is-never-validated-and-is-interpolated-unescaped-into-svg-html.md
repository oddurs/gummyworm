---
id: 13
title: --background is never validated and is interpolated unescaped into SVG/HTML
type: bug
status: done
milestone: v2.3.1
assignee: Oddur Sigurdsson
created: 2026-09-20
updated: 2026-09-22
priority: p1
effort: m
area: export
---

## What happens

`lib/cli.sh:277` accepts any string for `--background` with no validation, and
`lib/config.sh:219` accepts the same from a config file's `background=` key.
The value is then interpolated straight into the generated markup.

```sh
gummyworm -f html --background '"><script>x</script>' -o out.html in.png
# exit 0; out.html contains <script>x</script>
```

`lib/utils.sh` already defines `is_valid_hex_color`, and `test_zsh_compat.sh:113`
tests it — but nothing in `lib/` or `bin/` ever calls it. The validator exists,
is covered, and is wired to nothing.

## Why it matters beyond cosmetics

`background` is settable from `./.gummywormrc`, a project-local config file. A
cloned repository can therefore carry a config that injects markup into every
HTML file the user exports. The exported HTML is meant to be published, so the
injected content travels.

The narrow reading — a user passing their own flag on their own machine — is
self-inflicted and harmless. The config-file path is not, because the value does
not come from the person running the command.

## What should happen

- The color is validated where it enters, so a bad value fails fast with a clear
  message rather than silently producing broken output.
- Output escaping does not depend on validation having happened. Both SVG and
  HTML escape what they interpolate, so a future caller that skips validation
  cannot reintroduce this.

Named colors (`red`, `transparent`) are currently accepted by ImageMagick and by
CSS, so validation should allow a conservative named set as well as hex, not hex
only — otherwise this is a breaking change for anyone using `background=black`.

## Acceptance criteria

- [x] `--background` rejects a malformed value with a usage error and non-zero exit
- [x] A `background=` value from a config file is validated the same way
- [x] SVG and HTML export escape the background value on output
- [x] Valid hex (`#1e1e1e`, `#fff`) and common named colors still work
- [x] Tests cover a malformed flag, a malformed config value, and the escaping

## 2026-09-20

is_valid_hex_color turned out not to exist anywhere in lib/ or bin/ — it was referenced only by test_zsh_compat.sh, which reported PASS because of the runner bug in 0016. Implemented it and is_valid_color in config.sh rather than utils.sh: config.sh parses the config file at source time (config.sh:272-274) and is sourced before utils.sh, so a validator defined in utils.sh was command-not-found at the moment the config needed it. That first attempt silently rejected every config background, valid ones included.

## 2026-09-20

escape_markup uses sed, not ${var//&/&amp;}: bash 5.2+ reads an unquoted & in a substitution replacement as the matched text, so the parameter-expansion form emitted '<lt;' instead of '&lt;'. Verified identical output under bash 3.2.57 and 5.3.9.
