# Patched MoltenVK

[English](README.md) | [Chinese](README.zh-CN.md) | [Japanese](README.ja.md)

> This English document is authoritative. The Chinese and Japanese documents are complete translations for convenience.

A patched [MoltenVK](https://github.com/KhronosGroup/MoltenVK): a pinned upstream commit, an ordered patch series adopted from public forks, and the scripts that rebuild it. It makes no compatibility or conformance promise. It holds no MoltenVK source tree and no built dylib.

## Baseline and current patch set

- Upstream base: MoltenVK `main` at `5189f8de` (`v1.4.2-58-g5189f8de`), pinned in [`base/moltenvk-main-5189f8de.json`](base/moltenvk-main-5189f8de.json). Dependencies follow its `ExternalRevisions`
- Current patch set: [`1.4.2-patched.1`](patchsets/1.4.2-patched.1/manifest.json), with 8 patches. Its Git tag is the source of record for builds consumed downstream; there are no binary Releases. The ID keeps the last upstream release; the source's own version constant says 1.4.3, which upstream has not released
- Reviewed: see [MAINTENANCE.md](MAINTENANCE.md#review-records)

## Repository layout

| Path | Contents |
|---|---|
| `base/` | Pinned upstream repository and commit |
| `patchsets/<id>/` | `series` and `manifest.json` for one patch set; scripts use the newest unless `MOLTENVK_PATCHSET_DEFINITION=patchsets/<id>` selects another |
| `patches/community/` | Fixes adopted from public forks, one commit per file |
| `scripts/` | Fetch, check and build scripts |
| `docs/` | Review records |

## What the patches do

Every change is generic and on by default, and never matches a game. Each non-trivial one has an environment switch; see [MAINTENANCE.md](MAINTENANCE.md#environment-switches).

- Present swapchain images after the present wait semaphores have signalled
- Size tessellation scratch buffers from what shaders write, and clamp indirect tessellated draws to them
- Keep compute-sourced barriers inside the compute encoder, and run `vkCmdDispatch` encoders concurrently where barriers are honoured
- Let Metal optimize precise-math helpers in fragment and compute stages
- Cap the Metal draws encoded per indirect-count command with a very large declared maximum, raising the cap when draws are truncated; a one-shot command above the threshold can lose draws
- Convert indirect-count arguments before dynamic rendering begins

## Verify and build

```bash
scripts/static-check.sh
scripts/integration-check.sh "$(scripts/fetch-source.sh)"
scripts/build.sh
```

`integration-check.sh` applies every patch with `git am` to a temporary worktree of the pinned base and checks that the result is the tree recorded in the manifest. `build.sh` is described in [BUILDING.md](BUILDING.md).

## Documentation

- [BUILDING.md](BUILDING.md): building the dylib
- [MAINTENANCE.md](MAINTENANCE.md): review records, gates and environment switches
- [SECURITY.md](SECURITY.md): reporting security issues
- [docs/upstream-reviews.md](docs/upstream-reviews.md): review records

## License

Apache-2.0, the same as MoltenVK; see [`LICENSE`](LICENSE). Adopted commits keep their original authorship, and modified files carry modification notices.
