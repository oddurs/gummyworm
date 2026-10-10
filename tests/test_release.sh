#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_release.sh - Tests for scripts/release.sh
# ============================================================================
# Offline only: every case here is one the script must refuse before it
# touches the network. Hashing a real published archive is verified by hand
# at release time, not in the suite.
# Shell compatibility: Bash 3.2+
# ============================================================================

set -e; set -u; set -o pipefail 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

RELEASE="$PROJECT_ROOT/scripts/release.sh"

# A scratch copy of the formula, so no test can modify the real one
FORMULA_COPY=$(mktemp)
cp "$PROJECT_ROOT/Formula/gummyworm.rb" "$FORMULA_COPY"
trap 'rm -f "$FORMULA_COPY"; cleanup_temp' EXIT

# Run release.sh against the scratch formula; echo combined output
run_release() {
    GUMMYWORM_FORMULA="$FORMULA_COPY" bash "$RELEASE" "$@" 2>&1
}

# Succeeds when release.sh exits non-zero for the given arguments
release_refuses() {
    ! GUMMYWORM_FORMULA="$FORMULA_COPY" bash "$RELEASE" "$@" >/dev/null 2>&1
}

test_requires_exactly_one_argument() {
    assert_true 'release_refuses'           "no arguments is refused"
    assert_true 'release_refuses 1.0.0 2.0.0' "two arguments are refused"
}

test_rejects_non_semver_versions() {
    local v
    for v in 2.3 v2.3.1 2.3.1-rc1 abc 2..1; do
        assert_true "release_refuses '$v'" "version '$v' is refused"
    done
}

test_refuses_a_tag_that_does_not_exist() {
    local out
    out=$(run_release 99.99.99 || true)
    assert_contains "$out" "does not exist locally" "a missing tag is named as missing"
}

test_refuses_a_missing_formula() {
    local out
    out=$(GUMMYWORM_FORMULA=/nonexistent/gummyworm.rb bash "$RELEASE" 2.3.0 2>&1 || true)
    assert_contains "$out" "Formula not found" "a missing formula is reported"
}

test_refusals_leave_the_formula_untouched() {
    local before after
    before=$(cat "$FORMULA_COPY")
    run_release 2.3 >/dev/null || true
    run_release 99.99.99 >/dev/null || true
    after=$(cat "$FORMULA_COPY")
    assert_equals "$before" "$after" "a refused run does not modify the formula"
}

test_no_longer_builds_its_own_tarball() {
    # The old script hashed a tarball built from the working tree, which can
    # never match GitHub's archive. Guard against that coming back.
    assert_false "grep -qE '^[^#]*tar .*-czf' '$RELEASE'" "release.sh does not build a local tarball"
    assert_true  "grep -q 'archive/refs/tags' '$RELEASE'" "release.sh hashes GitHub's tag archive"
}

run_discovered_tests "Release Script"
