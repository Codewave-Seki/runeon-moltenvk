#!/usr/bin/env bash
# Checks manifests, the base file, the READMEs and commit messages. Needs no
# MoltenVK checkout.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$script_dir/common.sh"

load_manifests
require_command jq
require_command perl
require_command git
cd "$repo_root"

[[ "$(readlink AGENTS.md)" == CLAUDE.md ]] || die "AGENTS.md must be a symlink to CLAUDE.md"

# Base file.
[[ "$(basename "$base_manifest" .json)" == "$base_id" ]] || die "base file name differs from baseId"
jq -e '(.commit | test("^[0-9a-f]{40}$")) and (.repository | startswith("https://"))
       and ((.tag == null) or (.tag | type == "string"))' \
  "$base_manifest" >/dev/null || die "invalid base file: $base_manifest"

# Patch manifest against series.
[[ "$(basename "$patchset_definition")" == "$patch_set_id" ]] \
  || die "patch-set directory name differs from patchSetId: $patchset_definition"
[[ "$result_tree" =~ ^[0-9a-f]{40}$ ]] || die "resultTree must be a full tree SHA"
[[ "$(series_paths)" == "$(jq -r '.patches | sort_by(.order)[] | .path' "$patch_manifest")" ]] \
  || die "series and patch manifest order differ"

while IFS= read -r relative_patch; do
  require_file "$relative_patch"
  entry="$(jq -ec --arg path "$relative_patch" '.patches[] | select(.path == $path)' "$patch_manifest")"
  [[ "$(sha256_file "$relative_patch")" == "$(jq -r .sha256 <<<"$entry")" ]] \
    || die "patch SHA-256 mismatch: $relative_patch"
  jq -e '(.summary | length > 0) and (.author | length > 0)' <<<"$entry" >/dev/null \
    || die "summary or author missing: $relative_patch"
  if [[ "$relative_patch" == patches/community/* ]]; then
    jq -e '(.kind == "community") and (.sourceUrl | startswith("https://")) and (.sourceCommits | length > 0 and all(test("^[0-9a-f]{40}$")))' \
      <<<"$entry" >/dev/null || die "patch needs kind community, sourceUrl and full sourceCommits: $relative_patch"
  elif [[ "$relative_patch" == patches/runeon/* ]]; then
    jq -e '.kind == "runeon" and ((has("sourceUrl") or has("sourceCommits")) | not)' \
      <<<"$entry" >/dev/null || die "patch needs kind runeon and no sourceUrl or sourceCommits: $relative_patch"
  else
    die "patch outside patches/community or patches/runeon: $relative_patch"
  fi
done < <(series_paths)

for shell_script in scripts/*.sh .githooks/*; do
  bash -n "$shell_script"
done

# Only the README is translated.
readme_names=(README.md README.zh-CN.md README.ja.md)
for readme in "${readme_names[@]}"; do
  require_file "$readme"
  for name in "${readme_names[@]}"; do
    grep -Fq "($name)" "$readme" || die "README language link is missing $name: $readme"
  done
done
cjk='\p{Han}|\p{Hiragana}|\p{Katakana}'
while IFS= read -r english_file; do
  if perl -CSD -ne "\$found ||= /$cjk/; END { exit(\$found ? 0 : 1) }" "$english_file"; then
    die "English-only file contains Chinese or Japanese text: $english_file"
  fi
done < <(git ls-files | grep -Ev '^README\.(zh-CN|ja)\.md$')
perl -CSD -ne '$found ||= /\p{Han}/; END { exit($found ? 0 : 1) }' README.zh-CN.md \
  || die "Chinese README does not contain Chinese text"
perl -CSD -ne '$found ||= /\p{Hiragana}|\p{Katakana}/; END { exit($found ? 0 : 1) }' README.ja.md \
  || die "Japanese README does not contain Japanese text"

# Commit messages are English (CI needs the full history: fetch-depth 0).
if git rev-parse --verify --quiet HEAD >/dev/null; then
  if git log --format='%H%n%B' | perl -CSD -ne "if (/^([0-9a-f]{40})\$/) { \$c = \$1 } elsif (/$cjk/) { print \"\$c\\n\"; \$bad = 1 } END { exit(\$bad ? 0 : 1) }"; then
    die "commit messages above contain Chinese or Japanese text"
  fi
fi

printf 'static checks passed for %s\n' "$patch_set_id"
