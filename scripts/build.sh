#!/usr/bin/env bash
# Builds libMoltenVK.dylib of the selected patch set for x86_64 and arm64: a
# fresh patched clone of the base, MoltenVK's own dependencies, then the
# xcodebuild command of MoltenVK's Makefile `macos` target. Everything stays in
# the work root. Prints the dylib's path and SHA-256.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$script_dir/common.sh"

load_manifests
require_command git
require_command xcodebuild
require_command lipo

base_root="$("$script_dir/fetch-source.sh")"
tree="$work_root/build/$patch_set_id"

if [[ ! -d "$tree/.git" ]]; then
  mkdir -p "$(dirname "$tree")"
  rm -rf "$tree.partial"
  git clone --quiet --no-checkout "$base_root" "$tree.partial"
  git -c advice.detachedHead=false -C "$tree.partial" checkout --quiet --detach "$base_commit"
  apply_series_to "$tree.partial"
  mv "$tree.partial" "$tree"
fi
[[ "$(git -C "$tree" rev-parse 'HEAD^{tree}')" == "$result_tree" ]] \
  || die "$tree is not the tree of $patch_set_id; remove it to start again"

cd "$tree"
# ponytail: an existing External/build is trusted; remove it after a base change.
[[ -d External/build/Latest ]] || ./fetchDependencies --macos

xcodebuild build -quiet \
  -project MoltenVKPackaging.xcodeproj \
  -scheme "MoltenVK Package (macOS only)" \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$work_root/derived-data" \
  'GCC_PREPROCESSOR_DEFINITIONS=${inherited}'

dylib="$tree/Package/Release/MoltenVK/dynamic/dylib/macOS/libMoltenVK.dylib"
require_file "$dylib"
for arch in x86_64 arm64; do
  lipo "$dylib" -verify_arch "$arch" || die "$dylib has no $arch slice"
done
printf '%s\nsha256 %s\n' "$dylib" "$(sha256_file "$dylib")"
