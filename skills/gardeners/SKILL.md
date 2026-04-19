---
name: gardeners
description: Autonomous project gardening by a coordinated team of agents. Spawns a team of gardeners that each run the `garden` skill in parallel, coordinating via a shared task list to avoid duplicate work. Use when the user wants to tend multiple small issues in one pass. Invoke with /gardeners.
license: MIT
---

# Gardeners

A team version of the `garden` skill. Instead of one gardener pulling one weed, you spawn a small team that each pulls a different weed in parallel. They share a task list so two gardeners don't fight over the same issue.

Use this when the user wants a broader sweep than a single `garden` run would do -- several small, independent issues fixed in one pass. For a single focused fix, use the `garden` skill directly instead.

## Flow

1. **Create a team** with a shared task list
2. **Spawn N gardeners** (default 5) into the team, each instructed to run the `garden` skill with coordination rules
3. **Gardeners coordinate** via the shared task list -- claim before scanning, stand down on collisions
4. **Collect results** as each gardener reports in with a PR URL
5. **Review and merge** the PRs, then clean up

## Step 1: Create the team

Use `TeamCreate` to make a team named `gardeners` (or similar -- match to the session if helpful):

```
TeamCreate({team_name: "gardeners", description: "Gardeners running /garden in parallel, coordinating via shared task list"})
```

This gives the team a shared task list. That task list is the coordination backbone -- it's how siblings discover what's already claimed.

## Step 2: Spawn gardeners

Default to **five gardeners** unless the user asks for a different count. More gardeners means more coverage but more collisions; fewer means less parallelism.

Spawn each one with the `Agent` tool, passing `team_name: "gardeners"` and a distinct `name` (e.g. `gardener-1` through `gardener-5`). Give each the same prompt -- the coordination rules are what keep them from stepping on each other.

### Gardener prompt template

Each gardener needs:

- An identity (their name in the team)
- A reminder that siblings exist
- The coordination rules below
- Instructions to run the `garden` skill to completion and report back the PR URL

The coordination rules (include these verbatim in every gardener prompt):

```
1. Before scanning, call TaskList to see what other gardeners have already claimed or completed. Avoid duplicating their work.
2. When you pick an issue, immediately call TaskCreate with a specific subject (e.g. "Fix typo X in file Y") and TaskUpdate to set yourself as owner and status=in_progress. This tells siblings what you're working on.
3. If your scan surfaces additional issues beyond the one you pick, TaskCreate them as pending (no owner) so siblings can claim them.
4. If another gardener has already claimed the issue you'd have picked, scan for a different one -- don't open a duplicate PR.
5. On collision (two gardeners on the same issue), earliest claim wins. The later claimer stands down and picks something else.
6. When done, TaskUpdate status=completed and include the PR URL.
```

Run gardeners in the background (`run_in_background: true`) so they work in parallel. You'll get a notification as each reports in.

## Step 3: Let them work

Gardeners will:

- Post a claim to the task list when they pick an issue
- Broadcast (via `SendMessage`) if they detect a collision, citing earliest-claim-wins
- Surface additional findings from their scan as pending tasks for siblings
- Open a PR and mark their task completed

You generally don't need to intervene. If a gardener seems stuck, send them a message or check the task list for blocked tasks.

## Step 4: Collect results

As each gardener reports in, note the PR URL. Expect between `N-2` and `N` PRs from a team of `N` -- some gardeners may find nothing new to pick after coordination, which is fine.

## Step 5: Merge and clean up

Review the PRs together. Look for:

- Duplicates that slipped through (close the losers)
- PRs that should be combined

Then:

- Merge the good ones (squash, delete branch)
- Close any duplicates with a comment pointing at the survivor
- Prune stale local `garden/*` branches that are left over from the team run
- Shut down the team: `SendMessage` a `shutdown_request` to each gardener, then `TeamDelete`

## Notes

- **Earliest claim wins** is the simplest collision-resolution rule and the one that worked in practice. Don't overthink it.
- **Shared task list beats chat** for coordination. Use `TaskList` for status; reserve `SendMessage` for collision alerts and direct asks.
- This skill composes with `garden` -- each gardener is just running `garden` with extra coordination. If the single-gardener flow changes, this one benefits automatically.
