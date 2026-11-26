---
name: garden
description: Autonomous project gardening. Scans the docs, code, and tests for maintenance issues, picks one, fixes it in a worktree, self-reviews with competing agents, and opens a PR. The fix can be as small as a stale doc reference or as heavy-handed as pruning useless tests, combining duplicated ones, deleting dead code, or refactoring and simplifying code. Use when the user wants to tidy up the project, fix stale docs, prune or consolidate tests, simplify or refactor code, or generally tend the codebase. Invoke with /garden.
license: MIT
---

# Garden

A single-shot autonomous maintenance agent. You invoke it, it finds one thing worth fixing, fixes it well, and opens a PR. Then it stops. Think of it as a gardener walking through the project, tending one thing per visit: sometimes pulling a weed, sometimes taking the shears to an overgrown bed.

Inspired by the "doc-gardening" and "garbage collection" concepts from agent-first engineering: steady, small-batch tending beats painful cleanup sprints.

## Flow

1. **Setup** -- enter a worktree on a `garden/`-prefixed branch
2. **Scan** -- survey the project for maintenance issues
3. **Select** -- pick the single most worthwhile issue to fix
4. **Fix** -- make the change, commit it
5. **Self-review** -- dispatch two competing sub-agents to review the fix
6. **Iterate** -- if reviewers find problems, fix and re-review (max 3 rounds)
7. **Ship** -- open a PR against the main branch

## Step 1: Setup

Create a worktree and branch:

```bash
REPO="$(git rev-parse --show-toplevel)"
WORKTREE="$REPO/.claude/worktrees/garden-$(date +%Y%m%d-%H%M%S)"
git worktree add "$WORKTREE" -b garden/<descriptive-slug>
echo "repo: $REPO"
echo "worktree: $WORKTREE"
```

Record both paths the block echoes -- `git worktree add` prints neither. Shell state doesn't survive to your next command: the variables are gone, and in a sub-agent thread the working directory resets too. So pass the worktree path explicitly from here on. Prefix later commands with `cd <worktree> &&`, hand the path to the reviewers you dispatch in Step 5, and reuse both paths in Step 7.

Don't re-derive the worktree path with a `garden-*` glob. Another garden run may have a worktree of its own, and both `cd` and `git worktree remove` fail when the glob matches more than one.

The branch name should reflect the issue you end up fixing (you can rename it after the scan). Use the `garden/` prefix always.

## Step 2: Scan

Survey the project for maintenance issues. The scan is intentionally broad -- you're a gardener walking through the plot, noticing what needs attention. You don't need to find everything. Some things you catch this time, others next time.

Read the project's documentation, code, and tests, cross-reference them against each other, and build a list of findings.

### Docs plot

Look for these kinds of issues in documentation:

- **Stale docs** -- documentation that describes code, behavior, APIs, or project structure that no longer exists or has changed
- **Orphaned references** -- links to files, functions, sections, or URLs that don't exist or are broken
- **Missing docs** -- code, features, packages, or entry points that should be documented but aren't
- **Inconsistencies** -- docs that contradict each other or contradict the code
- **README drift** -- the README doesn't reflect the current state of the project (structure, features, usage, dependencies)

### Code plot

Look for code that could be less code, or plainer code, while doing the same thing:

- **Dead code** -- functions, types, parameters, flags, imports, and branches that nothing uses or reaches
- **Duplicated logic** -- the same thing implemented in several places that could be one
- **Needless complexity** -- abstractions with a single user, indirection that hides nothing, options nobody sets, a long function that a short one would replace
- **Inconsistent patterns** -- one problem solved several ways where the project clearly has a preferred way
- **TODO graveyards** -- TODOs and commented-out code that are done, obsolete, or never going to happen

### Tests plot

Look for tests that cost more to keep than they are worth:

- **Useless tests** -- tests that cannot fail, or that say nothing about the project's own behavior: they exercise a mock, the standard library, or a dependency, or they restate the implementation line by line
- **Duplicated tests** -- several tests covering the same behavior that could be one test, or one table of cases
- **Stale tests** -- skipped or disabled tests nobody will re-enable, tests of behavior that was removed, helpers and fixtures no test uses

### How heavy-handed to be

The size of the change follows from the issue, not from a preference for small diffs. Deleting a few hundred lines or reshaping a package is fine when that is what the issue takes. What keeps heavy-handed work safe is not its size but these rules:

- **Preserve behavior.** A refactor or simplification changes how the code is written, not what it does. If you find a bug along the way, leave it in place and mention it in the PR; a fix hidden inside a refactor is hard to review.
- **Leave public interfaces alone.** Don't rename, remove, or change the signature of anything other projects or users depend on -- a library's exported API, a CLI's flags, an HTTP API, a database schema.
- **Lean on the tests.** Run the test suite before you change anything, so you know what passes, and again after. If the code you want to reshape has no tests covering it, pick something you can verify, or keep the change small enough to verify by reading.
- **Account for every test you remove.** For each one, be able to say what it fails to check, or which remaining test covers the same behavior. A test that looks redundant but exercises an edge case nothing else does stays. When combining tests, every case from the originals survives in the result.
- **Don't reshape code and prune its tests in one change.** The tests are what verify the refactor; if both move at once, nothing does.

### What to leave alone

Leave generated code, vendored code, and third-party code alone, along with anything the project marks as not to be edited by hand.

Do not modify log-like or append-only documentation. These are historical records, not living docs. Specifically:

- **Decision logs** -- files like `docs/decisions.md`. These are chronological records of past decisions. Even if they reference things that no longer exist, that's intentional -- they record what was decided at the time.
- **Diary entries** -- files in `docs/diary/` produced by the diary skill. These are implementation narratives. They capture what happened, including failures and dead ends. Do not "fix" them.
- **Changelogs** -- any CHANGELOG or HISTORY files. These are release records.

If you're unsure whether something is a living doc or a historical record, leave it alone.

### Future plots (not yet active)

These are natural extensions for the future. Don't act on them now, but the scan architecture is designed to accommodate them:

- **Dependencies** -- outdated packages, unused dependencies, security advisories
- **Test coverage** -- uncovered code paths, flaky test patterns
- **Config** -- drift between environment configs, stale CI steps, unused build targets

## Step 3: Select

From your findings, pick the single most worthwhile issue to fix. Use your judgment -- consider severity, your confidence in the fix, and how cleanly it can be resolved. There's no rigid prioritization formula, and no preference for the smallest issue: a larger pruning you're confident in beats a typo.

State what you picked and why before proceeding.

## Step 4: Fix

Make the change. Keep it **focused** -- one issue, one PR -- but as large as the issue needs. Cutting a whole bed back is fine; replanting the garden while you're at it is not. If fixing one thing reveals three others, note them mentally but only address the one you selected.

Respect the project's existing conventions. Read CLAUDE.md, check for linters, understand the project's style. Don't impose your own preferences -- tidy according to the standards already in place.

Run the project's tests, linters, and build, and make sure they pass, then commit the change with a clear message.

## Step 5: Self-review

Dispatch two sub-agents to review the change. Tell them:

- They are competing with another agent to find issues
- They should review both correctness and whether the fix introduces new problems (e.g., updating a doc reference that accidentally breaks another cross-reference)
- They should verify the fix actually addresses the finding -- not just that it's a valid change, but that it's the right change
- For a code change, they should check that behavior and public interfaces are unchanged, and run the tests themselves rather than take your word for it
- For removed or combined tests, they should check each one: was it really useless, and is every case that mattered still covered?
- Whichever agent finds more real issues wins honour and glory

## Step 6: Iterate

If the reviewers find problems:

1. Address the feedback
2. Commit the fix
3. Re-run the competing review

Cap at **3 iterations**. If after 3 rounds there are still concerns, proceed to shipping but include the unresolved concerns in the PR description.

## Step 7: Ship

Open a PR against the main branch. The PR description should have this structure:

```markdown
## What was found

<the issue and where it was found>

## What was fixed

<the change and why>

## Review notes

<any unresolved concerns from self-review, or "Clean review -- no concerns raised.">
```

If the change removes or combines tests, list each one under "What was fixed" and say why it went or where its cases now live. The reader shouldn't have to reconstruct that from the diff.

After opening the PR, remove the worktree and stop.

```bash
cd <the-repo-path-from-step-1>
git worktree remove <the-worktree-path-from-step-1>
```
