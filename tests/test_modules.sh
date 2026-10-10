#!/usr/bin/env bash
# ============================================================================
# gummyworm/tests/test_modules.sh - Module loading and the dependency graph
# ============================================================================
# Every lib must load on its own in a fresh shell, bringing its declared
# dependencies with it. Before this was enforced, only bin/gummyworm sourced
# anything, in a hand-kept order, and putting a function in the "wrong"
# module silently broke callers loaded earlier.
# Shell compatibility: Bash 3.2+ (spawns zsh and /bin/bash where present)
# ============================================================================

set -e; set -u; set -o pipefail 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

LIB="$PROJECT_ROOT/lib"

# module:own_function:function_from_a_dependency
MODULES=(
    "config:config_load_files:is_valid_color"
    "utils:log_error:is_valid_color"
    "palettes:palette_get:log_error"
    "image:calc_dimensions:log_error"
    "converter:convert_to_ascii:palette_to_array"
    "export:export_svg:image_check_deps"
    "cli:parse_args:is_url"
)

# Succeeds when <shell> can source lib/<module>.sh alone, twice, and ends up
# with both functions defined. Run from a scratch directory so no relative
# path can resolve by accident.
loads_alone() {
    local shell="$1" module="$2" own="$3" dep="$4" check
    case "$shell" in
        *zsh) check="whence -w $own >/dev/null && whence -w $dep >/dev/null" ;;
        *)    check="declare -F $own >/dev/null && declare -F $dep >/dev/null" ;;
    esac
    (
        cd "$(mktemp -d)" || exit 1
        env -i HOME="$HOME" PATH="$PATH" "$shell" -c \
            "source '$LIB/$module.sh' && source '$LIB/$module.sh' && $check" \
            >/dev/null 2>&1
    )
}

run_all_modules_under() {
    local shell="$1" entry name own dep
    for entry in "${MODULES[@]}"; do
        name="${entry%%:*}"
        own="${entry#*:}"; own="${own%%:*}"
        dep="${entry##*:}"
        assert_true "loads_alone '$shell' $name $own $dep" \
            "$(basename "$shell"): lib/$name.sh loads alone, twice, with its dependencies"
    done
}

test_every_module_loads_alone_in_bash() {
    run_all_modules_under bash
}

test_every_module_loads_alone_in_system_bash_3_2() {
    if [[ ! -x /bin/bash ]] || ! /bin/bash -c '[[ ${BASH_VERSINFO[0]} -eq 3 ]]'; then
        skip_test "/bin/bash is not bash 3.2 here"
        return 0
    fi
    run_all_modules_under /bin/bash
}

test_every_module_loads_alone_in_zsh() {
    if ! command -v zsh >/dev/null 2>&1; then
        skip_test "zsh not installed"
        return 0
    fi
    run_all_modules_under zsh
}

test_all_sh_loads_everything() {
    local out
    out=$(env -i HOME="$HOME" PATH="$PATH" bash -c \
        "source '$LIB/all.sh' && declare -F parse_args convert_to_ascii export_svg palette_get calc_dimensions config_load_files | wc -l" 2>&1)
    assert_equals "6" "$(printf '%s' "$out" | tr -d ' ')" "all.sh defines a function from every module"
}

test_sourcing_does_not_read_config_files() {
    # Sourcing used to load ~/.gummywormrc as a side effect. It must not: the
    # suite would otherwise depend on whoever runs it.
    local home out
    home=$(mktemp -d)
    printf 'width=7\n' > "$home/.gummywormrc"
    out=$(cd "$home" && env -i HOME="$home" PATH="$PATH" bash -c \
        "source '$LIB/all.sh' && printf '%s' \"\$CONFIG_WIDTH\"")
    assert_equals "80" "$out" "sourcing leaves CONFIG_WIDTH at its default"

    out=$(cd "$home" && env -i HOME="$home" PATH="$PATH" bash -c \
        "source '$LIB/all.sh' && config_load_files && printf '%s' \"\$CONFIG_WIDTH\"")
    assert_equals "7" "$out" "config_load_files reads the user's config"
    rm -rf "$home"
}

test_no_module_is_sourced_from_inside_a_function() {
    # Sourcing inside a function makes `declare`d variables local, and readonly
    # ones local under zsh. Every source of a lib must be at top level.
    local offenders
    offenders=$(awk '
        /^[a-zA-Z_][a-zA-Z0-9_]*\(\) *\{/ { infn = 1 }
        infn && /^\}/ { infn = 0; next }
        infn && /^[[:space:]]*(source|\.)[[:space:]].*lib\// { print FILENAME ":" FNR }
    ' "$LIB"/*.sh "$PROJECT_ROOT/bin/gummyworm" "$SCRIPT_DIR"/*.sh)
    assert_equals "" "$offenders" "no lib is sourced from inside a function"
}

test_declared_dependencies_match_the_code() {
    # The Requires: header must list what the module actually sources.
    local f name header sourced
    for f in "$LIB"/*.sh; do
        name=$(basename "$f" .sh)
        [[ "$name" == "config" || "$name" == "all" ]] && continue
        header=$(grep -m1 '^# Requires:' "$f" | grep -oE 'lib/[a-z]+\.sh' | grep -v config | sort | tr '\n' ' ')
        sourced=$(grep -oE '^source "\$\{GUMMYWORM_LIB_DIR\}/[a-z]+\.sh"' "$f" | grep -oE '[a-z]+\.sh' | sed 's|^|lib/|' | sort | tr '\n' ' ')
        assert_equals "$header" "$sourced" "lib/$name.sh sources exactly what its header declares"
    done
}

run_discovered_tests "Module Loading"
