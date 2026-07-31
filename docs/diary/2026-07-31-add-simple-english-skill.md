# Diary: Add the simple-english skill

Copy the `simple-english` skill from the external repo [AminBlg/SimpleEnglish](https://github.com/AminBlg/SimpleEnglish) into fabrik, license included, then fix a dangling reference it shipped with and bump the plugin version.

## Step 1: Copy the skill from AminBlg/SimpleEnglish

**Author:** main

### Prompt Context

**Verbatim prompt:** "See the simple English skill here: https://github.com/AminBlg/SimpleEnglish

Copy it into this repo. Make sure to copy the license file as well."

**Interpretation:** Vendor the skill into fabrik's `skills/` directory as-is, and bring the upstream license along so the copy is properly attributed.

**Inferred intent:** Make the skill available through the fabrik plugin so it loads in Markus's sessions like the other skills, while staying compliant with the upstream MIT license.

### What I did

Cloned the upstream repo (depth 1) into the session scratchpad and inspected it. The repo contains more than the skill: evals with raw benchmark results, an examples directory, and a system prompt. The skill itself lives at `skills/simple-english/` and consists of `SKILL.md` plus `references/checklist.md` and `references/use-cases.md`.

Read all three skill files and the `LICENSE` (MIT, Copyright (c) 2026 AminBlg) before copying. Copied the skill directory to `/skills/simple-english/` and placed the license inside it at `/skills/simple-english/LICENSE` so it travels with the skill rather than sitting loose in the repo root next to fabrik's own files.

Added the README entry under Available Skills, alphabetically between `security-review` and `spec`, with a link crediting the upstream repo. Committed on the `add-simple-english-skill` branch and opened PR #86, which is now merged to main.

### Why

The skill teaches writing per ASD-STE100 Simplified Technical English: 20/25-word sentence limits, one word one meaning, active voice, condition before command. It doubles as an anti-slop filter for AI-generated docs. Only the skill directory was worth vendoring; the upstream evals and prompts are development artifacts for the upstream repo, not something the plugin should carry. The MIT license requires the copyright and permission notice to accompany copies, hence `/skills/simple-english/LICENSE`.

### What worked

Cloning to the scratchpad and reading everything before touching the repo made the scope decision easy: the skill directory maps one-to-one onto fabrik's existing `skills/<name>/SKILL.md` layout, so the copy was a plain `cp -R` with no restructuring.

### What didn't work

Nothing failed in this step. Clone, copy, README edit, and PR all went through on the first attempt.

### What I learned

The upstream SKILL.md frontmatter carries extra fields fabrik's own skills don't use (`version`, `license`, `compatibility`, `metadata`). Claude Code tolerates them, so a verbatim copy was fine, but they will drift from reality if we ever modify the skill without touching them — the upstream `version: 1.0.0` is already meaningless in this repo.

### What was tricky

Deciding where the license goes. Repo root would conflict with fabrik having its own licensing story; inside the skill directory keeps the notice attached to the exact files it covers. No other skill in the repo has a bundled license yet, so this sets the precedent for future vendored skills.

### What warrants review

Read `/skills/simple-english/SKILL.md` end to end once — it is opinionated (bans "should", semicolons, and most modals) and its self-check step is mandatory wording, so make sure that tone is wanted in sessions where it triggers. Confirm the README entry renders correctly and that the skill shows up in a fresh plugin install.

### Future work

Consider whether the strict frontmatter fields should be trimmed to match fabrik's house style. Upstream may also evolve; there is no sync mechanism, so any upstream improvements need manual re-vendoring.

## Step 2: Fix the dangling rules.md reference

**Author:** main

### Prompt Context

**Verbatim prompt:** "What's that rules.md file? Correct that."

**Interpretation:** I had flagged while copying that `references/checklist.md` tells check mode to "cite only rule numbers that appear in rules.md", but no `rules.md` exists. Markus asked what it was and told me to fix it.

**Inferred intent:** Ship the vendored skill without broken internal references, even if the bug came from upstream.

### What I did

Traced the reference: nowhere in the upstream repo does `rules.md` exist. The rule catalog lives in `SKILL.md` itself, whose own check-mode instruction correctly says "Cite only rule numbers that exist in this file". The checklist line is evidently a leftover from an earlier upstream layout where the rules sat in a separate file. Changed the line in `/skills/simple-english/references/checklist.md` to point at SKILL.md and committed on a new `simple-english-fixes` branch.

### Why

Check mode instructs the model to only cite rule numbers from a file it cannot find. A model following that literally has no valid source of rule numbers; a model improvising will invent them — the exact failure mode the skill itself warns about in SKILL.md ("the numbering is unintuitive and models invent it").

### What worked

Having read every file during the copy in Step 1 meant the inconsistency was already known and flagged in the PR body, so this was a one-line fix with no new investigation.

### What didn't work

Nothing failed. The fix is a single-line edit.

### What I learned

Vendoring verbatim first and fixing in a follow-up commit was the right order: the copy commit stays a faithful snapshot of upstream, and the deviation is its own commit with its own rationale in history.

### What was tricky

Nothing tricky; the only judgment call was fixing it locally versus staying byte-identical to upstream, and a broken reference is not worth preserving.

### What warrants review

Diff `945ee9e` — one line in `/skills/simple-english/references/checklist.md`. Check that no other file in the skill mentions `rules.md` (I searched; this was the only occurrence).

### Future work

This fix could be offered upstream as a PR to AminBlg/SimpleEnglish.

## Step 3: Version bump on the branch

**Author:** main

### Prompt Context

**Verbatim prompt:** "Do the version bump" followed by the correction "No, part of the branch, just the file change"

**Interpretation:** Bump the version in `/.claude-plugin/plugin.json` as a commit on the `simple-english-fixes` branch — only the file change, no tag or GitHub release yet.

**Inferred intent:** Get the version change reviewed and merged together with the checklist fix, deferring the tag and release until the branch lands on main.

### What I did

Set `version` to `0.29.0` in `/.claude-plugin/plugin.json` and committed it as `8e09031` on `simple-english-fixes`. The branch now holds two commits: the checklist fix and the bump.

### Why

A new skill is new functionality, which per the versioning rules in CLAUDE.md is a minor bump: 0.28.1 becomes 0.29.0. Remote installs are cached by version, so without the bump nobody gets the new skill. One bump covers both the skill (already on main) and the checklist fix (on this branch).

### What worked

I initially started the bump directly on main following the pattern of earlier bump commits; Markus redirected it onto the branch before anything was committed, so the correction cost nothing.

### What didn't work

Nothing failed; the redirect above was a scope correction, not an error.

### What I learned

Version bumps here belong in the same PR as the change they version, not as separate commits on main — CLAUDE.md's "bump the version together with any change" means literally together. The tag and `gh release create` still happen on main after the merge, on the bump commit.

### What was tricky

Sequencing: the skill merged without a bump, so the bump rides the follow-up branch. That leaves a window where main has the skill but not the version — harmless since installs only refresh on version change, but worth knowing when reading history.

### What warrants review

Confirm 0.29.0 is the intended number and that the release notes, when written, mention both the new skill and the checklist fix.

### Future work

After the branch merges: tag `v0.29.0` on the bump commit, push the tag, and create the GitHub release.
