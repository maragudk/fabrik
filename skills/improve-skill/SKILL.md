---
name: improve-skill
description: Review the current conversation for fabrik skills that could be improved (corrections, friction the user had to manually flag, missed triggers, anything else worth flagging) and ship the improvements back to the fabrik repo as a PR (concrete fixes) or issue (fuzzy observations / redesigns). Use when the user invokes /improve-skill or asks to make a skill better, smarter, or less friction-prone. May also be suggested at end of session if there's concrete signal that a skill underperformed; otherwise stay silent.
license: MIT
---

# Improve skill

A skill for incrementally improving other fabrik skills based on what just happened in the current conversation. The premise: every real session is a free user study. If a skill underperformed -- gave incomplete advice, missed something the user had to ask for manually, didn't trigger when it should have -- that's signal worth turning into a concrete improvement to the skill.

This skill harvests that signal and ships it back to `maragudk/fabrik` as a PR (when the fix is clear) or an issue (when the observation is real but the fix isn't).

## When to use

**Primarily user-invoked.** The user runs `/improve-skill` or says things like "make the X skill better", "the brainstorm skill should ask fewer questions", "this skill missed something". They may also bring their own idea about what to fix; that idea joins the findings list rather than replacing it.

**Proactively suggest at end-of-session moments only when there's concrete signal.** Examples of concrete signal:

- The user corrected output that came from a skill's guidance
- The user asked manually for something the invoked skill should have done unprompted
- The assistant supplemented with knowledge that's literally another skill's job (a missed trigger)
- An invoked skill produced something out of date, contradicted another skill, or confused the assistant

No signal, no suggestion. Be quiet by default. The bar is the same as the `decisions` skill: only speak up when there's something specific to point at.

## When not to use

- **Writing a new skill from scratch** -- that's `skill-creator`, not this.
- **Fixing code bugs in user projects** -- those are normal edits.
- **General codebase tidying in fabrik** -- that's `garden`.

This skill only edits `skills/*/SKILL.md` and the subfiles those skills reference.

## Step 1: Gather signals from the conversation

Read back over the current conversation. The candidate set is *any fabrik skill the conversation gives signal about*, whether it was invoked or not. A skill ends up on the list one of two ways:

- **It was invoked**, and something was off.
- **It should have been invoked but wasn't**, inferred from the assistant supplementing with knowledge that's literally another skill's job.

For each candidate skill, look for these signal types:

1. **Corrections.** Places where the user pushed back on output that came from the skill's guidance ("no", "stop", "not like that"), or where the assistant changed approach mid-task because of feedback.
2. **Manual asks the skill should have covered.** Moments where the user explicitly requested something within the skill's stated scope but the skill didn't do it unprompted. These are friction-reduction wins -- if the skill had simply done the thing, the user wouldn't have had to interrupt.
3. **Missed triggers.** A skill that obviously should have fired didn't, inferred from the assistant supplementing with knowledge already documented in another skill.
4. **Anything else worth flagging.** The above aren't exhaustive. Outdated examples, confusing phrasing, contradictions with another skill, missing cross-references, stale tool names -- if it would clearly improve the skill, flag it. Don't omit a real observation because it doesn't fit a category.

Why all of these matter: skills get better over time only if friction translates into edits. The model is the witness to its own confusion and the user's corrections; this skill is the mechanism for turning that into a diff.

## Step 2: Present findings to the user

Summarise each finding as a one-line entry:

```
[skill-name]: [what was observed in the conversation] -> [proposed change type: trigger / content / structure / redesign]
```

Show the full list to the user, ask which to act on, and accept any extras the user wants to add. If the user invoked with a specific idea, fold it into the same list as another finding -- don't drop the conversation-derived ones in favour of the user's idea.

If after the pass there are no findings, say so plainly and stop. Don't manufacture work.

## Step 3: Classify each accepted finding

Classify each finding the user wants to act on as one of:

- **Concrete fix** -- the right change is clear (description tweak, added example, rule clarification, missing cross-reference, fixing a stale fact). Goes into a PR.
- **Fuzzy / redesign** -- the signal is real but the right fix isn't obvious, or the change is structural enough to deserve discussion before code ("split this skill in two", "the trigger model is wrong"). Discuss in chat first; if the discussion converges on a concrete change, ship as a PR; if it doesn't, file an issue so the thinking isn't lost. Don't default to "issue" just because the finding started fuzzy.

A single invocation may produce one PR (covering several concrete fixes across one or more skills) plus one or more issues (for the genuinely unresolved ones). That's fine.

## Step 4: Prepare a working copy of fabrik

The skill almost always runs outside the fabrik repo. To edit `skills/*/SKILL.md`, you need a working copy. Lookup order:

1. **`~/Developer/fabrik`** -- if it exists, prefer it.
   - **Do not edit the user's main checkout directly.** They may have in-progress work there.
   - Create a git worktree off it:
     ```bash
     git -C ~/Developer/fabrik worktree add ../fabrik-improve-skill-<slug> -b improve-skill/<slug>
     ```
   - Do all edits in the worktree, push from the worktree, open the PR from the worktree.
2. **Otherwise**, clone `maragudk/fabrik` to a temp directory, branch, edit there, push, open the PR. Report the path back to the user so follow-ups are easy.

The branch name is `improve-skill/<slug>` where `<slug>` is a short kebab-case description of the change (e.g. `improve-skill/brainstorm-one-question`). By default, one PR per `improve-skill` invocation, even when several skills are touched -- keeps review batched. But if the user wants to act on findings one at a time (e.g. "let's take those one at a time"), a PR per finding is fine; follow the user's preference.

**Before editing, Read `AGENTS.md` at the repo root** and follow whatever conventions it specifies (README updates, version bumping, etc.). `CLAUDE.md` is a symlink to `AGENTS.md`. The harness loaded the *user's current project's* AGENTS.md/CLAUDE.md at session start, not fabrik's, so cd-ing into the worktree doesn't auto-load fabrik's rules -- read it explicitly.

## Step 5: Draft PR and issue bodies

Draft the commit message and the PR / issue body. Don't pause to ask the user "here's the body, approve?" -- the gate was already passed in Step 2, when they said yes to acting on the finding. A second approval round on the prose just slows the loop down. Write a reasonable body, push, and open. Only check in mid-step if you hit something genuinely uncertain (scope changed, framing is unclear) -- not for routine prose.

**PR body** structure:

```markdown
## What was observed

<short summary of the friction or gap, drawn from the current conversation>

## What changed

<per-skill bullet of the actual edits, e.g. "brainstorm: added explicit one-question-per-message rule to opening line">

## Why

<the reasoning, so a future reader can judge whether the change still makes sense>
```

Apply any conventions from `AGENTS.md` to the PR (for example, README entries, version-bump reminders) so the PR is mergeable as-is, not a half-finished draft.

**Issue body** structure:

```markdown
## What was observed

<short summary of the friction, drawn from the current conversation>

## Why this is worth discussing

<why it's not a straightforward fix -- structural, ambiguous, or contested>

## Partial ideas

<anything the user or assistant floated, even if half-baked>
```

One issue per fuzzy / redesign finding. Title clearly: `improve-skill: <skill-name> <one-line summary>`.

## Step 6: Push and open

Once approved:

- Commit the edits in the worktree / clone with a clear message.
- Push the branch.
- `gh pr create` for the PR (if any).
- `gh issue create` for each issue (if any).
- Report all URLs back to the user.

That's the run. The skill stops once URLs are reported. Follow-up review feedback, version bumps, and merging are the user's call.

## Notes on tone

- Be specific. "The brainstorm skill could ask one question at a time" is useless without pointing at where in the conversation that mattered. Cite the moment.
- Generalise from the example. The PR is one diff that will affect every future invocation of the skill -- write it for that universe, not just this conversation.
- Keep edits surgical. If a finding is "the example is stale", change the example; don't rewrite the section. Big rewrites belong in an issue first.
- Don't pad. If there's one finding, the PR has one bullet under "What changed". That's fine.
