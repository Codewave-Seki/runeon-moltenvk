#!/usr/bin/env bash
# Applies the selected patch set to a temporary worktree of the pinned base and
# checks the resulting tree. Proves only that the series applies as recorded.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$script_dir/common.sh"

[[ $# -eq 1 && -n "$1" ]] || die "usage: $0 MOLTENVK_SOURCE_ROOT"
source_root="$(cd "$1" && pwd)"

load_manifests
require_command git
assert_base_checkout "$source_root"

worktree="$(mktemp -d "${TMPDIR:-/tmp}/moltenvk-check.XXXXXX")"
cleanup() {
  git -C "$source_root" worktree remove --force "$worktree" 2>/dev/null || rm -rf "$worktree"
  git -C "$source_root" worktree prune
}
trap cleanup EXIT

git -C "$source_root" worktree add --quiet --detach "$worktree" "$base_commit"
apply_series_to "$worktree"
printf 'integration check passed for %s (%s patches, tree %s)\n' \
  "$patch_set_id" "$(series_paths | wc -l | tr -d ' ')" "$result_tree"
