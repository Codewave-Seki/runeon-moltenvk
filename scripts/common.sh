#!/usr/bin/env bash

set -euo pipefail
umask 022

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
work_root="${MOLTENVK_WORK_ROOT:-$repo_root/.work}"
# The newest patch set unless MOLTENVK_PATCHSET_DEFINITION selects another.
patchset_definition="${MOLTENVK_PATCHSET_DEFINITION:-}"
if [[ -z "$patchset_definition" ]]; then
  patchset_definition="$(cd "$repo_root" && ls -d patchsets/*/ 2>/dev/null | sort -V | tail -n 1 || true)"
  patchset_definition="${patchset_definition%/}"
fi
[[ -n "$patchset_definition" ]] || { printf 'error: no patch set under patchsets/\n' >&2; exit 1; }
patchset_definition="$(cd "$repo_root" && cd "$patchset_definition" && pwd)"
patch_manifest="$patchset_definition/manifest.json"
series_file="$patchset_definition/series"
# Each patch set names its base; earlier patch sets keep theirs.
base_id_ref="$(jq -er '.baseId' "$patch_manifest" 2>/dev/null)" \
  || { printf 'error: cannot read baseId from %s\n' "$patch_manifest" >&2; exit 1; }
base_manifest="$repo_root/base/$base_id_ref.json"

# git am needs a committer. Fixed values and author dates make the patched HEAD
# reproducible; MoltenVK derives its pipelineCacheUUID from that HEAD.
export GIT_COMMITTER_NAME="MoltenVK patch series" GIT_COMMITTER_EMAIL="noreply@example.invalid"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_file() {
  [[ -f "$1" ]] || die "required file not found: $1"
}

json_value() {
  require_command jq
  jq -er "$2" "$1"
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

series_paths() {
  sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$series_file"
}

load_manifests() {
  require_file "$base_manifest"
  require_file "$patch_manifest"
  require_file "$series_file"

  base_id="$(json_value "$base_manifest" '.baseId')"
  base_repository="$(json_value "$base_manifest" '.repository')"
  base_tag="$(jq -r '.tag // empty' "$base_manifest")"
  base_commit="$(json_value "$base_manifest" '.commit')"
  patch_set_id="$(json_value "$patch_manifest" '.patchSetId')"
  result_tree="$(json_value "$patch_manifest" '.resultTree')"
}

# A checkout is a valid base when HEAD is the pinned commit and nothing is
# modified. Dependencies under External/ are ignored by MoltenVK itself.
assert_base_checkout() {
  local root="$1"

  [[ "$(git -C "$root" rev-parse HEAD)" == "$base_commit" ]] \
    || die "$root is not at $base_commit"
  [[ -z "$(git -C "$root" status --porcelain)" ]] || die "$root has local changes"
}

# Applies the series with git am onto the checkout and checks the resulting
# tree against the manifest.
apply_series_to() {
  local root="$1" relative_patch expected

  while IFS= read -r relative_patch; do
    expected="$(jq -er --arg path "$relative_patch" '.patches[] | select(.path == $path) | .sha256' "$patch_manifest")" \
      || die "patch not in manifest: $relative_patch"
    [[ "$(sha256_file "$repo_root/$relative_patch")" == "$expected" ]] \
      || die "patch SHA-256 mismatch: $relative_patch"
    git -C "$root" am --quiet --committer-date-is-author-date "$repo_root/$relative_patch" \
      || { git -C "$root" am --abort; die "patch does not apply: $relative_patch"; }
  done < <(series_paths)
  [[ "$(git -C "$root" rev-parse 'HEAD^{tree}')" == "$result_tree" ]] \
    || die "patched tree differs from resultTree in $patch_manifest"
}
