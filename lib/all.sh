#!/usr/bin/env bash
# ============================================================================
# gummyworm/lib/all.sh - Load every module
# ============================================================================
# The one list of modules. Order does not matter: each module sources its own
# dependencies, and every module is include-guarded, so anything already
# loaded returns immediately. Source this at top level, not from inside a
# function (see the note in any module's dependency block).
#
# Loading defines functions and constants only. It does not read the user's
# config files -- call config_load_files for that.
# ============================================================================

# Locate this directory, portable across bash and zsh
if [[ -n "${BASH_VERSION:-}" ]]; then
    _gw_all_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # shellcheck disable=SC2296
    _gw_all_dir="$(cd "$(dirname "${(%):-%x}")" && pwd)"
fi

# shellcheck source=lib/config.sh
source "$_gw_all_dir/config.sh"
# shellcheck source=lib/utils.sh
source "$_gw_all_dir/utils.sh"
# shellcheck source=lib/palettes.sh
source "$_gw_all_dir/palettes.sh"
# shellcheck source=lib/image.sh
source "$_gw_all_dir/image.sh"
# shellcheck source=lib/coverage.sh
source "$_gw_all_dir/coverage.sh"
# shellcheck source=lib/converter.sh
source "$_gw_all_dir/converter.sh"
# shellcheck source=lib/export.sh
source "$_gw_all_dir/export.sh"
# shellcheck source=lib/cli.sh
source "$_gw_all_dir/cli.sh"

unset _gw_all_dir
