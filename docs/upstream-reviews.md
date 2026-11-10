# Upstream Reviews

Each section records one review: what was taken, what was left out and why. Sections are append-only; a later review supersedes an earlier decision by recording a new one.

<a id="base-main-5189f8de-20261106"></a>
## BASE-MAIN-5189F8DE-20261106

- Base: KhronosGroup/MoltenVK `main` at `5189f8de86ec365860f63bf1da736815cfaea5cd` (`v1.4.2-58-g5189f8de`). No upstream release contains it.
- Patch set: `1.4.2-patched.1`. The ID keeps the last release; the source's version constant says 1.4.3, which upstream has not released.
- Sources reviewed: [nivogli/MoltenVK](https://github.com/nivogli/MoltenVK) branch `enshrouded-v19` at `96793f1de5fd898a8e4ad3b7d7b52f23b8bac483`, 15 commits on this base; [fortmeier/MoltenVK pull 1](https://github.com/fortmeier/MoltenVK/pull/1), `a58d6bcf04ac4a8c1f59652b340411dde760b33a`, for [KhronosGroup/MoltenVK#2588](https://github.com/KhronosGroup/MoltenVK/issues/2588). Public references: KhronosGroup/MoltenVK #2841, #2891, #2892, #2893; [djnunocunhadev/enshrouded-mac-perfmod](https://github.com/djnunocunhadev/enshrouded-mac-perfmod) (Apache-2.0).

### Evidence

Observed on an Apple M3 Max with macOS 27.0.1, under Wine and Rosetta 2 on Apple Silicon. This is not a conformance statement.

| Build | Result with the game Enshrouded |
|---|---|
| Unmodified MoltenVK 1.4.2 | Fails at startup (`drawIndirectCount` false) |
| This base | Starts; about 20 FPS at Medium |
| The nivogli fork, without the present fix | About 35 FPS at High; repeated older frames and row tearing |
| The fork plus the present fix | Those frames and tearing gone, by visual confirmation; no frame rate was measured for this build |

The fork's benefit was measured as a whole, not per commit. The series below differs from those builds. It has since been run with the game on the same machine: at the High preset it entered the world and played about five minutes, with no draw cap raise and no device loss in the logs; the maintainer saw frame rate fall late in that session, and no frame rate figure was recorded for this series. Tessellated draws in that run were not confirmed, and other Vulkan titles have not been tested with it.

Small local checks of this series (a program that creates `VkInstance` and `VkDevice`, draws offscreen and runs compute on the same machine, not committed):

| Check | Fork | This series |
|---|---|---|
| Indirect-count draws, 300 real of `maxDrawCount` 1000, same command buffer submitted twice, drawn columns counted | 256 and 256 (a raised cap never reached it) | 300 and 300 (at or below the threshold, as the base) |
| The same with `maxDrawCount` 2000 | Not recorded | 256 and 300: the first submission loses 44 draws; for a one-shot command they are lost for good |
| The same, indexed, triangle-fan and within-cap variants, hoisting on and off, with Metal API validation | Not compared | Every count correct, no validation errors |
| 2000 order-sensitive dispatches with compute barriers, `MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS=0` | Wrong result | Correct result |
| The same with argument buffers, also with `vkCmdDispatchIndirect` and a `DRAW_INDIRECT` barrier | Correct result | Correct result |
| 3000 iterations of present then destroying the swapchain without waiting (invalid use) | Not run. The base crashes in `MVKSwapchain::beginPresentation` | Completes without a crash, three runs |
| Converted MSL of one small shader per stage, from `MVK_CONFIG_SHADER_DUMP_DIR` | Not compared | `optnone` removed from `spvFMul` in fragment and compute, kept in vertex |
| The draw clamp as a standalone C++ check | Not compared | Holds for the cases tried, including near `UINT32_MAX` |

Not run locally: tessellated draws, so `0102`'s sizing and the clamp inside the kernels, and tessellation-stage precise-math handling, rest on reading the code and on the kernels compiling. Barrier and concurrency timing gains were not measured per patch.

### Taken

| Patch | Author | Source | Behaviour | Modifications |
|---|---|---|---|---|
| `0101` | Dirk Fortmeier | `a58d6bcf04` | Present from the completed-handler | `_swapchain` and `_device` guarded by `_detachmentLock` in `beginPresentation()`, as the handler can outrun an unwaited swapchain destruction; comment corrected for single-queue semaphores; notice comment added; `Docs/Whats_New.md` hunk dropped |
| `0102` | nivogli | `a6289be3`, `bb88c75c` | Tessellation scratch sizes from reflection; indirect draw clamp | Statistics and completion handler dropped; budget variable removed; 64-bit lengths; switch added; simpler reflection interface |
| `0103` | nivogli | `49a7b097`, `2babf427` | Compute-sourced barriers stay in the encoder | One switch; shared predicate; only over dispatch work; a following `vkCmdDispatchIndirect` ends the encoder if the barrier covers indirect arguments (`DRAW_INDIRECT`, `ALL_GRAPHICS` or `ALL_COMMANDS`) |
| `0104` | nivogli | `71bf4b4e` | `TOP_OF_PIPE` and `BOTTOM_OF_PIPE` as no stages | Same scope as the source commit: only the decision in `0103` |
| `0105` | nivogli | `9674c5bd` | Concurrent `vkCmdDispatch` encoders | Only when barriers are honoured: the source made the encoder concurrent regardless, a data race without argument buffers or a residency set |
| `0106` | nivogli | `3bf6ffe6`, from enshrouded-mac-perfmod | Precise-math helpers without `optnone` | Decided from the Vulkan stage in `MVKShaderModule::convert()` instead of matching `\nvertex ` in text, which missed tessellation stages. Fragment and GLCompute only; vertex and tessellation stages keep theirs because their conversion options carry their own stage |
| `0107` | nivogli | `08e692dc`, `5546b028`, `96793f1d`, part of `d496ec14` | Indirect-count draw cap, self-correcting | Applies only above `maxDrawCount` 1024; read at encode time instead of `setContent()`; one count per encode; no statistics; no upper limit; other devices uncapped; raises log a MoltenVK warning |
| `0108` | nivogli | `d9503da3` | Conversion before dynamic rendering | Records the count each conversion was sized for; also stops at `vkCmdWaitEvents` and `vkCmdExecuteCommands` |

### Left out

| Commit | Why |
|---|---|
| `145cbf0a` | Math-mode experiment, off by default in the source; not tested here |
| `a52d9ec5` | Fast transcendental functions, off by default in the source; community reports higher frame rates with fast math, but it was off in the tested build and was not tested here |
| `34f8bc86` | Cap decay. Dead after `96793f1d`: `floorCap` always equals the new cap, so `cap > lowest` never holds |
| `d496ec14`, except the truncation counter | Diagnostic statistics and histograms |
| Statistics of `bb88c75c` | `MVKPerfTess.h`, its buffer, completion handler and log lines |
| Wider part of KhronosGroup/MoltenVK#2891 | Fence path and render pass dependencies: not in the tested build, and keeping them only synchronizes more |

### Known residuals

- `0107`: a one-shot indirect-count command with `maxDrawCount` above 1024 and a real count above the cap loses those draws permanently. A repeated command loses them on each submission until a raised cap covers its real count, then recovers (one submission per doubling in the local check). Commands at or below 1024 behave as the base.
- `0101`: with the single-queue semaphore style the encoded wait is a no-op, so ordering relies on command buffers completing in queue order. That was observed (0 of 40 samples out of order), but no Metal document found guarantees it.
- `0102`: the tess control output stride is not compared with the tess evaluation input size, unlike the vertex to tess control pair, because the render pipeline compiler requests no reflection. They should match, as the evaluation stage is converted from the control stage's outputs; this is unverified.
- `0106`: a compute shader whose output later feeds vertex positions also loses `NoContraction`; the stage cannot show this.
- `0103`: Metal does not state whether `memoryBarrierWithScope:` covers indirect argument reads, so the patch assumes it does not and ends the encoder before such a `vkCmdDispatchIndirect`.

<a id="linear-tiling-fallback-20261110"></a>
## LINEAR-TILING-FALLBACK-20261110

- Base: unchanged, `5189f8de86ec365860f63bf1da736815cfaea5cd`.
- Patch set: `1.4.2-patched.2`, which is `1.4.2-patched.1` plus `0109`.
- Source reviewed: [KhronosGroup/MoltenVK pull 2825](https://github.com/KhronosGroup/MoltenVK/pull/2825) by Gauthier Piarrette, one commit `982334711641ef88726a88dad7f89e774b50d74b`, open and not merged at the time of this review. It is contributed to MoltenVK under Apache-2.0; nothing was taken from other implementations of the same idea.

### Why

For a `VK_IMAGE_TILING_LINEAR` image that is not 2D, or has more than one mip level or array layer, `validateLinear()` fails `vkCreateImage()` with `VK_ERROR_FEATURE_NOT_PRESENT`, because Metal cannot back such a texture with linear memory. The Vulkan specification guarantees linear tiling only for a 2D image with one level and one layer and leaves anything more to `vkGetPhysicalDeviceImageFormatProperties`, so the refusal is legal, but some applications neither query nor handle it. Such an application exceeds the limits that `vkGetPhysicalDeviceImageFormatProperties` reports, which violates a valid usage rule; MoltenVK still reports those limits, so the fallback being on by default does not change anything for a correct application.

### Evidence

Observed on an Apple M3 Max with macOS 27.0.1. This is not a conformance statement.

- Red Dead Redemption 2 under Wine, with `1.4.2-patched.1`: the MoltenVK log shows `vkCreateImage(): If tiling is VK_IMAGE_TILING_LINEAR, imageType must be VK_IMAGE_TYPE_2D` 16 times and `mipLevels must be 1` 3 times, immediately before the game crashes during its initialisation.
- Red Dead Redemption 2 under Wine, with a build of `1.4.2-patched.2`, run on 2026-11-10: the Game Init crash at `RDR2.exe+0x6f74dc4` did not occur. No run with `MVK_CONFIG_LINEAR_TILING_FALLBACK=0` was made, so that the refusals cause the crash remains a hypothesis, now with stronger evidence.
- Third-party, not reproduced here: the pull request reports that the same change on a 1.4.1 base took the game from never drawing a frame to playing its prologue on an Apple M1 Pro.
- A local probe (a program that loads the dylib directly, creates `VkInstance` and `VkDevice`, and creates 16x16 `R8G8B8A8_UNORM` linear images; not committed), for both the `arm64` slice and the `x86_64` slice under Rosetta 2:

| Image | `1.4.2-patched.1` | `1.4.2-patched.2` | `1.4.2-patched.2`, switch `0` |
|---|---|---|---|
| 2D, 1 level, 1 layer (control) | `VK_SUCCESS` | `VK_SUCCESS` | `VK_SUCCESS` |
| 3D, depth 4 | `VK_ERROR_FEATURE_NOT_PRESENT` | `VK_SUCCESS` | `VK_ERROR_FEATURE_NOT_PRESENT` |
| 2D, 2 levels | `VK_ERROR_FEATURE_NOT_PRESENT` | `VK_SUCCESS` | `VK_ERROR_FEATURE_NOT_PRESENT` |
| 2D, 2 layers | `VK_ERROR_FEATURE_NOT_PRESENT` | `VK_SUCCESS` | `VK_ERROR_FEATURE_NOT_PRESENT` |

With the fallback, one warning was logged for the first such image and none for the others.

Not run locally: binding memory to such an image, host writes or reads through a mapping, and sampling it. Whether the game draws correctly with the fallback is not known.

### Taken

| Patch | Author | Source | Behaviour | Modifications |
|---|---|---|---|---|
| `0109` | Gauthier Piarrette | `98233471` | Linear-tiled 3D, mipmapped and array images are created with optimal tiling, with one warning | `MVK_CONFIG_LINEAR_TILING_FALLBACK` defaults to `1` instead of `0`, marked as a downstream change; `Docs/Whats_New.md` hunk dropped. The appended `MVKConfiguration` member raises the internal padding count from 4 to 8, as in the source; the `static_assert` on the size of `MVKConfiguration` holds for both architectures |

### Known residuals

- `0109`, from reading the code, not from a probe: for dedicated memory, MoltenVK copies between the mapping and the texture at flush and unmap. Other host-visible memory is backed by an `MTLHeap` on Apple GPUs, so the texture overlaps the mapped bytes, and host writes in linear layout give wrong pixels but stay in bounds.
- `0109`: `vkGetImageSubresourceLayout` describes the optimal layout, not the linear one the application asked for. An application that computes offsets itself instead of asking may read or write the wrong bytes.

<a id="pipeline-cache-stored-compile-failure-20261110"></a>
## PIPELINE-CACHE-STORED-COMPILE-FAILURE-20261110

- Base: unchanged, `5189f8de86ec365860f63bf1da736815cfaea5cd`.
- Patch set: `1.4.2-patched.2`, which also gains `0201`.
- Source: none. `0201` is a Runeon fix written for this series. No upstream issue or pull request covers it, and upstream `main` has not changed this code since the base; it is not proposed upstream.

### Why

`MVKPipelineCache::readData()` compiles every stored shader library while `vkCreatePipelineCache()` runs. A Metal compile failure is reported on the owner of the library, which is the pipeline cache, so one stored entry that fails to compile makes `vkCreatePipelineCache()` destroy the cache and return `VK_ERROR_INITIALIZATION_FAILED` with `VK_NULL_HANDLE`. Such an entry is stored whenever a pipeline's shader failed to compile in the run that saved the cache, because the library is cached even though its compile failed. An application that does not check the result and passes the null handle to `vkGetPipelineCacheData()` crashes in `MVKPipelineCache::writeData()`.

### Evidence

Observed on an Apple M3 Max with macOS 27.0.1. This is not a conformance statement.

- Red Dead Redemption 2 under Wine, with `1.4.2-patched.2` before `0201`: the first start ran and saved a 72,773,057-byte pipeline cache; the log has one `Shader library compile failed` for MSL that writes `gl_CullDistance`, which its output struct does not declare. The second start, with that cache present, exited after 73 seconds with `fault in system call ... MVKPipelineCache::writeData` followed by winevulkan's assertion on `vkGetPipelineCacheData`. With the cache files moved away, the game started again.
- The saved data begins with MoltenVK's own header: vendor `0x106b`, device `0x1b000209` and a `pipelineCacheUUID` equal to that of the build that wrote it.
- A local probe (a program that loads the dylib directly, creates `VkInstance` and `VkDevice`, calls `vkCreatePipelineCache()` with the saved data, then `vkGetPipelineCacheData()` for the size and for the data without checking the first result; not committed, and the game data is not in this repository), for both the `arm64` slice and the `x86_64` slice under Rosetta 2. For the build with `0201`, a copy of the data had its UUID rewritten to the new build's, because the UUID follows the patched `HEAD`:

| Build | Data | `vkCreatePipelineCache` | `vkGetPipelineCacheData` |
|---|---|---|---|
| Before `0201` | Saved data, UUID matches | `VK_ERROR_INITIALIZATION_FAILED`, `VK_NULL_HANDLE`; the same compile error logged once | `SIGSEGV` reading address `0x98` in `MVKPipelineCache::writeData` |
| With `0201` | Saved data, UUID rewritten to match | `VK_SUCCESS`; the same compile error logged once | `VK_SUCCESS`, 72,773,057 bytes |
| With `0201` | Saved data, UUID of the older build | `VK_SUCCESS`, data ignored | `VK_SUCCESS`, 36 bytes (header and end marker) |

The written data has the input's size but not its byte order, because the cache iterates an unordered map.

- Red Dead Redemption 2 under Wine, with a build of `1.4.2-patched.2` including `0201`, run on 2026-11-10: the second start, with the game's saved pipeline cache present, no longer crashed in `MVKPipelineCache::writeData`.

### Taken

| Patch | Author | Source | Behaviour | Modifications |
|---|---|---|---|---|
| `0201` | WIndFate | Runeon | After each stored entry is added, the configuration result of the cache is cleared, so a compile failure of that entry is logged but does not fail `vkCreatePipelineCache()`. A read error after the entry still fails it | Not applicable |

### Known residuals

- `0201`: the failed entry stays in the cache, is written out again, and is compiled again on every load. A pipeline that uses it fails as it did when it was saved.
- The SPIR-V to MSL conversion that writes an undeclared `gl_CullDistance` is a separate defect and is not fixed here.
- Every stored entry is still compiled while `vkCreatePipelineCache()` runs; with this cache the whole probe took 224 seconds on each slice, almost all of it in that call.
