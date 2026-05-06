---
name: diary
description: Write and maintain an implementation diary capturing what changed, why, what worked, what failed (with exact errors and commands), what was tricky, and how to review and validate. Activates proactively during non-trivial implementation work (new features, bug fixes, refactors, research spikes) and at natural session-end moments -- after a PR merges, a feature ships, or a work chunk wraps up -- to capture the narrative while it's still fresh. Does not activate for trivial tasks like one-line fixes, config tweaks, or quick questions.
license: MIT
---

# Diary

An implementation diary captures the narrative of your work: what you did, why, what worked, what broke, what was tricky, and what needs review. The concept of "diary" activates existing behavioral patterns without requiring much engineering -- the model already knows what a diary is.

## Working Loop

Follow this cycle for each meaningful unit of progress:

1. **Implement** -- make the code change
2. **Update diary** -- add or update the current step in the diary file
3. **Commit together (when asked)** -- when the user asks for a commit, include the diary file alongside the code it documents. Invoking this skill is **not** itself a commit request -- wait for the user to ask before running `git commit`.

A "step" is a logical chunk of work, not necessarily a single commit. Examples: "wire up the API endpoint", "debug the flaky test", "research how the auth middleware works".

## File Location

Diary files live at `docs/diary/YYYY-MM-DD-<slug>.md` relative to the project root.

- The date is when work on the task started
- The slug is free-form: a feature name, ticket reference, or whatever describes the task
- One file per task or feature -- if work spans multiple days, steps accumulate in the same file
- Create the `docs/diary/` directory if it doesn't exist

Examples:
- `docs/diary/2026-03-25-add-diary-skill.md`
- `docs/diary/2026-03-20-fix-auth-race-condition.md`
- `docs/diary/2026-03-18-PROJ-123.md`

## Diary File Structure

```markdown
# Diary: <task description>

Brief description of the goal and context for this task.

## Step 1: <short description>

**Author:** <agent name -- "main" if written by the main agent, otherwise the sub-agent name>

### Prompt Context

**Verbatim prompt:** <the exact user prompt that initiated this step>
**Interpretation:** <what the assistant understood from the prompt>
**Inferred intent:** <the underlying goal behind the prompt>

### What I did
<factual description of actions taken, files touched, commands run>

### Why
<connects the actions to the goal>

### What worked
<positive signals worth replicating>

### What didn't work
<failures recorded immediately with verbatim errors and commands>

### What I learned
<tacit knowledge that isn't obvious from the code>

### What was tricky
<friction points, hidden complexity, sharp edges>

### What warrants review
<tells a reviewer where to look and how to validate>

### Future work
<implied follow-ups that naturally fell out of the work, not a wishlist>

## Step 2: <short description>

...
```

## Writing Rules

- **Prose-first.** The diary is a narrative, not a log dump. Technical details (paths, hashes, error messages) are included inline but wrapped in readable prose.
- **All sections, every step.** Never skip a section. If "What didn't work" is genuinely empty because everything went smoothly, say that explicitly.
- **Failures are gold.** Record them immediately with verbatim error messages and the exact commands that produced them. These are the most valuable parts of the diary.
- **Absolute paths from project root.** All file paths referenced in the diary are absolute relative to the project root (e.g., `/src/handler.go`).
- **Prompt Context is verbatim.** Copy the user's prompt exactly as given. Don't paraphrase the verbatim section.
- **Identify authorship.** Put a `**Author:**` line right under each step heading you write so it's obvious who wrote it -- your sub-agent name if you're a named sub-agent, or `main` if you're the main agent.
- **Don't modify old diary entries.** Only edit a diary file if it was created in the current session. Subsequent work should create a new diary file rather than revising earlier entries -- diaries are a historical narrative, not a living document.

## When to Activate

This skill activates proactively during non-trivial implementation work:
- New features
- Bug fixes
- Refactors
- Research spikes

Do **not** activate for:
- One-line fixes
- Config tweaks
- Quick questions about the codebase
- Trivial changes that don't warrant narration
