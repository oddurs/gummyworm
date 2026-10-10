#!/usr/bin/env bash
# ============================================================================
# release.sh - Point the Homebrew formula at a published gummyworm release
# ============================================================================
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 2.3.1
#
# Run this AFTER the tag is pushed. It:
# 1. Checks that tag v<version> exists locally and on origin
# 2. Downloads GitHub's archive for that tag and hashes it
# 3. Writes the url, version and sha256 into Formula/gummyworm.rb
#
# The hash has to come from GitHub's archive, because that is the file the
# formula's url serves and the file brew verifies. An earlier version of this
# script built its own tarball from the working tree and hashed that instead:
# different top-level directory, different contents, uncommitted changes
# included -- so the hash it wrote could never match the url beside it.
#
# Environment:
#   GUMMYWORM_FORMULA   formula to update (default: Formula/gummyworm.rb)
#   GUMMYWORM_REMOTE    git remote holding the tag (default: origin)
#
# Compatibility: macOS, Linux, FreeBSD
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO_URL="https://github.com/oddurs/gummyworm"
FORMULA_PATH="${GUMMYWORM_FORMULA:-$PROJECT_ROOT/Formula/gummyworm.rb}"
REMOTE="${GUMMYWORM_REMOTE:-origin}"

# Detect platform for portable commands
PLATFORM="unknown"
case "$(uname -s)" in
    Darwin*)  PLATFORM="macos" ;;
    Linux*)   PLATFORM="linux" ;;
    FreeBSD*) PLATFORM="freebsd" ;;
    *)        PLATFORM="unknown" ;;
esac

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die() { log_error "$*"; exit 1; }

# Portable sed in-place editing
sed_inplace() {
    if [[ "$PLATFORM" == "macos" || "$PLATFORM" == "freebsd" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Portable SHA256 of stdin
sha256_stdin() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{print $1}'
    else
        sha256sum | awk '{print $1}'
    fi
}

usage() {
    echo "Usage: $0 <version>"
    echo "Example: $0 2.3.1"
    echo ""
    echo "Tag and push v<version> first; this script hashes the published archive."
    exit 1
}

# Check arguments
if [[ $# -ne 1 ]]; then
    usage
fi

VERSION="$1"
TAG="v${VERSION}"

# Validate version format (basic semver)
# Store regex in variable for Bash 3.2 compatibility
re_version='^[0-9]+\.[0-9]+\.[0-9]+$'
if [[ ! "$VERSION" =~ $re_version ]]; then
    die "Invalid version format. Use semver: X.Y.Z"
fi

cd "$PROJECT_ROOT"

[[ -f "$FORMULA_PATH" ]] || die "Formula not found at $FORMULA_PATH"

# The tag must exist here...
if ! git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
    die "Tag ${TAG} does not exist locally. Tag the release first: git tag -a ${TAG}"
fi

# ...and be published, or GitHub has no archive to hash.
if ! git ls-remote --exit-code --tags "$REMOTE" "refs/tags/${TAG}" >/dev/null 2>&1; then
    die "Tag ${TAG} is not on ${REMOTE}. Push it first: git push ${REMOTE} ${TAG}"
fi

# The published tag must be the one we have, or we would hash something else.
local_sha=$(git rev-parse "${TAG}^{commit}")
remote_sha=$(git ls-remote --tags "$REMOTE" "refs/tags/${TAG}^{}" | awk '{print $1}')
if [[ -z "$remote_sha" ]]; then
    # Lightweight tag: no peeled entry, the ref itself names the commit
    remote_sha=$(git ls-remote --tags "$REMOTE" "refs/tags/${TAG}" | awk '{print $1}')
fi
if [[ "$local_sha" != "$remote_sha" ]]; then
    die "Local ${TAG} (${local_sha}) differs from ${REMOTE} (${remote_sha}). Refusing to hash a tag that is not the one published."
fi

URL="${REPO_URL}/archive/refs/tags/${TAG}.tar.gz"
log_info "Hashing published archive: $URL"

command -v curl >/dev/null 2>&1 || die "curl is required"
SHA256=$(curl -fsSL "$URL" | sha256_stdin) || die "Failed to download $URL"

# An empty download hashes to this; never write it into a formula
readonly EMPTY_SHA256="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
if [[ -z "$SHA256" || "$SHA256" == "$EMPTY_SHA256" ]]; then
    die "Downloaded archive was empty; not updating the formula"
fi

log_info "SHA256: $SHA256"
log_info "Updating $(basename "$FORMULA_PATH")..."

sed_inplace -E "s|^([[:space:]]*url \")[^\"]*(\")|\\1${URL}\\2|" "$FORMULA_PATH"
sed_inplace -E "s|^([[:space:]]*sha256 \")[^\"]*(\")|\\1${SHA256}\\2|" "$FORMULA_PATH"
sed_inplace -E "s|^([[:space:]]*version \")[^\"]*(\")|\\1${VERSION}\\2|" "$FORMULA_PATH"

# Confirm every field landed, rather than trusting three seds silently
grep -q "url \"${URL}\"" "$FORMULA_PATH"        || die "url was not updated"
grep -q "sha256 \"${SHA256}\"" "$FORMULA_PATH"  || die "sha256 was not updated"
if grep -q '^[[:space:]]*version "' "$FORMULA_PATH"; then
    grep -q "version \"${VERSION}\"" "$FORMULA_PATH" || die "version was not updated"
fi

echo ""
log_info "Formula now points at ${TAG}."
echo ""
echo "Next steps:"
echo "  1. Review:  git diff -- $(basename "$(dirname "$FORMULA_PATH")")/$(basename "$FORMULA_PATH")"
echo "  2. Commit:  git commit -am 'Point formula at ${TAG}'"
echo "  3. Push:    git push ${REMOTE} main"
echo "  4. Release: gh release create ${TAG} --notes-file <notes>"
echo ""
echo "If you publish through a separate tap, copy the formula there as well:"
echo "  homebrew-gummyworm/Formula/gummyworm.rb"
