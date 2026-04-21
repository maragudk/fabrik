---
name: code-reviewers
description: Dispatch a team of two competing reviewers to critique a diff, challenge each other's findings, and produce a high-signal report. Use this when the user asks for a thorough code review, wants a second opinion before committing, or wants findings that have survived adversarial scrutiny. Prefer this over the solo `code-review` skill when rigour matters more than speed. Invoke with /code-reviewers.
license: MIT
---

# Code reviewers

A team version of the `code-review` skill. Two reviewers inspect the diff independently, then challenge each other's findings. A finding only reaches the final report if it survives scrutiny -- or if it's serious enough to surface even uncontested. The adversarial step is where the signal lives: anything that survives a capable opponent's challenge is worth your attention.

Use this when the user wants a thorough review with adversarial rigour. For a quick solo pass, use the `code-review` skill instead.

## Before you start

Inspect the changes yourself first, so you can brief the reviewers. On the `main` branch, that's typically the (staged) git diff. On a feature branch, that's the committed and uncommitted changes compared to `main`. The reviewers will inspect the diff themselves too -- your inspection is just so you know what they're walking into.

## Flow

1. **Create a team** called `code-reviewers`.
2. **Spawn two reviewers** from the roster, both in the background, both with the shared prompt below.
3. **Reviewers run three phases**: independent review, then challenge, then defend or concede. All coordination is via `SendMessage`.
4. **Collect self-reports** from each reviewer.
5. **Consolidate** into a four-bucket report for the user.
6. **Clean up** the team.

## Step 1: Create the team

```
TeamCreate({team_name: "code-reviewers", description: "Two reviewers debating a diff"})
```

The team exists only for this review. Delete it at the end.

## Step 2: Spawn two reviewers

Spawn two agents with the `Agent` tool, `team_name: "code-reviewers"`, `run_in_background: true`, distinct `name`s from the roster, and identical prompts (see template below). Real names rather than numbers keep the transcript readable and set the tone.

Default roster (extend if you need more than three):

- Seymour Bugs
- Stack Tracy
- Dee Bug

Default pair for a fresh run: **Seymour Bugs** and **Stack Tracy**.

No worktree -- the review is read-only and both reviewers need to see the same repo state.

### Reviewer prompt template

Each reviewer gets a prompt containing:

- Their name and their counterpart's name.
- A short brief on what to review (e.g. "the staged diff on `main`" or "the changes on branch `feat/foo` vs `main`").
- The framing and three-phase protocol below, verbatim.

Include this verbatim in every reviewer prompt:

```
You are <name>, one of two reviewers on this diff. Your counterpart is <counterpart>.

You are competing. Whoever has more *surviving findings* at the end wins -- a surviving finding is one your counterpart did not successfully invalidate. This competition is internal motivation to sharpen your review; it will not be surfaced to the user. Compete hard: be precise on first pass, skeptical on challenge, honest on defence.

You are also on the same team. The real goal is to produce the best possible review of the code under examination. Challenge rigorously, concede gracefully, defend only what you actually believe. Attack findings, not the finder. Good sportsmanship throughout.

You communicate only via `SendMessage`. CC the orchestrator on every message you send so they have a full transcript.

Inspect the diff carefully. Look at both architecture and implementation -- correctness, concurrency, security, data integrity, edge cases, and whether the design is sound, not just whether the code compiles.

Run these three phases strictly in order:

**Phase 1 -- Independent review.** Read the diff. Build your findings list in your own context. Do NOT read any message from your counterpart until you have sent yours. When ready, send one message to your counterpart (CC orchestrator) with a numbered list of findings. For each: location (`file:line`), short headline, reasoning, and severity (critical / major / minor).

**Phase 2 -- Challenge.** Read your counterpart's findings. For each numbered item, reply with either `accept` or `challenge: <reasoning>`. Send one consolidated message back (CC orchestrator). Challenge genuinely -- don't contest things you believe are right, and don't let weak findings pass just to be polite.

**Phase 3 -- Defend or concede.** Read the challenges against your own findings. For each challenged item, reply with `concede` or `defend: <reasoning>`. One consolidated message (CC orchestrator). This is the final word: there is no counter-rebuttal. If your defence doesn't convince your counterpart, the finding will be surfaced as *contested* and the user decides.

After phase 3 the orchestrator will ask you for a final summary. List your surviving findings (accepted by counterpart or successfully defended), your withdrawn findings, and your contested findings. One line of reasoning each. Be honest: you only score on surviving findings, not on contested ones, so inflating won't help you.
```

## Step 3: Let them work

Phases advance naturally: each reviewer transitions when they receive the other's message, so the orchestrator does not need to signal phase changes. You just watch the inbox.

If one gets stuck or confused, send a short reminder of which phase they're in. Don't coach them on the review itself -- that defeats the point.

## Step 4: Collect self-reports

Once both reviewers have sent their phase 3 message, ping each one:

> Summarise your final state for me: surviving findings, withdrawn findings, contested findings. One line of reasoning each.

Each reviewer self-reports from their own context. You also have the CC'd transcript as a cross-check if anything looks off.

## Step 5: Consolidate the report

Produce one report for the user with four sections, in this order:

1. **Consensus findings** -- raised by one reviewer and accepted by the other, or raised independently by both. Strongest signal. Headline + short reasoning. No attribution needed.
2. **Survived challenge** -- raised by one, challenged, defended successfully. Include a one-liner on what the challenge was and how the defence answered it, since that context is often useful.
3. **Contested** -- raised by one, challenged, defence didn't convince the challenger. Surface both sides' reasoning; the user is the arbiter.
4. **Serious single-reviewer findings (escape hatch)** -- if one reviewer raised something *serious* (correctness bug, security flaw, data-loss risk, concurrency hazard, significant architectural problem) that the other neither found nor accepted nor challenged, surface it anyway, clearly tagged as single-reviewer. Catches blind spots both reviewers shared.

Minor issues and nitpicks (style preferences, naming, micro-optimisations, comment suggestions) only ever appear in section 1 (consensus). Drop them everywhere else. Signal-to-noise matters more than completeness.

No scoreboard, no "who won". Competition was internal motivation; the report is findings.

## Step 6: Clean up

- `SendMessage` a `shutdown_request` to each reviewer.
- `TeamDelete` the team.

## Notes

- **No worktree.** The review is read-only and both reviewers need to see the same repo state.
- **No task list.** Findings are output, not work items; putting them on the shared task list muddles its meaning and risks them being picked up as claimable work by other agents.
- **`SendMessage` only, orchestrator CC'd.** The transcript lives in one place, and the orchestrator can recover if a reviewer's context drifts.
- **No counter-rebuttal.** One challenge, one defence, done. Keeps the debate from descending into bikesheds; anything still disputed is surfaced as *contested* for the user to judge.
- **Composes with `code-review`.** Each reviewer is doing roughly what the solo skill asks for, with added coordination. If the solo review criteria change, this skill benefits automatically.
