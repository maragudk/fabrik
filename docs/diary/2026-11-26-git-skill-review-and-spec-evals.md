# Diary: Review the `git` skill and test the `spec` skill

Markus felt the `git` skill had drifted out of date, so we went through it point by point. Afterwards I took over PR 152, which adds the `spec` skill, tested it with the `skill-creator` evaluation loop, fixed two problems the tests found, and merged it.

## Step 1: Trim the `git` skill

**Author:** main

### Prompt Context

**Verbatim prompt:** I think the git skill is a bit outdated. Let's go through it
**Interpretation:** Read `/skills/git/SKILL.md`, list what looks stale, and decide each point with Markus.
**Inferred intent:** Keep only the git preferences that differ from what the harness already does, so the skill isn't spending tokens on things agents already know or on rules that no longer apply.

### What I did

I read the skill and listed seven candidate issues. Markus invoked `one-at-a-time`, so we settled them one per message, in the worktree `/.claude/worktrees/git-skill`. Decisions:

- **Description:** rewritten to say the skill is about how Markus's git preferences diverge from the harness's defaults.
- **Backticks-in-the-shell bullet:** dropped. It is general shell knowledge, not a preference.
- **"Ask about GitHub issues before committing":** dropped. Markus then asked to keep a fabrik-specific note, so `/AGENTS.md` now says "Fabrik doesn't use GitHub issues, so don't ask about issues to reference in commits."
- **"Assign Markus as PR reviewer":** dropped, and with it the whole "Creating pull requests" section.
- **Screenshots via Artifact, merging rules:** kept as they are.
- **Worktree-first and push-gate rules:** left out of the skill. The lead agent already works in a worktree, and fabrik's reasons for both are specific to this repo.

Midway through, Markus pointed out new `git` skill changes on `origin/main` (a "Using `gh`" section, the merge-checks bullet, and cleanup without asking). I fast-forwarded `main` and the worktree, popped my stashed edits, and resolved the one conflict by keeping upstream's `gh` section and dropping the reviewer section. I committed `f3a9135`, fast-forwarded `main`, and removed the worktree. After PR 152 merged I rebased it to `dfece27` and pushed on Markus's approval.

### Why

The skill had picked up rules that either duplicate default behavior or block work in repos where they don't apply. The issues question in particular stopped every commit.

### What worked

Going one decision at a time kept each change small and reversible. Markus reversed one decision right after I made it (the fabrik issues note), and that was cheap to fix because nothing else depended on it yet.

### What didn't work

My first `edit` of `/CLAUDE.md` was refused: "Refusing to write .../CLAUDE.md: it is a symbolic link. Write to the link's target path instead: .../AGENTS.md." `CLAUDE.md` is a symlink to `AGENTS.md`, so edits have to go to `AGENTS.md`.

My first replacement in `AGENTS.md` also removed the blank line before `## Adding a new skill, sub-agent, or hook`, and I had to put it back.

`git stash pop` after fast-forwarding to `origin/main` gave "CONFLICT (content): Merge conflict in skills/git/SKILL.md", because upstream had inserted its new section right next to the one I deleted.

### What I learned

When a skill rule gets deleted, a project's `AGENTS.md` may still contain an opt-out that refers to it. Here the fabrik line "skip the `git` skill's question" would have pointed at nothing, so the reference had to be reworded at the same time.

### What was tricky

The skill gets loaded by every running session from the main checkout, so all edits had to stay in the worktree until the end. That made rebasing onto the upstream changes a stash-and-pop job rather than a simple pull.

### What warrants review

`git show dfece27`: the new description and the three removals in `/skills/git/SKILL.md`, plus the reworded issues line in `/AGENTS.md`.

### Future work

None.

## Step 2: Take over PR 152 and test the `spec` skill

**Author:** main

### Prompt Context

**Verbatim prompt:** Now take over PR 152. Use your skill-creator skill to check the new skill
**Interpretation:** Check out the `spec-skill` branch, run the `skill-creator` loop on `/skills/spec/SKILL.md` (test prompts, runs with and without the skill, grading), and fix what turns up.
**Inferred intent:** Find out whether the skill really changes agent behavior before merging it.

### What I did

I checked out the branch in `/.claude/worktrees/spec-skill` and confirmed with `git merge-tree` that it merged cleanly with `main`. In the scratchpad I built a small fixture project, "regroup", with a `docs/spec.md`, `docs/todo.md`, a diary entry, and a `sqlite/users.go`. Markus approved four test prompts: propose-but-don't-write ("exports are CSV only"), implementation detail in the wrong place (sqlc and the `Store` struct), a feature the spec rules out (soft delete when the spec says deletions are immediate), and writing already-agreed wording verbatim. Each prompt ran twice, once with the skill and once without, in separate general-purpose sub-agents.

Round 1: all checks passed with the skill and 75% passed without it. Two findings led to edits:

1. The soft-delete run picked a 30-day restore window, the same as the skill's example entry ("Deleted data is gone after 30 days"). I replaced the example in both places with one about leaving a group.
2. The sqlc run with the skill added a line to `docs/todo.md` without asking, because the skill said "say where it goes instead and put it there". I changed that to "offer to put it there".

Round 2 reran sqlc and soft delete and added a CSV test against a spec without its own agreement preamble. All checks passed with the skill and 50% without it. I committed `c297bcc` to the PR branch, pushed, and merged PR 152 as `2e2981b` on Markus's explicit "push and merge pr 152".

### Why

The fixture's spec opened with "nothing is added without agreement", so the runs without the skill already avoided writing unagreed wording. The no-preamble test isolates what the skill adds by itself.

### What worked

The no-preamble CSV test was the clearest result. Without the skill, the agent wrote "**Exports are CSV only.**" straight into `docs/spec.md` without asking. With the skill, it proposed the wording and waited.

### What didn't work

- `tools.Agent` returned `status: "async_launched"` right away, so my first collection step ran before any agent had finished (every run took about 338 ms and produced empty diffs). The real results came later as task notifications.
- One sub-agent wrote its `response.md` to `iteration-1/propose-not-write/outputs/` instead of `.../with_skill/outputs/`, and I had to move it.
- `aggregate_benchmark` printed "No eval directories found" until I renamed the directories to `eval-N-*/<config>/run-1/`.
- `generate_review.py` failed under the system Python 3.9: "TypeError: unsupported operand type(s) for |: 'type' and 'NoneType'". It worked with `uv run --python 3.12`.
- Taildrop to the MacBook failed with "not connected to the tailnet", so Markus never saw the review page. I summarized the results in chat instead.
- My guess that "30 days" leaked from the example was wrong. In round 2 the skill still picked 30 days, and the runs without the skill suggested it too. It is just the usual default.
- `gh pr merge 152 --merge --delete-branch` also removed the local worktree and branch, so my own cleanup failed with "fatal: Not a valid object name spec-skill".

### What I learned

A fixture that states its own rules makes the baseline look much better than it is. For a skill that gates writes, the test project has to leave the rule out of the files the agent reads.

### What was tricky

Deciding what counts as evidence. The 30-day result looked like the example leaking until the baseline produced the same number. The example swap is harmless, but this test didn't show it was needed.

### What warrants review

`git show c297bcc` for the two `spec` skill edits. The eval workspace is in this session's scratchpad (`spec-workspace/`), which may be cleared.

### Future work

The `skill-creator` description-optimization loop hasn't been run on `spec`.
