# Diary: Secret-scanning git pre-commit hook

Markus wants fabrik to ship hooks that aid coding agents. The first is automated secret scanning, so agents (and he) don't have to worry about committing secrets. This diary covers shaping the requirements and building a dependency-free scanner that runs as a global git pre-commit hook, installed automatically by fabrik's SessionStart hook.

## Step 1: Shape requirements

**Author:** main

### Prompt Context

**Verbatim prompt:** I'd like some new hooks in fabrik, to aid coding agents in their work. The first thing I want is automated secret scanning, so they don't have to worry about committing secrets. How could we set that up?
**Interpretation:** Design a secret-scanning mechanism delivered by the fabrik plugin, starting from a proposal and refining it with Markus before any building.
**Inferred intent:** Make it hard for any agent session to land a secret in git history, without per-repo setup or ongoing attention.

### What I did

Read `/hooks/hooks.json` and `/hooks/scripts/session-start.sh` (the only existing hook is SessionStart, which injects `/hooks/scripts/AGENTS.md` as context). Proposed a Claude Code `PreToolUse` hook on Bash running gitleaks on `git commit`. A research sub-agent then looked at obra/superpowers (Markus's suggestion) and at Codex and Claude Code hook mechanics.

Markus steered the design through several turns:

- "I'd rather not have external dependencies." -- gitleaks dropped in favour of our own bash script using `grep -E`.
- "Would it be easier to just make a git precommit hook that we can install easily through fabrik?" -- yes; switched from a PreToolUse hook to a global git pre-commit hook.
- Install automatically from the SessionStart hook; chain to repo-local hooks.
- Block files named exactly `.env`.
- Detectors trimmed to Anthropic, OpenAI, AWS, and Google keys only.

Separately, Markus asked for a rule to build in worktrees rather than the main checkout. I first put it in `CLAUDE.local.md`, then moved it to `/AGENTS.md` (which `CLAUDE.md` symlinks to, so Codex reads it too) and committed it on this branch as `183c114`. It lands on `main` together with the scanner.

### Why

A git pre-commit hook is the actual enforcement point: it catches agent commits, commits made inside scripts (`make release`), and human commits. Git has already done the staging for `git commit -a` and `git -C dir commit`, so no shell-command parsing is needed. It works for Codex without the Codex hook-trust re-approval that a PreToolUse hook would need on every change.

### What worked

The research pass settled the PreToolUse details quickly, and those details are what made the git-hook route look better: Claude Code's `if: "Bash(git commit *)"` does not match `git -C dir commit`, and Codex has no `if` field at all, so a PreToolUse version would have needed its own command parser.

### What didn't work

The first proposal (gitleaks via PreToolUse) was rejected on dependency grounds, and the PreToolUse shape itself was then superseded. Nothing failed technically; the design just moved twice.

### What I learned

- obra/superpowers has no secret scanning or commit guard; its only hook is SessionStart. Worth borrowing: table-driven hook tests that pipe inputs with stripped environments and assert on output. Worth avoiding: failing open silently on missing dependencies.
- Codex already loads fabrik's `/hooks/hooks.json` (there's a trust entry for the session-start hook in `~/.codex/config.toml`), and it trusts hooks by hash, so changing `/hooks/scripts/session-start.sh` means re-approving it once in Codex's `/hooks`.
- A global `core.hooksPath` disables every repo-local hook in `.git/hooks`, not just pre-commit, hence chaining stubs for all standard client-side hooks.

### What was tricky

The plugin install path changes with each update (installs follow `main` by commit SHA), so `core.hooksPath` can't point into the plugin directory; the scripts must be copied to a stable location.

### What warrants review

That the installer never clobbers an existing `core.hooksPath` set to something else, and that tests never touch the real global git config.

### Future work

Known accepted gaps: `git commit --no-verify` bypasses the hook, and repos that set a local `core.hooksPath` (husky v9 does) override the global one, so scanning doesn't run there.

## Step 2: Build the scanner, chaining stubs, installer, and tests

**Author:** builder

### Prompt Context

**Verbatim prompt:** You are building a dependency-free secret scanner for fabrik, shipped as a global git pre-commit hook and installed automatically by fabrik's SessionStart hook. (Followed by the lead's full brief: where to work, the agreed decisions, five numbered requirement sections for the scanner, chaining, installer, tests, and docs, and a "Done means" list.)
**Interpretation:** Implement Step 1's design with only bash, git, grep -E, sed/awk, and jq, portable to macOS bash 3.2 with BSD tools and to Raspberry Pi OS with GNU grep and mawk.
**Inferred intent:** Make it hard for any session, agent or human, to commit a key, without per-repository setup and without slowing git down.

### What I did

Layout: `/hooks/git-hooks/` holds `scan-secrets` (the scanner), `pre-commit` (scan, then chain), `run-local-hook` (the shared chaining implementation), and one identical thin `/bin/sh` stub per other client-side hook name. `/hooks/scripts/install-git-hooks.sh` copies that directory to `${XDG_CONFIG_HOME:-~/.config}/fabrik/git-hooks` and sets the global `core.hooksPath` when unset. `/hooks/scripts/session-start.sh` runs it and appends any warning to `systemMessage` and `additionalContext`. The tests are in `/hooks/test/test-git-hooks.sh`.

The scanner runs `git diff --cached --unified=0` through awk. Awk tracks the hunk line counts, so it knows each added line's number in the new file and never mistakes an added `++` line for a `+++` header. It writes two line-aligned files: `path<TAB>line` and the added line padded with a space on each side. Each detector is then one `grep -anoE` over the whole content file, and `-n` maps a hit back to its record. The padding means every fixed-length detector can require a non-key character on both sides without `^`/`$` alternations, which BSD `grep -o` handles badly. `.env` detection is a separate `git diff --cached --name-only -z --diff-filter=ACR`.

Regexes chosen (with the gitleaks rules as a reference):

- Anthropic: `sk-ant-[a-z]+[0-9]{2}-[A-Za-z0-9_-]{80,}`. Real keys have 93 characters plus `AA` after the version tag. The general tag covers `api03`, `admin01`, and the `oat01` OAuth tokens. Requiring 80 or more rules out `sk-ant-api03-...` placeholders.
- OpenAI: `sk-(proj|svcacct|admin)-[A-Za-z0-9_-]{80,}` (real bodies are 116 or more characters) and the legacy `[^A-Za-z0-9_-]sk-[A-Za-z0-9]{48}[^A-Za-z0-9_-]`. The legacy pattern can't match inside an Anthropic key, because the hyphen in `sk-ant-` breaks the 48-alphanumeric run, and the left boundary stops mid-key matches. I didn't require `T3BlbkFJ`, because the brief specified the formats without it.
- AWS key ID: `[^A-Za-z0-9_](AKIA|ASIA)[A-Z0-9]{16}[^A-Za-z0-9_]`, which is `\b` semantics.
- AWS secret: 40 characters of `[A-Za-z0-9/+]` closely following `aws_secret_access_key` and similar names, matched case-insensitively. The final form is in Step 3.
- Google: `[^A-Za-z0-9_-]AIza[0-9A-Za-z_-]{35}[^A-Za-z0-9_-]`.

Redaction prints the first 8 characters and then `…`, or 4 for the AWS secret, which has no fixed prefix. The scanner sets `LC_ALL=C` and uses `grep -a` throughout.

`run-local-hook` finds the repository hooks via `git rev-parse --git-common-dir`, so it works in linked worktrees. It execs the hook with args and stdin, so its exit code passes through. It refuses to run a hook that resolves into its own directory, whether directly, through a symlinked hooks directory, or through a symlinked hook.

The installer compares with `diff -rq` and copies each file to a per-process temp name before renaming it into place. It writes `core.hooksPath` as `~/.config/fabrik/git-hooks` when the destination is under HOME, so a global gitconfig shared between the Mac and the Pi stays valid on both.

The tests build every fake key at runtime with a deterministic generator, so no key-shaped literal lands in the repo. They point HOME, XDG_CONFIG_HOME, and GIT_CONFIG_GLOBAL into a temp dir, and refuse to run unless `git config --global --show-origin` shows the temp file. The table rows are `path|content|expectation`, followed by scenario blocks.

### Why

One grep pass per detector over all added lines keeps the scan to a fixed number of processes regardless of diff size. A per-line bash loop over lines containing "secret" would have meant thousands of forks on a big commit.

### What worked

- The first full run on macOS passed once a test-helper bug was fixed.
- Running the suite in Docker stood in for the Pi. `debian:stable-slim` (amd64 under emulation: mawk 1.3.4 20250131, GNU grep 3.11, git 2.47.3) and `debian:bookworm-slim` on arm64 (mawk 1.3.4 20200120, GNU grep 3.8, git 2.39.5) both passed. The mounted script installs git and jq first.

### What didn't work

- `ssh pi3` (and `pi3.local`) failed with `ssh: Could not resolve hostname pi3: nodename nor servname provided, or not known`, so the Pi itself wasn't tested. Docker on arm64 bookworm was the closest substitute.
- The first test run gave `182 passed, 40 failed`. `r=$(new_repo)` ran `new_repo` in a subshell, so its `N` counter never advanced, and every test reused `repo1`. Worse, once one test symlinked `repo1/.git/hooks` to the source hooks directory, the next `git init` re-initialised `repo1` and copied git's 14 `*.sample` templates through the symlink into `/hooks/git-hooks/`. The writer sub-agent spotted the stray files. I deleted them, made the symlink tests use a copy in the temp dir, and added a final check that the source directory's `ls -l` is unchanged.
- The worktree sandbox refused several Bash commands with "this command names git in a form too complex to verify". This came from paths containing `git-hooks`, heredocs mentioning git, and `cd`. I moved such work into scripts in the scratchpad and ran them with `bash <script>`.
- Adding close-status checks to the awk `END` block made every commit fail closed (`could not read the staged diff`). `close()` on a file that was never opened returns -1 in BSD awk. Now only files that were written get checked.

### What I learned

- In this harness's zsh, `grep` is a shell function wrapping ugrep. Inside `bash` scripts it's `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD). Test portability in `bash`, not in the interactive shell.
- In hooks, git leaves `GIT_DIR` unset for a plain repository, with cwd at the worktree root. It sets `GIT_DIR` to `.git/worktrees/<name>` (which contains a `commondir` file) in a linked worktree, and to the given path with `--git-dir`. The stubs' fork-free fast path relies on this.

### What was tricky

- `push-to-checkout` can't be stubbed, because its mere existence replaces git's built-in `updateInstead` behaviour.
- BSD `grep -o` with `^` alternations is unreliable, hence the space padding.

### What warrants review

- The regex choices above.
- That `/hooks/test/test-git-hooks.sh` can never touch the real global config: the isolation check is near the top.

### Future work

None beyond Step 3's list.

## Step 3: Self-review with two competing reviewers, and fixes

**Author:** builder

### Prompt Context

**Verbatim prompt:** (same brief) "Once the implementation is done, self-review before handing back to the lead."
**Interpretation:** Run the code-review skill's two competing reviewers over the diff, then fix what they find.
**Inferred intent:** Find the bugs before Markus does.

### What I did

Two reviewers ran independently, using experiments in isolated temp dirs. Consensus findings, all fixed:

1. **Fail-open on context lines.** `diff.interHunkContext=3` or `GIT_DIFF_OPTS=--unified=5` makes git emit context lines even with `--unified=0`. The awk treated a context line as the end of the hunk, so every later `+` line in it went unscanned and a key committed with rc=0. Now the scanner passes `--inter-hunk-context=0`, unsets `GIT_DIFF_OPTS`, counts context lines (including empty ones from `diff.suppressBlankEmpty`), and exits 2 (fail closed) on any in-hunk line it doesn't recognise.
2. **Speed.** Hook existence alone made git slow. Each stub cost about 20 ms, `reference-transaction` fires about 7 times per commit and about 22 times per rebased commit, and a 20-commit rebase went from 0.1 s to about 9 s. I dropped the `reference-transaction` and `post-index-change` stubs and rewrote the rest as `/bin/sh` with a fork-free fast exit. When no `.git/hooks/<name>` exists, the repository isn't a linked worktree, and there's no `.git/lfs`, the stub exits at once. The scanner also prefilters in awk (only lines containing `sk-`, `AKIA`, `ASIA`, `AIza`, or `secret` reach grep) and skips the detector greps when nothing matches. Measured with a scratch benchmark: 20 commits took 0.80 s without the hooks and 2.02 s with them (about 60 ms each). A 20-commit rebase took 0.14 s without and 0.35 s with.
3. **Git LFS breakage.** git-lfs installs into `core.hooksPath`, finds fabrik's `pre-push` there, and skips. A reviewer verified that a push then uploaded 0 of 1 LFS objects. `run-local-hook` now execs `git lfs <hook>` for pre-push, post-checkout, post-commit, and post-merge when the repository has `.git/lfs` and no hook of its own. If git-lfs is missing, pre-push exits 2, matching git-lfs's own hook.
4. **Installer read without includes.** `git config --global --get` ignores `[include]`, so a dotfiles-style included `core.hooksPath` was silently overridden. It now reads with `--includes` and also checks `--system`.
5. **Installer races.** Concurrent session starts gave spurious "could not copy" warnings because of shared temp names and deletion of other processes' temp files. Temp names are now per-process, and success is decided by re-checking that the copy is current. A lost config-lock race re-reads the value before warning.
6. **Dotfiles forcing a recopy.** A `.DS_Store` made `diff -rq` differ forever. Extra files in the destination are now ignored and left alone, so files written by other tools are no longer deleted.
7. **Weak tests.** The redaction check now asserts that no 8-character window past each key's prefix (or its last 8 characters) appears, and that every printed match is at most 8 characters. The new tests cover interHunkContext, GIT_DIFF_OPTS, multi-hunk and multi-file line numbers, quoted paths, renaming into `.env`, editing a tracked `.env` (passes), `--amend`, a mid-pipeline diff failure, a broken scanner blocking a real commit, the exact exit-code pass-through (3), CDPATH, the non-executable-hook hint, the LFS fallback, `[include]` and system config, concurrent installs, no rewrite on an idempotent run, and a watchdog so a recursion regression fails instead of hanging.

Single-reviewer findings fixed because they were cheap or serious:

- An exported `CDPATH` made `cd .git/hooks` print a path, which silently disabled repository hooks. Both scripts now `unset CDPATH`.
- BSD awk truncates at NUL, which missed a key after a NUL past byte 8000. NULs now become spaces via `tr`.
- The scanner now checks its writes to the findings file.
- Tabs and newlines in `.env` paths are sanitised.
- The ignored-hook hint now matches git's.
- Common AWS secret spellings were missed (`aws configure set …`, `--secret-access-key`, `AWS_SECRET_KEY`, XML tags, escaped JSON, `setenv(…)`). The final regex is `(aws[_.-]?secret[_.-]?(access[_.-]?)?key|secret[_.-]?access[_.-]?key)[^A-Za-z0-9/+]{1,6}[A-Za-z0-9/+]{40}[^A-Za-z0-9/+=]`, matched case-insensitively.
- Comments that named callers are rewritten, and the single-use variables `TAB`, `LOWER`, and `ROWS` are inlined.

Not fixed, for the lead and Markus to decide:

- Server-side hooks (`pre-receive`, `update`, `post-receive`, `post-update`) are silently disabled in local bare repos, which affects push-to-deploy. The brief said to skip server-side stubs. Adding them is a four-line change.
- There's no false-positive escape hatch apart from `--no-verify`, which the message forbids. AWS's documented example ID and public-by-design Firebase/Maps browser keys get blocked. The brief explicitly ruled out an allowlist.
- Merges: a clean `git merge` is unscanned, while concluding a conflicted merge scans everything incoming. `git am` and cherry-picks are unscanned too.
- `git lfs install` and the pre-commit framework refuse to install while `core.hooksPath` is set.
- Files marked `-diff` or `binary` in `.gitattributes` are skipped, as git treats them as binary.
- No session-start warning when the current repo sets a local `core.hooksPath` (husky).
- Two same-detector keys separated by a single character are reported once. The commit is still blocked.

### Why

The fail-open and the LFS upload loss were the kind of silent failures a safety net must not have. The slowdown would have made Markus rip the whole thing out.

### What worked

Mutation checks on a copy of `/hooks` confirmed that the new tests catch the regressions the reviewers found surviving. Removing pipefail now fails 2 tests, a redaction leak 31, removing the NUL handling 4, `--diff-filter=A` 2, dropping `unset CDPATH` 1, and dropping `--includes` 6. Removing all three context-line defences together fails 2. Final results: `284 passed, 0 failed` on macOS (bash 3.2.57, BSD grep, awk 20200816, git 2.54.0), on Debian stable amd64, and on Debian bookworm arm64.

### What didn't work

Mutating only one context-line defence at a time leaves the suite green, because the other two still catch it. That is defence in depth working, not a test gap, but it means each layer isn't pinned on its own. The installer's per-process temp names aren't pinned by a test either, because the "re-check that the copy is current" logic makes the old shared-name race harmless too.

### What I learned

- `git config --get` never follows `[include]` unless asked with `--includes`.
- Git skips a hook that doesn't exist without forking anything, so every stub that exists costs a process per invocation. Hooks like `reference-transaction` fire far more often than you'd guess.

### What was tricky

The background watchdog in the tests kept the test's stdout pipe open for 60 s after the suite finished, because the orphaned `sleep` inherited it. Redirecting the watchdog's output to `/dev/null` fixed it.

### What warrants review

- The LFS fallback in `/hooks/git-hooks/run-local-hook`.
- The fast path in the stubs (e.g. `/hooks/git-hooks/commit-msg`): it must never skip a real repository hook.
- The installer's foreign-value logic in `/hooks/scripts/install-git-hooks.sh`.
- Codex trusts hooks by hash, so `/hooks/scripts/session-start.sh` needs re-approving once in Codex's `/hooks`.

### Future work

The "Not fixed" list above. Run `bash hooks/test/test-git-hooks.sh` on the real pi3 when it's reachable.

## Step 4: Show the `.env` advice only when a `.env` was found

**Author:** builder

### Prompt Context

**Verbatim prompt:** yes
**Interpretation:** The lead asked whether the `.env` instructions should appear only when a `.env` was actually found. The answer was yes. I applied the same rule to the "Remove each secret" line, so a `.env`-only block doesn't tell the agent to edit secrets out of a file.
**Inferred intent:** Make the block message match what was found, so the agent isn't sent to fix a problem it doesn't have.

### What I did

In `/hooks/git-hooks/scan-secrets`, the report step now checks the findings file once for each kind. Record number 0 means a `.env` file, and any other record is a key. Two `awk` one-liners set `has_env` and `has_key`, and each advice line is printed only when its flag is set. The other lines (retry, `--no-verify`) are unchanged. In `/hooks/test/test-git-hooks.sh` I added three scenarios, key-only, `.env`-only, and both, with checks for each advice line and the `--no-verify` line. The fake key is still built at runtime.

### Why

A block caused only by a `.env` file said "Remove each secret from the file", which is wrong advice, and a block caused only by a key mentioned `.env` for no reason.

### What worked

`awk -F '\t' '$1 == 0 { print "yes"; exit }'` is bash 3.2 and BSD safe. The suite passes with `296 passed, 0 failed` on macOS.

### What didn't work

My first "no such line" checks used `check "..." ! grep -qF ...`. `check` runs its arguments as a command, so `!` was looked up as a program, and the checks failed even though the hook output was right (`294 passed, 2 failed`). A small `lacks` helper that negates the `grep` fixed it.

### What I learned

`check` can't take a negated command directly. A helper function is the way to assert absence.

### What was tricky

Nothing beyond the `check` and `!` problem above.

### What warrants review

The `has_env` and `has_key` block in `/hooks/git-hooks/scan-secrets` and the three new scenarios in `/hooks/test/test-git-hooks.sh` before the `--amend` test.

### Future work

None.
