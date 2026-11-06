#!/usr/bin/env bash
# Applies the selected patch set in place to a clean checkout of the pinned
# base, for building. Use integration-check.sh to test without changing it.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$script_dir/common.sh"

[[ $# -eq 1 && -n "$1" ]] || die "usage: $0 MOLTENVK_SOURCE_ROOT"
source_root="$(cd "$1" && pwd)"

load_manifests
require_command git
assert_base_checkout "$source_root"
apply_series_to "$source_root"
printf 'applied %s; tree %s\n' "$patch_set_id" "$result_tree" >&2
