# CLAUDE.md

Conventions for working in this public repository, complete on their own. `AGENTS.md` is a symlink to this file; do not create a separate copy. User-facing documentation lives in [README.md](README.md), [BUILDING.md](BUILDING.md) and [MAINTENANCE.md](MAINTENANCE.md); review records are sections of `docs/upstream-reviews.md`.

## 0. Before you start

- Read the parts of `MAINTENANCE.md` that apply: what may enter a patch set, and the switches.
- Find the newest patch set under `patchsets/` and check whether it is tagged (`git tag -l`). Tagged patch sets are frozen; new work goes into a new, untagged patch-set ID.
- Enable the commit message hook once per clone: `git config core.hooksPath .githooks`.
- If a request conflicts with these rules, stop and ask the maintainer before doing anything.

## 1. Public repository boundary

This repository holds a pinned MoltenVK baseline plus an ordered patch series, manifests and scripts. It never holds a MoltenVK source tree or a built dylib.

Everything here is public: patched-MoltenVK content only, no private information. Write every commit, patch, manifest entry and document in English, for an outside reader. A game may be named in a rationale, with public URLs; code never matches a game name, AppID or executable name.

## 2. Layout

| Path | Role |
|---|---|
| `base/<baseId>.json` | Pinned upstream repository, tag (or `null`) and commit; each patch set names its base |
| `patchsets/<patch-set-id>/{series,manifest.json}` | One definition per patch set |
| `patches/community/01NN-<slug>.patch` | Fixes adopted from public forks, keeping the original author |
| `patches/runeon/02NN-<slug>.patch` | Fixes written for Runeon |
| `docs/upstream-reviews.md` | Review records |
| `scripts/` | Bash tools; all load `scripts/common.sh` |
| `.githooks/commit-msg` | Rejects commit messages that are not English |

Scripts use the newest patch set unless `MOLTENVK_PATCHSET_DEFINITION=patchsets/<id>` selects another. CI runs the static check for every patch set and the integration check for the newest.

## 3. Patch-set IDs and bases

- A patch-set ID is `<last upstream release>-patched.<N>`, for example `1.4.2-patched.1`. `N` only increases.
- A base may pin a tag or, when upstream has unreleased fixes that are needed, a commit on upstream `main`: `base/moltenvk-main-<short commit>.json` with `"tag": null`. The patch-set ID keeps the version of the last upstream release. The source's own version constant may already be higher: at `5189f8de` it says 1.4.3, because upstream raises it right after a release and `v1.4.3` is not released.
- Dependencies are pinned only by the `ExternalRevisions` directory of the base commit, fetched by its `./fetchDependencies`.
- A patch set's `resultTree` is the Git tree of the base after its whole series is applied. It is the patch set's identity check: recompute it after every series change.

## 4. What may enter a patch set

- A fix from a fork is adopted only after its defect or benefit has been reproduced locally on this base, and that is recorded in `docs/upstream-reviews.md`. A clean apply alone proves nothing. Forum and issue reports are leads, not evidence.
- A Runeon-written fix is admitted only with a local reproduction of its defect, by probe or game log, recorded in `docs/upstream-reviews.md`. The other rules here apply to it too.
- Record every review decision, including exclusions and why, in `docs/upstream-reviews.md`.
- Keep original authorship with `git am` and the `From:` line. The commit message states the source URL, the modifications and why.
- Rework a fork's commits into one patch per behaviour; do not carry them commit for commit.
- Changes are generic and on by default. They never key on game identity.
- Each non-trivial behaviour change has exactly one documented environment kill switch, so it can be isolated. Every switch appears in `MAINTENANCE.md` with its default and scope. Documented exceptions are listed there.

## 5. Licence

MoltenVK is Apache-2.0 and so is everything here:

- Retain all upstream notices, and keep `LICENSE` identical to MoltenVK's.
- A source file added by a patch carries an Apache header.
- A modified file has a prominent modification notice: a one-line comment at the change (`Downstream change`), plus the commit message.

## 6. Code in patches

- Follow the style of the file you change. Do not reformat surrounding code.
- Use MoltenVK's facilities first (`mvkGetEnvVarNumber`, existing helpers). Add no dependency, and prefer no new file where a small helper fits an existing one.
- Comments are in English and explain why. Mark a deliberate simplification with a `ponytail:` comment that names its ceiling.
- Each patch stays small and is one behaviour. It must build for `x86_64` and `arm64`.

## 7. Patch files and manifests

- Each patch is one commit in `git format-patch` form and must apply with `git am` and no conflict on top of the base plus every earlier entry.
- Keep `series` order and manifest `order` identical. Every entry records `order`, `path`, `sha256`, `kind`, `author` and `summary`. A `community` entry also records `sourceUrl` and full `sourceCommits`; a `runeon` entry has neither.
- After editing a patch, update its `sha256` and the patch set's `resultTree`. Never edit a patch or manifest of a tagged patch set.

## 8. Validation and evidence

Before every commit:

```bash
scripts/static-check.sh
scripts/integration-check.sh "$(scripts/fetch-source.sh)"
```

These checks prove that the series applies and produces the recorded tree, nothing more. `scripts/build.sh` proves it compiles for both architectures.

- Say what was not verified. A fix checked only by code review, or a probe that did not reproduce the defect, is reported as such.
- Without local evidence a cause is a hypothesis.
- No performance or conformance claim goes beyond what was measured.

## 9. Documentation

- The root holds only the READMEs, `BUILDING.md`, `MAINTENANCE.md`, `SECURITY.md`, this file and its `AGENTS.md` symlink. `docs/` holds only `upstream-reviews.md`.
- Only the README is translated. `README.md` is authoritative; `README.zh-CN.md` and `README.ja.md` are complete translations, updated in the same commit.
- A new review is a new section at the end of `docs/upstream-reviews.md`, with an `<a id>` anchor, and one row of the table in `MAINTENANCE.md`.

## 10. Git

- **Commit messages are in English**, enforced by `.githooks/commit-msg` and by `static-check.sh` over the whole history. Use an imperative subject of 72 characters or fewer and a body wrapped at about 72 columns that explains what and why. Keep trailers such as `Co-Authored-By` at the end.
- One topic per commit. Run `git status --short` and `git diff --check` before committing, and stage specific paths.
- Published history is never rewritten; an unpushed commit may be amended. Never force-push `main`, and never move or delete a tag or Release.
- Pushing, tagging and publishing are explicit maintainer decisions, taken one at a time.

## 11. Working practice

- Change only what the task needs.
- Keep `.work/` out of Git, pass `-derivedDataPath` inside it on every `xcodebuild` call, and remove build trees when the work is done.
- Report results as they are: failed checks with their output, skipped steps as skipped.
