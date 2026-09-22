---
id: 20
title: release.sh prints a SHA256 that can never match the URL it prints
type: bug
status: backlog
milestone: later
created: 2026-09-21
updated: 2026-09-21
priority: p2
effort: s
area: release
---

## What happens

`scripts/release.sh` builds its own tarball from the working tree and hashes
that (`scripts/release.sh:80-96`):

```sh
tar --exclude='.git' --exclude='scripts' ... -czf "$TARBALL_PATH" \
    -C "$PROJECT_ROOT/.." "$(basename "$PROJECT_ROOT")"
SHA256=$(shasum -a 256 "$TARBALL_PATH" | awk '{print $1}')
```

then prints that hash next to GitHub's archive URL, and writes both into the
formula (`scripts/release.sh:104-112`, `:129-132`):

```
URL: https://github.com/oddurs/gummyworm/archive/refs/tags/v${VERSION}.tar.gz
SHA256: ${SHA256}
```

The two tarballs cannot hash the same. They differ in at least:

- top-level directory — `gummyworm/` here, `gummyworm-2.3.0/` from GitHub
- contents — this one excludes `scripts/`, which GitHub's archive includes
- source — this one is the *working tree*, uncommitted changes and all, rather
  than the tag
- compression — gzip output is not reproducible across implementations anyway

So `brew install` against a formula written by this script fails its checksum
verification. The formula's last bump (`d08feef`) was done by hand, which is
consistent with the script not being usable for the job.

## What should happen

For a formula pointing at GitHub's archive, the hash has to come from that
archive:

```sh
curl -sL "https://github.com/oddurs/gummyworm/archive/refs/tags/v${VERSION}.tar.gz" \
  | shasum -a 256
```

which means the tag has to exist and be pushed first — worth stating in the
script's own "next steps" output, which currently tells the user to tag *after*
running it.

## Related

`Formula/gummyworm.rb` is still pinned to v2.2.0, so v2.3.0 is not installable
via brew. Fixing the script and bumping the formula belong together.

## Acceptance criteria

- [ ] The hash written into the formula is the hash of the artefact the URL serves
- [ ] The script fails clearly if the tag is not pushed yet, rather than hashing something else
- [ ] The printed "next steps" describe an order that actually works
- [ ] Formula/gummyworm.rb is bumped to the current release and verified with `brew audit` or an equivalent check
