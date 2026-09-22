---
id: 20
title: release.sh prints a SHA256 that can never match the URL it prints
type: bug
status: done
milestone: v2.3.1
assignee: Oddur Sigurdsson
created: 2026-09-21
updated: 2026-09-22
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

- [x] The hash written into the formula is the hash of the artefact the URL serves
- [x] The script fails clearly if the tag is not pushed yet, rather than hashing something else
- [x] The printed "next steps" describe an order that actually works
- [x] Formula/gummyworm.rb is bumped to the current release and verified with `brew audit` or an equivalent check

## 2026-09-22

Formula now points at v2.3.0, the latest published release; the sha256 matches an independent download of the url. brew 6 refuses to load a formula from a file path and a throwaway tap would modify the user's Homebrew install, so verification was: ruby -c, independent checksum, every path the install block uses present in the published tarball, and the formula's own test block run against a simulated libexec layout. Once v2.3.1 is pushed, 'scripts/release.sh 2.3.1' moves the formula to it.
