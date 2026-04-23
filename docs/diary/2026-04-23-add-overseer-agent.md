# Diary: Add `overseer` sub-agent and share lead's worktree across team

Introduce a read-only observer for multi-feature parallel work, and reshape the lead/builder/qa isolation model so each feature lives in one shared worktree.

## Step 1: Design -- land on read-only observer shape

### Prompt Context

**Verbatim prompt:** I was thinking of adding an orchestrator agent that serves as an intermediate between me and the team lead. The thinking was that we can work on multiple features in the same repo in parallel and have the orchestrator agent check progress on each team lead. Each team lead has its own builder in its own QA agent, et cetera. Would this be possible?
**Interpretation:** Design an orchestrator that sits above multiple team leads, each with their own builder/qa sub-team.
**Inferred intent:** Enable parallel feature work in one repo without losing a single point of oversight.

### What I did
Researched Claude Code's team framework via the `claude-code-guide` agent. Confirmed that teammates cannot spawn their own teams (`TeamCreate`/`TeamDelete` are unavailable inside a team), so the literal "orchestrator of team-leads-with-sub-teams" shape is impossible. Walked through alternatives with Markus: backgrounded worktree agents vs. a flat team vs. a read-only observer. Landed on the observer shape: lead keeps creating its own team the way it works today, but the lead now also runs in a worktree, and a new agent (`overseer`) reads worktrees, diaries, and git state to report back to the user.

### Why
Observer-only sidesteps the nested-team limitation and the prompt-complexity cost of a flat team with lead-a/builder-a/lead-b/builder-b peers. It also matches how Markus actually wanted to interact -- "give me an overview of state and progress" rather than "coordinate my teams".

### What worked
Framing the options as a tradeoff table (team framework vs. backgrounded worktrees vs. observer) made the decision quick. Sending a focused research question to `claude-code-guide` with an explicit word limit kept the lookup short.

### What didn't work
First-pass name was "orchestrator", which overstated what the agent does. Renamed to `overseer` mid-design.

### What I learned
The Claude Code team framework is single-rooted and non-hierarchical: one team per orchestration session, no sub-teams. Worth remembering the next time someone wants nested coordination -- the answer will usually be "use backgrounded worktree agents and SendMessage by name" instead.

### What was tricky
Disentangling what the user wanted conceptually ("oversight across features") from the specific mechanism they proposed ("orchestrator spawning sub-teams"). The mechanism was blocked; the concept was fine.

### What warrants review
The overseer's scope boundary -- is "read-only, no process inspection, raw session logs only as fallback" the right line? Future use will tell whether the observer needs more reach.

### Future work
None implied from this step.

## Step 2: Implement worktree reshuffle, overseer agent, README

### Prompt Context

**Verbatim prompt:** Yeah, I like Overseer.
**Interpretation:** Proceed with the observer design using the name `overseer`.
**Inferred intent:** Ship the agent and the supporting isolation changes in one PR.

### What I did
Added `isolation: worktree` to `/agents/lead.md` and dropped it from `/agents/builder.md` and `/agents/qa.md` so each feature gets one worktree rather than three. Updated the lead's system prompt to note the shared-worktree arrangement. Wrote `/agents/overseer.md`: read-only, starts with `git worktree list` + diaries + git log, falls back to `~/.claude/projects/...` JSONLs only when structured signals don't explain team state, never inspects processes. Updated `/README.md` with the new agent and refreshed the builder/qa descriptions to mention "the lead's worktree".

### Why
The one-worktree-per-feature model keeps commits, diary entries, and reviews colocated, which is also what makes the overseer's job cheap -- it just walks worktrees and reads files.

### What worked
The frontmatter change was mechanical. Writing the overseer's prompt proportional to the other agent files (short, no filler) kept it consistent with the existing style.

### What didn't work
Nothing broke.

### What I learned
`isolation: worktree` on a sub-agent is declarative: the agent always gets a worktree regardless of caller. Moving it from builder/qa up to lead was the right lever -- subagents spawned by the lead inherit its working directory.

### What was tricky
Getting the mental model right on worktree inheritance. Initially considered leaving `isolation: worktree` on all three agents, which would have produced three disjoint worktrees per feature on three branches -- not what anyone wants.

### What warrants review
The frontmatter + prompt wording on all three agents; whether the overseer's fallback-to-session-logs heuristic is tight enough to avoid context bloat.

### Future work
Exercise the flow end-to-end on a real feature to confirm the shared-worktree story holds up in practice.

## Step 3: Move background-by-default to frontmatter

### Prompt Context

**Verbatim prompt:** For the background stuff, is it possible to add it to the metadata in the front matter?
**Interpretation:** Replace the prompt-level "always spawn in background" instruction with a frontmatter field, if one exists.
**Inferred intent:** Make the behavior declarative rather than relying on the lead remembering to pass `run_in_background: true`.

### What I did
Asked `claude-code-guide` whether such a field existed. It does: `background: true`. Added it to the frontmatter of `/agents/builder.md` and `/agents/qa.md`, and rewrote the lead's instruction from "always spawn them in the background" to "they run in the background by default".

### Why
Declarative > imperative for behavior that should be invariant. The lead no longer has to remember the flag, and the behavior now travels with the agent definition.

### What worked
One-line frontmatter change, one-line prompt tweak.

### What didn't work
Nothing.

### What I learned
The plugin agent frontmatter schema is broader than I had in memory: alongside `name`/`description`/`model`/`isolation` it also supports `background`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`. Worth consulting docs before reaching for prompt-level workarounds.

### What was tricky
Nothing.

### What warrants review
That `background: true` actually takes effect when the lead spawns builder/qa -- needs a live run to confirm.

### Future work
None.
