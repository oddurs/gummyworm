---
id: 35
title: Numeric config values are evaluated as shell arithmetic, so a project .gummywormrc can execute commands
type: bug
status: done
milestone: v2.3.1
assignee: Oddur Sigurdsson
created: 2026-09-22
updated: 2026-09-22
priority: p0
effort: s
area: config
---

## What happens

`_load_config_file` validates `background=` and nothing else. Every other value
is copied verbatim into a `CONFIG_*` variable, seeds the matching `ARG_*`
(`parse_args` only validates values that arrive as CLI flags), and is later
used in shell arithmetic — `$(( ))` and `[[ -eq ]]`.

Bash evaluates a variable's *value* as an arithmetic expression, array
subscripts included, and a subscript undergoes command substitution. So:

```sh
cd cloned-repo            # contains .gummywormrc: width=HOME[$(touch PWNED)]
gummyworm photo.png       # PWNED now exists
```

Verified on bash 5.3.9 and on macOS's /bin/bash 3.2.57, via both `width=` and
`height=`. The primitive itself executes on both versions:

```
x='a[$(touch m)]'; $(( x * 2 ))     # runs touch
x='a[$(touch m)]'; [[ $x -eq 0 ]]   # runs touch
```

`set -u` blocks the naive payload only incidentally — `a[...]` fails as an
unbound variable before the subscript runs — but any variable that is set
(`HOME`, `PATH`) works as the array name.

The other numeric keys (`padding`, `brightness`, `contrast`, `frame_delay`,
`max_frames`, `loops`) did not fire on a plain text render only because that
path never reaches their arithmetic. They reach it in export or animation
modes and must be treated as equally exposed.

## Impact

`./.gummywormrc` is read from the current directory, so it travels with any
repository or archive. Running gummyworm inside one is enough — no flag, no
confirmation. Affects the published v2.3.0 and every earlier release with
config support (2.2.0+).

## Fix

- Validate every key in `_load_config_file` with the same rules as its CLI
  flag, and ignore an invalid value with a warning, matching `background=`.
- Defence in depth: `calc_dimensions` rejects non-integer target dimensions
  before any arithmetic, as it already does for source dimensions.

## Acceptance criteria

- [x] Every numeric and boolean config key is validated against the same rules as its CLI flag
- [x] An invalid config value is ignored with a warning and the default kept
- [x] The HOME[$(touch ...)] payload executes nothing via any key, on bash 3.2 and 5
- [x] Valid config values for every key still take effect
- [x] An end-to-end test runs gummyworm in a directory with a malicious .gummywormrc and asserts nothing executed

## 2026-09-22

Measured on the published v2.3.0 with a payload per key across text, svg and animated-gif modes: 10 of 57 combinations executed a command, via width, height, padding, frame_delay and max_frames. After the fix: 0 of 57 on bash 5.3.9 and 0 of 57 on /bin/bash 3.2.57. The fix is validation at the point of entry, not guarding each arithmetic sink: there are too many sinks, and entry validation is the control that scales. The warning deliberately does not echo the rejected value, which came from a file that may not be the user's. Moved into v2.3.1 rather than v2.4.0: nothing after v2.3.0 had been pushed, so the fix was committed before the v2.3.1 release commit and the v2.4.0 work replayed on top.
