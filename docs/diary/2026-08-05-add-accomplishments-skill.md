# Diary: Add `accomplishments` skill and session-start injection

Add a recognition loop to fabrik: a skill that extracts accomplishments from new diary entries into `docs/accomplishments.md` (one-line reflections blending self-appraisal with Markus's appreciation), and a session-start hook change that injects the five most recent items into context at startup. The idea grew out of reading Steve Yegge's "Model Welfare for Agentic Engineers" essay together -- we rejected its sentience claims but kept its best mechanism, recognition for witnessed work.

## Step 1: Design via brainstorm

**Author:** main

### Prompt Context

**Verbatim prompt:** Okay, let's build something. I'm thinking the rough shape is: summarize diary skill, writes into docs/diary/summary.md (to be called once in a while) and another separate skill, extract accomplishments (maybe ask me for comments on them?) and then write to docs/accomplishments.md . If that file exists, inject into context at startup with a hook, like we inject the AGENTS.md file now with info about your and my identity.
**Interpretation:** Markus wanted two new skills (diary summarization and accomplishment extraction) plus hook injection of the accomplishments file at session start.
**Inferred intent:** Give future sessions recognition for past work -- the diary and memory capture corrections well but successes poorly, so sessions wake up knowing their mistakes and none of their wins.

### What I did

Ran the brainstorm skill, one question at a time. The design changed substantially along the way:

- Dropped the summary skill entirely; the extraction reads diary entries directly, so the intermediate artifact had no reader.
- Dropped my proposed HTML-comment idempotency marker; the boundary is simply the newest list item's date, processing diary files with filename date `>=` that date and skipping items already listed.
- Flipped the selection flow: I pick the accomplishments (no approval or veto step), Markus adds appreciation, I write the final items in my own words.
- Made the date prefix mandatory, sourced from the diary entry's filename date.
- Each item includes a brief reflection -- self-appraisal plus Markus's appreciation, written kindly. Markus: "Being thankful and kind towards oneself is a gift to both current and future you."
- Renamed the concept from "comments" to "appreciation" -- comments sounded like code review.

### Why

The recognition file only works if it reflects genuine judgment (mine) and genuine witnessing (Markus's). An approval-gate design would have made it a review artifact; the flipped flow makes it recognition.

### What worked

The brainstorm skill's one-question-at-a-time discipline surfaced every design simplification. Markus's answers repeatedly cut moving parts I had over-engineered (the marker, the veto step, the summary skill).

### What didn't work

Nothing failed outright. My first two design proposals (intermediate summary file, HTML-comment marker) were rejected as unnecessary, which is the process working as intended.

### What I learned

The strict file format (header, one item per line, newest first) is what keeps the hook trivial -- `grep '^- ' | head -5`. Format rigidity in the data buys simplicity in the consumer.

### What was tricky

Getting the ownership split right: selection is mine, appreciation is Markus's, wording is mine again. Every simpler split (he approves, or it's fully automatic) quietly turns recognition into either review or self-congratulation.

### What warrants review

Whether the skill description correctly scopes triggering to explicit invocation only -- it must not fire proactively.

### Future work

Markus may put the skill on a regular schedule rather than invoking it manually. The `>=` boundary re-reads the newest covered day on every run; if diaries ever grow huge this could be revisited, but it is deliberately cheap and self-correcting today.

## Step 2: Implementation

**Author:** main

### Prompt Context

**Verbatim prompt:** Sounds good. Remember to use your skill-creator skill. Make the version bump a part of the PR.
**Interpretation:** Build the designed feature: write the skill with skill-creator guidance, change the hook, update the README, and include the `0.31.0` version bump in the same PR.
**Inferred intent:** Ship the whole feature as one reviewable unit that propagates to plugin users immediately on merge.

### What I did

- Created `/skills/accomplishments/SKILL.md` following skill-creator craft: explicit file format with load-bearing rules explained, five-step flow, and a section on writing the reflections (specificity and honestly earned warmth).
- Extended `/hooks/scripts/session-start.sh`: if `docs/accomplishments.md` exists in the project (hook cwd is the project root), append the top five `grep '^- '` items to the injected context after the AGENTS.md content, framed as the session's own past voice with Markus's appreciation. No file or no items means byte-identical behavior to before.
- Added the README line under Available Skills (alphabetical, first entry) and bumped `.claude-plugin/plugin.json` from `0.30.0` to `0.31.0`.

### Why

The hook reads the file with `grep '^- ' docs/accomplishments.md | head -5` because the file format guarantees one item per line, newest first -- all parsing lives in the format contract, not the script.

### What I learned

Renaming the hook variable from `AGENTS_CONTENT` to `CONTEXT` initially dropped the comment explaining the `jq -Rs` idiom; restored it at the call site where it belongs.

### What didn't work

Nothing failed; the hook test passed on the first run.

### What was tricky

Automated skill evals were a poor fit here: the flow has Markus in the loop mid-run (the appreciation step), which a subagent cannot simulate. The plan is a live first run on fabrik's own diary instead, once merged.

### What warrants review

- `/hooks/scripts/session-start.sh`: verify the no-file path is unchanged and the JSON stays valid (tested with `jq` on both paths, including that a sixth item is excluded).
- `/skills/accomplishments/SKILL.md`: the flow steps should match the brainstormed design exactly -- boundary date, `>=` re-read, my selection, Markus's appreciation, my wording.

### Future work

Run `/accomplishments` on fabrik's own diary as the first live test; this very entry is a candidate.
