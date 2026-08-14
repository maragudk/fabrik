# Diary: Move the lead, builder, and writer agents off agent teams onto background sub-agents

The lead/builder/writer trio was designed around the harness's agent-team mechanism: teammates messaging each other directly via `SendMessage`, with the session's implicit team forming on first spawn. In practice the messages often cross or arrive delayed. Since the usual shape of the work is one lead and one or more builders, the team machinery buys little -- plain background sub-agents with a report-and-continue loop do the same job more reliably.

## Step 1: Rework the three agent definitions

**Author:** main

### Prompt Context

**Verbatim prompt:** The agent teams don't work so well in this harness. Messages often cross or get delayed. Since we mostly work with one lead agent and one or more builders, I think it would be easier to just use subagents that run in the background. Change the lead and builder agents appropriately. Also look through the other skills for team vocabulary. In particular, the gardeners skill stays as-is, as it depends on the team communication. For other skills, let's decide together before you make changes.

**Interpretation:** Rewrite `/agents/lead.md` and `/agents/builder.md` (and by implication `/agents/writer.md`, which shares the teammate vocabulary) so they use background sub-agents instead of the agent-team mechanism. Survey the skills for team vocabulary, leave gardeners untouched, and bring any other affected skills to Markus for a joint decision before changing them.

**Inferred intent:** Make the everyday lead-plus-builders workflow reliable in this harness by dropping the flaky mid-run teammate messaging in favor of the sub-agent primitives that actually work: background runs, final reports, and `SendMessage` continuations.

### What I did

Reworked all three agent definitions around one core shift: sub-agents can't message their caller mid-run, so a builder or writer that hits an unresolvable question ends its run with the question in its report, and the caller answers via `SendMessage`, which continues the agent with its context intact.

- `/agents/lead.md`: no longer a "team lead". It spawns named builders as background sub-agents (the name makes them addressable for `SendMessage` continuations), hands the full requirements in the spawn prompt since each builder starts fresh, and relays reports to the user as before. The "bridge" paragraph now describes the report-and-continue loop. Description frontmatter changed from "Team lead that..." to "Lead that...".
- `/agents/builder.md`: told explicitly it runs in the background and can't ask the lead mid-run -- it ends its run with the question instead of guessing. It spawns a writer sub-agent for prose rather than "handing a brief to a writer teammate". The scope-boundary "stop and ask the lead" became "stop and report it to the lead".
- `/agents/writer.md`: same treatment for its two "ask the caller" instructions and the scope boundary.
- `/README.md`: the lead's one-liner updated to match the new description.
- `/.claude-plugin/plugin.json`: 0.32.3 -> 0.32.4 (patch -- changes to existing functionality).

### Why

The team mechanism's direct teammate messaging is the part that misbehaves (crossed and delayed messages). Background sub-agents avoid it entirely: the only communication is the spawn prompt, the final report, and explicit `SendMessage` continuations -- all of which are reliable in this harness.

### What worked

The grep survey for team vocabulary (`team|teammate|SendMessage|ListAgents` over `skills/`) was quick and conclusive. Most hits were false positives -- "team" in the human-organization sense in the observability, git, marimo, and unsloth skills, plus historical diary and accomplishments entries that stay untouched.

### What didn't work

Nothing failed; the work was reading and editing prose, with no commands erroring.

### What I learned

Only two skills actually depend on agent-team communication: gardeners (shared task list plus messaging -- stays as-is per Markus) and code-reviewers (two reviewers debating via `SendMessage` with the orchestrator CC'd). Markus chose to leave code-reviewers as-is too, so both team-based skills remain on the team mechanism while the everyday agents move off it.

### What was tricky

The subtle behavioral redesign: "ask the lead rather than guessing" is good guidance under teams but impossible for a background sub-agent. Every "ask" instruction had to become "end your run with the question in your report", paired with the caller-side instruction to answer via `SendMessage` continuation -- otherwise builders would either stall or guess.

### What warrants review

Read the three agent files as a set and check the loop is described consistently from both sides: the builder/writer side (end the run with the question) and the lead side (answer via `SendMessage` to continue). Also check that no teammate vocabulary survived outside gardeners and code-reviewers.

### Future work

If the harness's team messaging becomes reliable, gardeners and code-reviewers are the reference implementations for moving the trio back -- or the trio's report-and-continue loop becomes the pattern for moving those two off teams instead.
