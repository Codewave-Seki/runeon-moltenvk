# Maintenance Policy

This repository carries a patch series on a pinned MoltenVK commit. What may enter a patch set is in `CLAUDE.md` §4.

## Review records

| Record | Scope | First patch set |
|---|---|---|
| [BASE-MAIN-5189F8DE-20261106](docs/upstream-reviews.md#base-main-5189f8de-20261106) | New base on upstream `main` `5189f8de`, and the first community fixes | `1.4.2-patched.1` |

## Gates for entering a patch set

- Record the source URL and full commit SHAs, and keep the original author.
- Apply with `git am` and no conflict; describe any adaptation in the commit message.
- Build for `x86_64` and `arm64` with `scripts/build.sh`.
- Run a before-and-after probe for every behaviour a small program can observe. Say plainly what only a game or only reading the code can show.

## Environment switches

Each is read once per process, and each restores the base behaviour of its patch.

| Variable | Default | Scope | Patch |
|---|---|---|---|
| `MVK_PERF_TESS_REFLECTED_SIZES` | `1` | `0`: tessellation scratch buffers keep the device-maximum sizes | `0102` |
| `MVK_PERF_KEEP_COMPUTE_ENCODER` | `1` | `0`: every barrier takes the fence path and ends the encoder; also disables `0104` | `0103`, `0104` |
| `MVK_PERF_CONCURRENT_DISPATCH` | `1` | `0`: `vkCmdDispatch` encoders stay serial. Concurrency also needs Metal argument buffers and a residency set | `0105` |
| `MVK_PERF_OPTIMIZE_PRECISE_MATH` | `1` | `0`: fragment and compute stages keep `optnone` helpers, for shaders converted afterwards; MSL already in a pipeline cache stays as stored | `0106` |
| `MVK_PERF_ICOUNT_MAX_DRAWS` | `256` | Initial cap on Metal draws per indirect-count command with a `maxDrawCount` above 1024. `0`, a negative value or an unparsable one disables the cap and its counter. Each raise logs one MoltenVK warning | `0107` |
| `MVK_PERF_HOIST_INDIRECT_COUNT` | `1` | `0`: every indirect-count draw converts in place, restarting the render pass | `0108` |

Documented exceptions to one switch per behaviour change:

- `0101` has no switch: to isolate the change, build without the patch.
- The draw clamp in `0102` has no switch: it acts only where the base writes past its buffers.

## Patch notes

- Pipeline cache: MoltenVK derives `pipelineCacheUUID` from the first 8 hexadecimal digits of the Git `HEAD` of the build tree, so a build from the patched tree does not share a cache with the base or with another patch set. `common.sh` fixes the committer and dates so that `HEAD` is reproducible.
- Prefilled command buffers: with `MVK_CONFIG_PREFILL_METAL_COMMAND_BUFFERS` set, a command buffer keeps the cap of its encode for that one submission. MoltenVK clears the prefilled buffer on submit, and later submissions encode again with the current cap.
- One-shot commands: `0107` can lose draws of a one-shot command with `maxDrawCount` above 1024 permanently. See the review record.
- Immediate encoding: following commands are not recorded yet when dynamic rendering begins, so `0108` has no effect and draws convert in place.
- A second device: `0107` keeps one process-wide counter bound to the first device with a capped command. Other devices get no cap.

## Release policy

No Release is planned. Scripts that package source and patch-set bundles get added before the first Release. The repository never contains a MoltenVK source tree or a built dylib.

Pushing, tagging and publishing are explicit maintainer decisions.
