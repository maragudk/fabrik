# Diary: Add the memory skill

Markus wants agents to keep project memory in a `## Memory` section at the bottom of `AGENTS.md` instead of in the harness's built-in memory, as an opt-in per project. This diary covers designing the `memory` skill, testing it with skill-creator, and optimising its description so it triggers at the right times.

## Step 1: Design and first draft

**Author:** main

### Prompt Context

**Verbatim prompt:** I'd generally like agents to disable their in-harness memory, but not always. Should we make a memory skill?

Properties:
- In-harness memory is turned of via config per project
- Memory is instead a `## Memory` section at the bottom of AGENTS.md
- This is opt-in, but once the section is there, that's what's used
- This is often for temporary memory or something that doesn't easily fit elsewhere
- It complements the more detailed info in the diary and the raw conversations in docs/conversations/, both of which are optional too

Thoughts?

Followed by: "I'd like a setup part (say, if there is no ## Memory section and the user asks for one) and a "use memory" part. The latter should basically mirror how your instructions tell you when to use your harness' built-in memory.", then "And we can make the skill description so it fires at the right times. Use your skill creator skill", and "And maybe don't refer to how to disable memory currently, that may change in the future and across harnesses. Just tell the agent to look up instructions on how to do it."

**Interpretation:** Build one skill with two parts. The "use" part carries over the rules my own harness gives me for built-in memory (what to save, what not to, weighing feedback, updating, pruning), adapted to a committed section in a file. The setup part adds the section and turns built-in memory off, without hardcoding how.

**Inferred intent:** Make memory visible and reviewable in the repo, and identical across Claude Code, Codex, and Antigravity, without committing fabrik to any one harness's current settings.

### What I did

I first argued for putting the rules in the section itself and keeping the skill for setup only, on the grounds that a skill only loads when its description matches. Markus chose the two-part skill, so I wrote `/skills/memory/SKILL.md` that way, and added the entry to `/README.md`. The section's one-line introduction names the skill, which gives every later session an always-loaded pointer to the rules.

The "use" part mirrors my built-in memory instructions: the four kinds (user, feedback, project, reference), **Why:** and **How to apply:** for feedback and project entries, absolute dates, update rather than duplicate, don't save what the repo records or what only matters to the conversation, ask what was non-obvious when asked to remember such a thing, don't overindex on soft feedback, and keep cautions about destructive actions until the user confirms.

### Why

Mirroring the existing rules means agents behave the same whether memory lives in the harness or in `AGENTS.md`; only the storage changes.

### What worked

Reading `AGENTS.md` costs nothing, since the harness already loads it. That leaves the skill responsible only for writing and for setup.

### What didn't work

My first proposal (rules in the section, no "use" part in the skill) was not what Markus wanted. Nothing failed technically.

### What I learned

The section differs from built-in memory in three ways that needed their own rules: it is committed and possibly public (nothing private), temporary notes are welcome (so every entry carries a date and there is a pruning rule), and saving is an edit to a tracked file (so the agent says in one line what it saved, and doesn't commit just for a memory).

### What was tricky

Staying out of harness specifics. A research agent confirmed that Claude Code's switch is `autoMemoryEnabled: false` in `.claude/settings.json`, that Codex's `memories` feature is off by default, and that Antigravity documents no switch. None of that is in the skill: step 3 of setup tells the agent to look up the current instructions and to say so plainly when it finds none.

### What warrants review

The wording of "What to save" and "What not to save" in `/skills/memory/SKILL.md`, since those decide what ends up in every project's `AGENTS.md`.

### Future work

Run the setup on fabrik itself. Roughly half of its current built-in memories are cross-project feedback that belongs in the injected `/hooks/scripts/AGENTS.md` instead.

## Step 2: Behaviour tests with and without the skill

**Author:** main

### Prompt Context

**Verbatim prompt:** And we can make the skill description so it fires at the right times. Use your skill creator skill

**Interpretation:** Follow skill-creator's loop: draft, test prompts with and without the skill, grade, review.

**Inferred intent:** Evidence that the skill changes behaviour, not just a plausible document.

### What I did

I built a small Go fixture project (`kiosk`) in the scratchpad and ran four cases, each with and without the skill, as subagents: a correction given mid-task with the section present, a stale entry plus "remember that we fixed X", setup from scratch, and a correction with no section. File facts were graded by a script and the replies by reading them. When Markus renamed the skill from `project-memory` to `memory`, I re-ran all eight.

### Why

The opt-in boundary and the setup flow are the parts an agent can't infer from the section alone.

### What worked

With the skill: 25 of 25 assertions in both rounds. Without: 22 of 25, then 23 of 25. Setup with the skill appended the standard section, set `autoMemoryEnabled` after fetching the Claude Code docs, cited them, and checked for memories to migrate. With no section, the skilled agent left `AGENTS.md` alone and quoted what it would save to built-in memory.

### What didn't work

`generate_review.py` failed under the system Python 3.9:

```
TypeError: unsupported operand type(s) for |: 'type' and 'NoneType'
```

Running it with `/opt/homebrew/bin/python3.15` worked. `aggregate_benchmark.py` printed "No eval directories found" until I rebuilt the results as `eval-<name>/<config>/run-1/`.

### What I learned

When the section already exists, the skill barely changes behaviour. The introductory line and the existing entries teach the format, and the baseline also declined to record a completed fix. The skill's measurable effect is in setup (the baseline invented its own inline rules and told agents to scatter notes across the file's other sections) and in holding the opt-in line (the baseline wrote the rule into the Testing section). One run per case, so this is thin evidence.

### What was tricky

Nothing confused a skill named `memory` with built-in memory, which was the reason I had first proposed `project-memory`.

### What warrants review

Whether the baseline's behaviour in the no-section case (writing a convention into the body of `AGENTS.md`) is actually worse. The skill treats that as a question for the user.

### Future work

None.

## Step 3: Description optimisation

**Author:** main

### Prompt Context

**Verbatim prompt:** Change name to just "memory", then also run description optimisation. Make sure it's not on Fable or Opus probably though?

**Interpretation:** Rename the skill, then run skill-creator's description loop on a cheaper model.

**Inferred intent:** A description that fires when it should, measured without spending the expensive models on hundreds of runs.

### What I did

I wrote 20 trigger queries, ten that should fire and ten near-misses (a memory leak, an in-memory cache, memoization, other `AGENTS.md` edits, a diary entry, a question about how auto memory works). I ran `scripts.run_loop` with `--model claude-sonnet-5-5` from a fixture project that has the section and built-in memory turned off, since that is the only state in which the skill should fire.

### Why

The skill is unusual in that it should trigger mid-task, on a remark the user makes in passing.

### What worked

The original description never fired on a near-miss, but missed three of the ten positives: two corrections given mid-task and a user describing their own background. The loop's rewrite fixed the two corrections by adding "even in passing or mid-task alongside another request" and quoting typical phrasings. I added a clause for facts about the user, and the result passed 20 of 20 queries, 59 of 60 runs.

### What didn't work

The stock `run_eval.py` only counts a skill invoked as the session's first tool call, and returns false as soon as any other tool is used. A hand-run showed Sonnet calling `fabrik:go`, then several `Bash` calls, and only then the memory skill, as its fifth to seventh tool call. Stock scoring would have marked every mid-task query a miss. I patched a scratch copy to watch the whole turn, to give each run its own copy of the fixture project with `--permission-mode acceptEdits` and `--no-session-persistence`, and to log the tools each run used.

The final description came out at 1,031 characters, over the 1,024 limit, so I shortened two phrases. `quick_validate.py` needs `yaml`, which Python 3.15 lacks, so validation runs under the system `python3`.

### What I learned

For a skill meant to fire mid-task, first-tool-call scoring measures the wrong thing, and an optimiser fed that signal would push the description towards "always invoke this first".

### What was tricky

The loop picks the best description by held-out score, and the held-out set was eight queries. Both candidates scored 7 of 8, so it reported the original as best even though the rewrite fixed two training misses. I took the rewrite.

### What warrants review

The last clause of the description ("something about themselves...") is mine and targets the one query both candidates missed, which was in the held-out set, so the final 20 of 20 is not a clean held-out result. The two phrases trimmed for length were not re-tested. Everything was measured on Sonnet; triggering on other models may differ.

### Future work

Watch real sessions in a project with the section for missed saves, and feed them back through `improve-skill`.
