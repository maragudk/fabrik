---
name: second-opinion
description: Get a second opinion from another AI model (currently OpenAI models, via the codex CLI) on a design decision, a stubborn bug, a code review, or any question where an independent take is valuable. Use only when the user explicitly asks for one -- "get a second opinion", "ask OpenAI", "ask codex", "what does GPT think", "/second-opinion", or similar. Do not use proactively.
license: MIT
---

# Second opinion

Consult an OpenAI model through the `codex` CLI and relay what it says. The value of a second opinion is independence: let the other model reach its own conclusion, verify what it claims, then report it faithfully -- especially where it disagrees with you.

## Preflight

Check auth once per session: `codex login status` should print `Logged in using ChatGPT` (or the API-key equivalent). Anything else: stop and ask the user to authenticate -- suggest they type `! codex login` (ChatGPT account, usage billed to their plan) or use `codex login --api-key <key>`.

If any codex command hangs -- even `codex --version` -- the installed binary does not work under Claude Code's Bash sandbox. Rerun with sandboxing disabled (`dangerouslyDisableSandbox: true`); that is safe combined with `-s read-only` below, which makes codex sandbox its own work. The Homebrew build has this problem; the standalone install (`codex update`) does not. Don't disable the sandbox preemptively -- only on a hang.

## Core command

Set up a working directory, write the prompt to a file (avoids shell-quoting pain and keeps a record of what was asked), then run codex in the background:

```sh
DIR=<your scratchpad>/second-opinion
mkdir -p "$DIR"
# write $DIR/prompt.md, then, as a background Bash call:
codex exec -C <repo root> -s read-only -o "$DIR/answer.md" - < "$DIR/prompt.md" > "$DIR/codex.log" 2>&1
```

- `codex exec` is non-interactive mode; `-` reads the prompt from stdin.
- `-C <dir>` pins codex's working root. Pass it always: your own working directory resets between Bash calls, so "run it from the repo root" is not something to rely on. Add `--skip-git-repo-check` if the target isn't a git repository.
- `-s read-only` lets codex read the workspace and run read-only commands to explore on its own, but never write. It also blocks network access -- so paste into the prompt anything codex cannot discover locally: `gh` output, release data, error logs, conversation context, external docs.
- `-o` writes only the model's final answer to `answer.md`. Read that file for the opinion.
- `codex.log` gets the event stream: a header (model, effort, session id), every command codex ran, and the full text of every file it read -- often 50-300 KB. Never cat it into context; `head -15` for the header, `tail -3` for the token count, and leave the rest on disk.
- Attach screenshots or diagrams with `-i <file>` if the question is visual.

**Expect minutes, not seconds** -- several minutes at default effort, longer at high effort on big questions. Run the codex call as a background Bash task, then wait on the answer file itself (e.g. a bounded `until [ -s "$DIR/answer.md" ]; do sleep 15; done` loop, backgrounded or via Monitor). Don't poll with `pgrep codex` -- other agents may be running codex too.

## Writing the prompt

State the question, the constraints that matter, and what shape of answer you want (a verdict with reasoning, alternatives considered, risks). Point codex at file paths and let it read them itself -- that is what `-s read-only` buys you, and its own digging through the code and git history is where the best findings come from. Ask it to verify stated premises against the repo rather than accept them; your framing may itself be wrong, and a good second opinion catches that.

Pick one of two modes, depending on what the second opinion is for:

- **Blind** -- for open questions and design forks. Do not reveal the conclusion you or the user currently favor; ask the open question, get an independent take, compare afterwards. An opinion that has seen your answer is anchored by it. When the user's question *is* their proposal ("should we do X?"), don't name X: describe the problem neutrally and require alternatives -- "list the options you considered and rejected, including changing nothing" -- so their option gets evaluated without being flagged as the favorite.
- **Adversarial** -- for validating a decision already made. Show the conclusion, diff, or design and ask the model to attack it: find the flaw, argue the other side, name what would make it fail.

In both modes, do not lead the witness. "We think X is right -- do you agree?" produces agreement, not an opinion.

## Model and effort

Pass no model or effort flags by default: codex then uses the user's `~/.codex/config.toml` (their configured preference) or its built-in default, which tracks OpenAI's current best -- as of mid-2026, `gpt-5.6-sol` at `xhigh` effort, the right weight for "hard problem, strongest independent take". The header in `codex.log` confirms what actually ran.

To dial down for a quick, cheap opinion:

```sh
codex exec -m gpt-5.6-terra -c model_reasoning_effort="medium" ...
```

- Models (mid-2026): `gpt-5.6-sol` (flagship), `gpt-5.6-terra` (balanced), `gpt-5.6-luna` (fast/volume).
- Effort levels: `low`, `medium`, `high`, `xhigh`, plus Sol-only `max` (deeper single-track reasoning) and `ultra` (parallel internal subagents) for genuinely gnarly problems -- both slow and allowance-hungry.
- codex does not validate these values client-side; a typo silently degrades the run rather than erroring. Check the header line.

## Verify before relaying

A second opinion arrives with the same confidence whether it is right or wrong, and both directions occur in practice: the other model may correct a premise you fed it (and be right), or fabricate a supporting fact (a plausible misreading of git history, an invented API behavior) inside an otherwise sound argument. Faithfully relaying a false claim is still a false claim.

So before relaying, check the load-bearing factual claims -- the empirical assertions the opinion stands on: git-history claims (`git log`, `git tag`, `git diff` them), tool and API mechanics (check the docs), numbers and measurements (recompute them). Skip claims that are pure judgment; verify the ones the judgment rests on. Report what you checked and what held -- a verified disagreement is worth far more than an unverified one.

## Follow-ups

The session id is printed in the `codex.log` header. Continue the conversation with:

```sh
codex exec resume <session-id> "follow-up question"
```

This keeps the model's context, so use it when the user reacts to the opinion ("ask it about X too", "tell it we can't do that because Y"). Add `--ephemeral` to the original command only for one-shots you will never resume; it prevents the session from being saved.

## Code review second opinions

For "second opinion on this diff/branch/commit", prefer `codex exec review` over a hand-rolled prompt. It is a dedicated review mode with a strict reviewer prompt -- only definite bugs introduced by the change, pre-existing problems excluded, "prefer no findings" over speculation -- and it is read-only by construction.

```sh
codex exec review --base main -o "$DIR/review.md" </dev/null > "$DIR/review.log" 2>&1
```

- Scope is exactly one of: `--uncommitted` (staged + unstaged + untracked), `--base <branch>`, `--commit <sha>`, or a custom prompt. A custom prompt cannot be combined with a git scope -- for a focused review ("check only the error paths"), capture the diff to a file yourself and use plain `codex exec`.
- It reviews the process working directory (no `-C`), so `cd` as part of the same command.
- A completed review exits 0 whether or not it found problems; empty output means failure, not a clean review. The verdict is in the output. Add `--json` if you want the structured findings events instead of prose.
- Review findings are opinions too: verify before acting on them.

## Direct or subagent?

Judgment call, not a rule:

- **Direct (the usual case)**: one opinion, and the question plus its context are already in your conversation. Run codex via Bash, read the answer file, relay it.
- **Subagent**: fanning out -- several opinions in parallel (different models, efforts, or blind vs adversarial framings) -- or when assembling the prompt requires heavy repo exploration that would drown your context. Give each subagent the prompt file path and have it return the opinion verbatim, not a summary; a paraphrased second opinion is a game of telephone.

## Relaying the opinion

Report what the model actually said. Attribute it (model and effort), quote the key passages, note what you verified, and put disagreements with your own view front and center -- an inconvenient second opinion is the whole point of asking. Do not blend the two views into consensus mush; where you still disagree after reading it, say so and say why.
