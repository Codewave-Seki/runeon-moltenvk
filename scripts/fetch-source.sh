#!/usr/bin/env bash
# Clones the pinned MoltenVK commit into the work root (once), verifies it, and
# prints its path.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$script_dir/common.sh"

load_manifests
require_command git
source_root="$work_root/source/$base_id"

if [[ ! -d "$source_root/.git" ]]; then
  mkdir -p "$(dirname "$source_root")"
  rm -rf "$source_root.partial"
  printf 'cloning %s %s\n' "$base_repository" "$base_commit" >&2
  git clone --quiet --no-checkout "$base_repository" "$source_root.partial"
  git -c advice.detachedHead=false -C "$source_root.partial" checkout --quiet --detach "$base_commit"
  mv "$source_root.partial" "$source_root"
fi

assert_base_checkout "$source_root"
printf '%s\n' "$source_root"
