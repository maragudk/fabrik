# Diary: Add `second-opinion` skill

Add a skill for consulting an OpenAI model through the codex CLI when the user explicitly asks for a second opinion. The skill covers the non-interactive `codex exec` flow, blind vs adversarial prompting, model/effort selection, follow-ups via session resume, `codex exec review` for diffs, and -- the finding the whole test campaign converged on -- verifying the other model's factual claims before relaying them.

## Step 1: Design decisions via brainstorm, then a pivot

**Author:** main

### Prompt Context

**Verbatim prompt:** I'd like to create a new skill called second-opinion. It should be used when you want to call another AI model (let's start with from OpenAI). We'll use the codex CLI. The skill should detail how to prompt the model through the CLI, how to select a model, an effort level, and whatever else is needed. I'm not sure whether the skill should always be run in a subagent itself to handle the communication?
**Interpretation:** New fabrik skill wrapping the codex CLI for second opinions, with an open design question about subagent execution.
**Inferred intent:** Make "ask another model" a first-class, repeatable move with the operational details (flags, auth, waiting, relaying) already solved.

### What I did

Started with the brainstorm skill per standing instruction. Three decisions landed before Markus cut the interview short ("We don't need to go through the design, use your skill-creator skill to write the skill and test it with a few subagents or something"):

- Execution: the calling agent judges direct-via-Bash vs subagent per context; the skill documents criteria for both. (Markus picked this over my "direct by default" recommendation.)
- Triggering: explicit requests only, never proactive.
- Model/effort: pass no flags; inherit codex's default rather than pinning names.

Probed the CLI before asking questions: `codex exec --help`, `codex login status`, a smoke test, and an invalid-model probe (error does not enumerate valid models). Established: `-o` writes just the final answer, `-s read-only` sandboxes codex's own work, `codex exec resume <session-id>` does follow-ups, invalid `model_reasoning_effort` values pass through unvalidated.

### What didn't work

- `codex --version` hung forever under the Bash sandbox -- moved to background at 120s, killed, retried with `dangerouslyDisableSandbox: true`, worked. Looked like a hard fact about codex; Step 3 revealed it was only a fact about the Homebrew build.
- `codex login status` initially reported "Not logged in"; Markus authenticated mid-session, which also replaced the binary (Homebrew `/opt/homebrew/bin/codex` gone, standalone `~/.local/bin/codex` symlink appeared) and created `~/.codex/config.toml` pinning `gpt-5.6-sol` / `xhigh`. The environment changing under the session caused two later contradictions worth re-verifying rather than trusting either observation.

## Step 2: Write the skill, test with five parallel subagents

**Author:** main

### What I did

Wrote the first draft (~100 lines, single SKILL.md), then launched five subagents in one message: three with-skill runs (blind design fork on README generation, adversarial attack on the versioning policy, code question on the hooks setup), one no-skill baseline on the adversarial prompt, and one investigator for `codex exec review` (Markus's mid-turn addition). Each with-skill agent saved prompt, answer, log, and a run report to the session scratchpad.

### What worked

- All three with-skill runs completed cleanly: 4-9 minutes each at `gpt-5.6-sol`/`xhigh`, ~97k tokens on the biggest. The `-o answer.md` pattern kept 50-300 KB event streams out of agent context.
- `-s read-only` letting codex explore the repo itself produced the standout moment: in the blind run, codex refused the stated premise ("README has drifted"), checked git history, and proved the premise wrong -- the "drift" was this very skill, uncommitted. The tester verified codex's counter-evidence and it held.
- The `codex exec review` investigation (binary string extraction plus live runs) established: dedicated review mode, strict anti-false-positive reviewer prompt, read-only by construction, exactly one scope selector (`--uncommitted`/`--base`/`--commit`/custom prompt, mutually exclusive), exit 0 regardless of findings, empty stdout means failure.

### What didn't work

- The adversarial run caught codex fabricating a supporting claim: a "duplicate 0.28.1 bump" that was an artifact of misreading `git log -S` (which matches both the commit adding and the commit removing a string). One false claim out of six, inside its top finding.
- The baseline agent misread its own histogram (`tail -5` of a sorted list read as the maximum) and briefly accused codex of fabricating a true number. Verification cut both ways all day.
- Two testers burned turns improvising wait loops for the backgrounded codex call; one loop used `pgrep -f "codex exec"` which matched a different agent's codex process. Another hit zsh's read-only `status` variable and nearly reported a false failure.

## Step 3: Revise from converged feedback

**Author:** main

### What I did

Three testers independently reported the same top gap: the skill said to relay faithfully but never to verify. Both failure directions had just been demonstrated live (codex rightly overturning a fed premise; codex inventing a supporting fact). Added a "Verify before relaying" section: check the load-bearing empirical claims, skip pure judgment, report what was checked.

Other revisions from test reports: `-C <dir>` moved into the core command (agent cwd resets between Bash calls); noted `-s read-only` also blocks network, so paste in what codex cannot discover locally; a wait recipe (watch the answer file, never `pgrep codex`); a do-not-cat warning for the event log; blind-mode guidance for when the user's question is itself the proposal (describe the problem neutrally, require alternatives-considered including "change nothing"); login check matches the positive `Logged in using ChatGPT`; a `codex exec review` section.

Re-tested the sandbox hang against the new standalone binary: sandboxed `codex exec` works end to end. Demoted the hang from a mandatory bypass instruction to a troubleshooting note -- agents should not reflexively disable the sandbox for a problem the current install does not have.

### What I learned

- Verification is the skill's actual payload. The CLI mechanics are learnable from `--help`; "check the claims before relaying, in both directions" is the part every untrained agent skipped or half-improvised.
- Environment observations go stale within a session. Two "facts" (binary path, absent config.toml) inverted after a mid-session reinstall; the skill now tells agents to check the run header instead of trusting documented defaults.

### How to review and validate

Run reports, prompts, verbatim answers, and the `codex exec review` findings are in the session scratchpad under `second-opinion-workspace/` (temporary). To validate the skill live: ask for a second opinion on any real design question and confirm the agent backgrounds the call, reads only `answer.md`, verifies at least one load-bearing claim, and attributes the opinion with model and effort from the log header.
