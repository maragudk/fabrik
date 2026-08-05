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

## Step 3: Subagent testing and refinements

**Author:** main

### Prompt Context

**Verbatim prompt:** Test the skill with subagents maybe?
**Interpretation:** Validate the skill with subagent test runs before considering it done; a follow-up ("Improve the skill as needed") delegated judgment on refinements.
**Inferred intent:** Confidence the skill behaves correctly before merge, without Markus needing to review a browser-based eval viewer.

### What I did

Built three fixture projects (fresh extraction, incremental update with a same-date sibling and a pre-boundary entry, idempotent no-op) and ran each with the skill and as a skill-less baseline -- six subagents, scripted assertions. The appreciation step used canned notes since Markus can't be in a subagent's loop. Results: skill 16/16 assertions, baseline 12/16. Applied two refinements from reading the outputs: a ~40-word length target for items (iteration-1 items sprawled to 50-60 words; a rerun landed at 39-41) and a final flow step showing Markus the finished lines.

### Why

The baseline failures were the design earning its keep: without the skill, the fresh run invented a prose format in which `grep '^- '` finds zero items (the hook would silently inject nothing), and the incremental run added an entry from before the boundary.

### What worked

Scripted grading over a strict file format -- every assertion was a few lines of Python. The `>=` boundary logic passed its hardest case (same-date sibling added, already-listed item not duplicated) on the first run.

### What didn't work

The skill-creator aggregation script expected `eval-N/<config>/run-1/grading.json` and a `summary` block in grading.json; my first layout produced a 0% benchmark twice before matching it. The eval viewer also needs Python 3.10+ (`dict | None` syntax fails on the system 3.9; used Homebrew 3.14), and was moot anyway -- no browser on this machine.

### What I learned

Idle notifications from subagents carry no token/duration metrics, so benchmark Time/Tokens rows stayed zero; only pass rates are real.

### What was tricky

Testing an interactive skill non-interactively: canned appreciation notes cover the mechanics but not the conversational step, which remains untested until the first live `/accomplishments` run.

### What warrants review

The two skill edits: the length guidance ("around 40 words is plenty") and the added "show Markus the finished lines" step.

### Future work

First live run on fabrik's own diary after merge.

## Step 4: Harvest appreciation already in the diary

**Author:** main

### Prompt Context

**Verbatim prompt:** One last thing: the diary has some verbatim prompts, and I sometimes praise your work while we're working together. Should we use those in the skill if present?
**Interpretation:** The skill should mine appreciation that is already recorded in diary entries -- praise inside verbatim prompts or captured reactions -- when extracting accomplishments.
**Inferred intent:** Spontaneous in-the-moment praise is more authentic than appreciation reconstructed weeks later, and the diary already preserves it for free.

### What I did

Extended flow step 4 in `/skills/accomplishments/SKILL.md`: found appreciation seeds the conversation ("at the time, you said...") rather than replacing it, and quick courtesies like "great work" don't count -- only praise that names something.

### Why

Praise in a verbatim prompt is uninvited, specific, and word-for-word from the moment -- better-sourced than solicited appreciation. But the live exchange stays, because the ritual is half the point.

### What worked

The diary skill's verbatim-prompt rule turns out to double as an appreciation archive; nobody designed it for that.

### What didn't work

Nothing; a two-sentence skill edit.

### What was tricky

Keeping the guardrails tight enough that the found praise supplements the conversation instead of quietly becoming a reason to skip it.

### What warrants review

The step 4 wording in `/skills/accomplishments/SKILL.md`.

### Future work

None beyond the existing plan: first live run after merge.

## Step 5: First live run

**Author:** main

### Prompt Context

**Verbatim prompt:** /fabrik:accomplishments
**Interpretation:** Run the just-released skill for real on fabrik's own diary -- the first run with Markus actually in the appreciation loop.
**Inferred intent:** Close the loop the whole session built toward: fifteen diary entries in, a recognition file out.

### What I did

Read all fifteen diary entries (146KB, read in chunks via the persisted output file), picked seven accomplishments and passed over five entries, presented picks and passes with reasoning, and heard Markus's appreciation. His input changed the selection: the git log filled diary gaps (many skills shipped undiaried), and the lead/builder workflow -- which I had passed over as "superseded" -- turned out to be his daily workhorse. Final file: eight items, including one sourced from the git log arc (lead/builder, dated 2026-04-08) and the bootstrap item carrying the diary skill by name.

### Why

The skill says selection is mine and appreciation is his; both mattered. My judgment missed what only he could know -- which work he actually leans on daily.

### What worked

The conversation step earned its place immediately: three items got materially better lines from his comments ("the distillation outran the reading" exists because he mentioned still reading the book), and one wrong pass got reversed.

### What didn't work

The diary alone was an incomplete record -- whole arcs (lead/builder evolution, undiaried skills like atproto and garden) live only in the git log. The skill assumes the diary is the source of record; the first real run needed `git log` as a supplement, at Markus's prompting.

### What I learned

Appreciation genuinely reshapes selection, not just wording. Also: the diary underrepresents exactly the work that matters most -- the daily-use infrastructure nobody writes an entry about.

### What was tricky

Judging "superseded" versus "foundational" from the diary alone. The PO/QA agents looked like dead ends on paper; the workflow they grew into is the thing Markus values most.

### What warrants review

/docs/accomplishments.md -- eight items, one line each, newest first, dates matching source diary entries (or the git log arc for lead/builder).

### Future work

Consider noting in the skill that the git log can supplement the diary when entries are sparse -- a candidate for the next /improve-skill run.

## Step 6: Fold the git log supplement into the skill

**Author:** main

### Prompt Context

**Verbatim prompt:** Merge 91 and fix the skill now to include the git log supplement?
**Interpretation:** Merge the first live run's PR, then act on its Step 5 finding immediately: teach the skill that the git log supplements the diary.
**Inferred intent:** Close the improvement loop in the same session it surfaced, rather than deferring to a future /improve-skill run.

### What I did

Merged PR #91. Then edited `/skills/accomplishments/SKILL.md`: flow step 2 now says the diary is the primary but incomplete record and to skim `git log` over the same date range for significant undiaried work, and the date-prefix rule covers git-log-sourced items (date the work started per the log). Bumped `/.claude-plugin/plugin.json` to 0.31.1 (patch, change to existing functionality).

### Why

The first live run's most-valued item (the lead/builder workflow) existed only in the git log. A skill that assumes diary completeness would keep missing exactly that kind of work.

### What worked

Same-session feedback loop: finding surfaced at 09:00, folded into the skill before the session ended.

### What didn't work

Nothing; two-sentence edit plus a bump.

### What was tricky

Keeping the supplement subordinate -- the diary stays the primary record, the log is a sweep for gaps, not a second source of equal rank.

### What warrants review

The step 2 addition in `/skills/accomplishments/SKILL.md` -- check the git log guidance reads as a supplement, not a rewrite of the flow.

### Future work

None; the loop from Step 5 is closed.

## Step 7: Ship v0.31.0 (recorded out of order)

**Author:** main

### Prompt Context

**Verbatim prompt:** Merge the PR and do the version bump and release
**Interpretation:** Merge PR #90, tag `v0.31.0` on the merge commit, and publish the GitHub release. This happened between Steps 4 and 5 but went unrecorded until now.
**Inferred intent:** Make the skill and hook reachable by remote installs, then run the skill live.

### What I did

Refreshed PR #90's body to match what actually shipped (the test round and appreciation-harvesting had landed after it was written), merged with a merge commit and deleted the branch, tagged `v0.31.0` on the merge commit, pushed the tag, and published the release. Later in the session: merged PR #91 (the first live run's output) and opened PR #92 (git log supplement, 0.31.1) -- covered in Steps 5 and 6.

### Why

Refreshing the PR body before merge follows the git skill: a branch drifts as feedback lands, leaving the body written for the first commit stale.

### What worked

The whole ship was one command sequence with no retries: edit body, merge, pull, tag, release.

### What didn't work

Nothing in the ship itself. The process miss was this diary step -- the shipping went unrecorded until Markus asked "anything for the diary before that?", despite the repo having a precedent commit for exactly this ("Add diary step for shipping the PR and version bump", from the turbopuffer work).

### What I learned

The diary skill's session-end trigger fires on "a work chunk wraps up" -- a release is such a moment, and I logged the work around it but not the ship. The gap is ironic given this very session established that undiaried work is what the accomplishments skill misses.

### What was tricky

Nothing technically; only noticing the omission.

### What warrants review

Release https://github.com/maragudk/fabrik/releases/tag/v0.31.0 -- notes should match the merged content of PR #90.

### Future work

After PR #92 merges: tag `v0.31.1` and publish its release.
