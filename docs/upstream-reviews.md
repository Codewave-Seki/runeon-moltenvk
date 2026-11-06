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
