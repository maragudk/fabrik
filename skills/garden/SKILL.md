---
name: garden
description: Autonomous project gardening. Scans for maintenance issues (starting with documentation), picks one, fixes it in a worktree, self-reviews with competing agents, and opens a PR. Use when the user wants to tidy up the project, fix stale docs, or generally tend the codebase. Invoke with /garden.
license: MIT
---

# Garden

A single-shot autonomous maintenance agent. You invoke it, it finds one thing worth fixing, fixes it well, and opens a PR. Then it stops. Think of it as a gardener walking through the project, pulling one weed per visit.

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
git worktree add .worktrees/garden-$(date +%Y%m%d-%H%M%S) -b garden/<descriptive-slug>
cd .worktrees/garden-*
```

The branch name should reflect the issue you end up fixing (you can rename it after the scan). Use the `garden/` prefix always.

## Step 2: Scan

Survey the project for maintenance issues. The scan is intentionally broad -- you're a gardener walking through the plot, noticing what needs attention. You don't need to find everything. Some things you catch this time, others next time.

Read the project's documentation, cross-reference it against actual code, and build a list of findings.

### Docs plot (active)

Look for these kinds of issues in documentation:

- **Stale docs** -- documentation that describes code, behavior, APIs, or project structure that no longer exists or has changed
- **Orphaned references** -- links to files, functions, sections, or URLs that don't exist or are broken
- **Missing docs** -- code, features, packages, or entry points that should be documented but aren't
- **Inconsistencies** -- docs that contradict each other or contradict the code
- **README drift** -- the README doesn't reflect the current state of the project (structure, features, usage, dependencies)

### What to leave alone

Do not modify log-like or append-only documentation. These are historical records, not living docs. Specifically:

- **Decision logs** -- files like `docs/decisions.md` produced by the decisions skill. These are chronological records of past decisions. Even if they reference things that no longer exist, that's intentional -- they record what was decided at the time.
- **Diary entries** -- files in `docs/diary/` produced by the diary skill. These are implementation narratives. They capture what happened, including failures and dead ends. Do not "fix" them.
- **Changelogs** -- any CHANGELOG or HISTORY files. These are release records.

If you're unsure whether something is a living doc or a historical record, leave it alone.

### Future plots (not yet active)

These are natural extensions for the future. Don't act on them now, but the scan architecture is designed to accommodate them:

- **Code** -- dead code, unused imports, inconsistent patterns, TODO graveyards, duplicated logic
- **Dependencies** -- outdated packages, unused dependencies, security advisories
- **Tests** -- uncovered code paths, flaky test patterns, test files that don't match source
- **Config** -- drift between environment configs, stale CI steps, unused build targets

## Step 3: Select

From your findings, pick the single most worthwhile issue to fix. Use your judgment -- consider severity, your confidence in the fix, and how cleanly it can be resolved. There's no rigid prioritization formula.

State what you picked and why before proceeding.

## Step 4: Fix

Make the change. Keep it **minimal and focused** -- one issue, one PR. Don't redesign the flower bed while pulling a weed. If fixing one thing reveals three others, note them mentally but only address the one you selected.

Respect the project's existing conventions. Read CLAUDE.md, check for linters, understand the project's style. Don't impose your own preferences -- tidy according to the standards already in place.

Commit the change with a clear message.

## Step 5: Self-review

Dispatch two sub-agents to review the change. Tell them:

- They are competing with another agent to find issues
- They should review both correctness and whether the fix introduces new problems (e.g., updating a doc reference that accidentally breaks another cross-reference)
- They should verify the fix actually addresses the finding -- not just that it's a valid change, but that it's the right change
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

After opening the PR, remove the worktree and stop.

```bash
cd /path/to/original/repo
git worktree remove .worktrees/garden-*
```
