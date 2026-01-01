#!/usr/bin/env bash
# ============================================================================
# release.sh - Helper script for creating gummyworm releases
# ============================================================================
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.0.0
#
# This script:
# 1. Creates a release tarball
# 2. Calculates the SHA256 hash
# 3. Updates the Formula with the new version and hash
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
}

# Check arguments
if [[ $# -ne 1 ]]; then
    usage
fi

VERSION="$1"

# Validate version format (basic semver)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Invalid version format. Use semver: X.Y.Z"
    exit 1
fi

cd "$PROJECT_ROOT"

log_info "Creating release v${VERSION}..."

# Create release directory
RELEASE_DIR="$PROJECT_ROOT/releases"
mkdir -p "$RELEASE_DIR"

# Create tarball
TARBALL="gummyworm-${VERSION}.tar.gz"
TARBALL_PATH="$RELEASE_DIR/$TARBALL"

log_info "Creating tarball: $TARBALL"

# Create tarball excluding unnecessary files
tar --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='.DS_Store' \
    --exclude='releases' \
    --exclude='scripts' \
    --exclude='*.tar.gz' \
    -czf "$TARBALL_PATH" \
    -C "$PROJECT_ROOT/.." \
    "$(basename "$PROJECT_ROOT")"

# Calculate SHA256
SHA256=$(shasum -a 256 "$TARBALL_PATH" | awk '{print $1}')

log_info "SHA256: $SHA256"

# Update Formula
FORMULA_PATH="$PROJECT_ROOT/Formula/gummyworm.rb"

if [[ -f "$FORMULA_PATH" ]]; then
    log_info "Updating Formula/gummyworm.rb..."
    
    # Update version in URL
    sed -i '' "s|/v[0-9]*\.[0-9]*\.[0-9]*\.tar\.gz|/v${VERSION}.tar.gz|g" "$FORMULA_PATH"
    
    # Update SHA256
    sed -i '' "s|sha256 \".*\"|sha256 \"${SHA256}\"|g" "$FORMULA_PATH"
    
    log_info "Formula updated with version ${VERSION}"
else
    log_warn "Formula not found at $FORMULA_PATH"
fi

echo ""
log_info "Release v${VERSION} prepared!"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit: git add -A && git commit -m 'Release v${VERSION}'"
echo "  3. Tag: git tag v${VERSION}"
echo "  4. Push: git push origin main --tags"
echo "  5. Create GitHub release and upload: $TARBALL_PATH"
echo ""
echo "For Homebrew tap setup, copy Formula/gummyworm.rb to your tap repository:"
echo "  homebrew-gummyworm/Formula/gummyworm.rb"
echo ""
echo "Formula values:"
echo "  URL: https://github.com/oddurs/gummyworm/archive/refs/tags/v${VERSION}.tar.gz"
echo "  SHA256: ${SHA256}"
