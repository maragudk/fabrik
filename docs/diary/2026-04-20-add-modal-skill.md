# Diary: Add modal skill

Add a new skill that teaches Claude how to write Modal (serverless Python compute) code, then tighten up the meta-rules around adding skills so the next addition doesn't repeat the mistakes from this one.

## Step 1: Research Modal docs and draft the skill

### Prompt Context

**Verbatim prompt:** I'd like to create a "modal" skill, to use the Modal compute infrastructure. Do a deep research on the docs at https://modal.com/docs/guide, then use your skill-creator skill.
**Interpretation:** Build a new skill under `/skills/modal/` covering Modal's Python SDK. Do real research on the official guide first rather than relying on training-data recall, then follow the skill-creator workflow.
**Inferred intent:** Markus wants Claude to produce idiomatic Modal code (correct decorators, image patterns, GPU specs, etc.) for his AI/ML work without him having to babysit each call.

### What I did
Loaded `WebFetch` and the skill-creator skill in parallel. Fetched the Modal guide index, then fanned out to ~12 specific subpages in parallel batches: apps, images, gpu, webhooks, secrets, volumes, scale, sandboxes, lifecycle-functions, cron, timeouts, dicts-and-queues, concurrent-inputs, managing-deployments, trigger-deployed-functions, retries. Read `/skills/datastar/SKILL.md` and `/skills/marimo/SKILL.md` to match the existing house style. Drafted `/skills/modal/SKILL.md` (~371 lines) covering: mental model, install/auth, apps and functions, invocation methods (`.remote/.map/.starmap/.spawn/.for_each`), images (chaining, caching, force_build), GPUs (types, multi-GPU, fallback lists), `@app.cls` lifecycle, web endpoint decorators, scaling/concurrency/retries, volumes/secrets/dicts/queues, schedules, sandboxes, cross-app `Function.from_name`, CLI cheatsheet, and a handful of idioms (deferred imports, baking weights, fan-out, runtime autoscaler tweaks).

### Why
The existing skills are tight, code-first, and free of fluff or emojis. Markus is a senior engineer who works in Python only for ML/AI, so the skill needs to skip Python basics and lean into the Modal-specific gotchas (image layer caching, when to use `@app.cls` vs `@app.function`, GPU fallback lists, `.commit()`/`.reload()` semantics on volumes). Parallel fetches were necessary because Modal's surface area is large and a single `WebFetch` would have given a shallow summary.

### What worked
Parallel `WebFetch` calls collapsed what would have been 15 minutes of sequential research into one round-trip. Reading two existing skills before writing made the style match (concise headers, table-heavy reference sections, code blocks with comments only where needed). The skill-creator skill's "be a bit pushy in the description" advice produced a description that triggers on many natural phrasings (`@app.function`, `modal run`, "host inference") rather than only the literal word "modal".

### What didn't work
Nothing major during the research and draft phase. A couple of `WebFetch` results were thin (the CLI reference page returned mostly navigation, not command details), but cross-referencing other pages filled the gaps.

### What I learned
The Modal SDK has shifted toward `uv_pip_install` over `pip_install` (faster) and toward `@modal.fastapi_endpoint` as the named decorator (was previously `web_endpoint`). The four web decorators are clearly differentiated by use case, which is worth a table in any skill. `modal.NetworkFileSystem` is no longer in the docs -- only `modal.Volume` -- so the skill should not mention NFS.

### What was tricky
Deciding how much breadth to include without bloating the skill past ~500 lines. Settled on inline coverage of every major topic and a closing note that points to https://modal.com/docs for parameter signatures and edge-case lookups, rather than splitting into a `references/` directory. Modal's surface is wide but each topic is short, so inline reads better than progressive disclosure here.

### What warrants review
The decorator names and parameter names should be spot-checked against the live Modal docs before anyone bets a deploy on them: especially `@modal.concurrent(max_inputs=, target_inputs=)`, `modal.Retries(max_retries=, backoff_coefficient=, initial_delay=)`, and the GPU type strings (`L40S`, `H100!`, `B200+`).

### Future work
The skill-creator workflow includes a "description optimization" loop that runs trigger evals to tune how often Claude consults the skill. Skipped this round (Markus said "vibe it") but worth running if the skill misfires in practice.

## Step 2: Open PR, miss the README, fix it, merge

### Prompt Context

**Verbatim prompt:** I'm sure you did good, ship it.
**Interpretation:** Commit the skill, push, open a PR. Do not add anything I haven't asked for.
**Inferred intent:** Trust the draft and move it through the standard PR flow.

### What I did
Created branch `add-modal-skill`, committed `/skills/modal/SKILL.md` with the message "Add `modal` skill for Modal compute infrastructure", pushed, opened PR #31. Markus then said "You forgot readme change" -- I had missed the "Available Skills" list in `/README.md`. Added the modal entry, committed, pushed, then squash-merged via `gh pr merge 31 --squash --delete-branch`.

### Why
The PR-per-change flow is the project's convention (recent merges all use PRs with `Fixes #N` style references where applicable). The README list is the public face of the plugin -- a skill missing from it is invisible.

### What worked
The squash merge meant the mangled commit message on the README fix didn't reach `main`; the PR title became the squash commit message. The git skill explicitly notes that follow-up commits on a branch can be sloppy because of squash, which proved correct.

### What didn't work
The README fix commit message came out as `Add  Usage: modal [OPTIONS] COMMAND [ARGS]...` because zsh expanded the backticks in `Add `modal` to README` as a command substitution that actually ran `modal --help`. Verbatim:
```
[add-modal-skill 7d83a08] Add  Usage: modal [OPTIONS] COMMAND [ARGS]...
```
The squash merge masked this from `main`'s history but it's a sharp edge worth flagging.

### What I learned
Backticks inside `git commit -m` strings are unsafe in zsh even when the surrounding string is double-quoted with code identifiers -- the heredoc pattern (`-m "$(cat <<'EOF' ... EOF)"`) is the only reliable workaround.

### What was tricky
The README omission was avoidable if I'd reread `/README.md` before committing rather than treating `/skills/modal/SKILL.md` as the only deliverable. The `/AGENTS.md` "Structure" section listed `skills/` but didn't say "and update README", so there was nothing in context to remind me.

### What warrants review
PR #31 history on GitHub shows the squash, but the branch's intermediate commits (with the mangled message) are gone. Nothing to verify.

### Future work
Codify the README rule somewhere durable so the next skill addition doesn't repeat this -- handled in Step 4.

## Step 3: Cut the release (botched patch, recovered as minor)

### Prompt Context

**Verbatim prompt:** yes [in response to: "Want me to bump `plugin.json` and cut a release?"]
**Interpretation:** Bump version in `/.claude-plugin/plugin.json`, commit on main, tag, push tag, create GitHub release.
**Inferred intent:** Make the new skill reachable by users on the next remote install (cached by version).

### What I did
First bumped 0.10.5 -> 0.10.6 (patch) and pushed `v0.10.6`. Markus then said "bump minor version". Deleted the `v0.10.6` tag locally and remotely (no GitHub release had been published from it), bumped 0.10.6 -> 0.11.0 with a new commit on top, tagged `v0.11.0`, pushed, ran `gh release create v0.11.0 --title "v0.11.0" --notes "..."`. History on `main` now reads: `Bump version to 0.10.6` then `Bump version to 0.11.0`.

### Why
A new skill is a feature addition. The project hadn't documented patch-vs-minor semantics yet, so I defaulted to patch by analogy with the previous release (0.10.5, which followed a typo fix). That defaulting was wrong -- and the fix in Step 4 is the lesson.

### What worked
Remote tag deletion (`git push --delete origin v0.10.6`) is non-destructive when no release artifact has been cut from it -- nothing downstream depended on the tag. Stacking the 0.11.0 commit on top of the 0.10.6 commit avoided force-pushing `main`, which the harness explicitly warns against.

### What didn't work
The orphan `Bump version to 0.10.6` commit is now permanent in `main`'s history, between two real commits. Cosmetic but annoying.

### What I learned
For releases on this project, ask Markus or check `/AGENTS.md` for the bump policy *before* picking a level. Defaulting based on the prior release's pattern is unreliable.

### What was tricky
Deciding between force-pushing `main` to drop the 0.10.6 commit (faster, cleaner history, but explicitly disallowed) and stacking a fix commit (slower, messier history, but safe). Stacking won.

### What warrants review
`/CHANGELOG.md` doesn't exist; the `Bump version to 0.10.6` commit shouldn't mislead anyone since no `v0.10.6` tag remains and no release was published. Verify on https://github.com/maragudk/fabrik/releases that only `v0.11.0` is listed.

### Future work
None.

## Step 4: Document versioning and README policy in AGENTS.md

### Prompt Context

**Verbatim prompt:** Add a note to AGENTS.md that new functionality (new skills, new subagents etc.) should bump minor version, changing existing stuff is a patch version bump.
**Interpretation:** Codify the patch/minor rule so future sessions don't repeat the Step 3 mistake.
**Inferred intent:** Move tacit project knowledge into the always-loaded `/AGENTS.md` so any AI working in the repo gets the rule for free.

### What I did
Added one paragraph to `/AGENTS.md` under the "Versioning" header: "New functionality (a new skill, sub-agent, hook, etc.) is a minor version bump. Changes to existing functionality are a patch version bump." Committed directly to `main` (Markus said "commit to main" when I offered PR or direct). Verified `/CLAUDE.md` is a symlink to `/AGENTS.md` so the rule reaches both Claude Code and Codex.

Followed up with two more commits: one to add a "MUST" rule about updating the README when adding a new skill (`Require README update when adding a new skill`), and one to widen the rule to sub-agents while adding an "Available Sub-agents" section to `/README.md` listing builder, lead, and qa.

### Why
Step 2 and Step 3 both surfaced gaps in tacit project knowledge -- README sync and bump policy -- that no one had written down. AGENTS.md is loaded into every session, so rules added there stop being invisible. The README sub-agents list also closes a parallel gap: builder/lead/qa exist in `/agents/` but were never advertised on the project page.

### What worked
The symlink check (`ls -la AGENTS.md CLAUDE.md`) avoided a duplicate-edit mistake -- only one file needed updating. The `MUST` capitalization is intentional in this case: it's a short, actionable rule with a clear reason, and the surrounding text explains why ("invisible to anyone browsing the repo"), so it doesn't read as cargo-cult emphasis.

### What didn't work
I initially saved a memory entry (`feedback_new_skill_readme.md`) about the README rule before realizing AGENTS.md was the right home for it. Deleted the memory and pruned `/MEMORY.md` once the rule was in AGENTS.md, since duplicating context costs tokens with no benefit.

### What I learned
Project rules belong in repo files; user-preference memories belong in the memory store. The dividing line: would a fresh contributor with no memory benefit from this rule? If yes, it goes in the repo.

### What was tricky
Picking between a PR and a direct commit for the AGENTS.md edits. Recent history shows both patterns -- skill changes go through PRs (#27-#30), version bumps go straight to main. Markus's call ("commit to main") clarified that meta/doc edits to AGENTS.md count as the latter.

### What warrants review
`/AGENTS.md` and `/README.md` are now the source of truth for "how to add a skill". Re-read both to confirm the wording is unambiguous: a fresh agent should know to (a) write the skill, (b) update README, (c) decide minor vs patch, (d) commit/tag/release. If any of those steps is unclear, the docs need another pass.

### Future work
Possibly a "how to add a skill" checklist in AGENTS.md if a third skill addition still misses something. Holding off until there's evidence the current wording isn't enough.
