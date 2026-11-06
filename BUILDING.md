# Building

Requirements: macOS with Xcode, `git`, `jq`, `perl` (for `static-check.sh`) and network access for the first fetch.

```bash
scripts/build.sh
```

This clones the pinned base into `.work/source/`, makes a patched clone in `.work/build/<patch-set-id>/` with `git am`, checks its tree against `resultTree`, and fetches dependencies with MoltenVK's own `./fetchDependencies --macos` at the revisions in its `ExternalRevisions`. It then runs the `xcodebuild` command of MoltenVK's Makefile `macos` target with `-derivedDataPath .work/derived-data`, verifies the `x86_64` and `arm64` slices, and prints the path and SHA-256 of:

```
.work/build/<patch-set-id>/Package/Release/MoltenVK/dynamic/dylib/macOS/libMoltenVK.dylib
```

An existing `External/build` is reused. Remove `.work/build/<patch-set-id>` to start again. Select another patch set with `MOLTENVK_PATCHSET_DEFINITION=patchsets/<id>`.
