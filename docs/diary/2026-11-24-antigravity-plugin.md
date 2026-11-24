# Diary: Add Antigravity plugin support

Make `fabrik` work natively as an Antigravity CLI (`agy`) plugin with full parity across skills, lifecycle hooks (`SessionStart` context injection and secret-scanning git hooks), and custom agents (`lead`, `builder`, and `writer`).

## Step 1: Build and validate the `.antigravity/fabrik/` plugin bundle

**Author:** main

### Prompt Context

**Verbatim prompt:** I just want it to work as an Antigravity plugin, so do whatever works. Make sure to work in a worktree.

**Interpretation:** Implement native Antigravity plugin support in an isolated git worktree under `.claude/worktrees/` so `fabrik`'s skills, `SessionStart` hook, and `lead`/`builder`/`writer` agents all load and function properly in Antigravity CLI without breaking Claude Code or Codex.

**Inferred intent:** Use `fabrik` seamlessly across Claude Code, Codex, and Antigravity CLI from the same repository without maintaining duplicated skills or divergent hook logic.

### What I did

Created a worktree at `.claude/worktrees/antigravity-plugin` on branch `antigravity-plugin` and added a native Antigravity plugin bundle under `/.antigravity/fabrik/`:

- Added `/.antigravity/fabrik/plugin.json` (versionless, matching `/.claude-plugin/plugin.json`, with `logo` set to `logo.png`) and `/.antigravity/fabrik/hooks.json` pointing `SessionStart` at `./hooks/scripts/session-start.sh --antigravity`.
- Symlinked `/.antigravity/fabrik/logo.png`, `/.antigravity/fabrik/skills`, `/.antigravity/fabrik/hooks/git-hooks`, and `/.antigravity/fabrik/hooks/scripts` back to the repository's canonical assets so neither symlinked installs (`~/.gemini/config/plugins/fabrik`) nor copy installs (`agy plugin install ./.antigravity/fabrik`, which dereferences symlinks) duplicate files or pull in root repository artifacts like `live12-manual-en.pdf`.
- Added semantic Antigravity agent ports in `/.antigravity/fabrik/agents/lead.md`, `/.antigravity/fabrik/agents/builder.md`, and `/.antigravity/fabrik/agents/writer.md`, translating Claude Code frontmatter and primitives (`opus`/`fable`, omitted `tools`, `Agent`, `SendMessage`, `EnterWorktree`) into Antigravity's schema (`mainAgent`, `subagent`, `model: pro`, explicit `tools` allowlists, `invoke_subagent` with `Workspace: "inherit"` or `"share"`, and `send_message`).
- Extended `/hooks/scripts/session-start.sh` with a `--antigravity` flag that reads `.cwd` (falling back to `.workspacePaths[0]`) from Antigravity's JSON stdin payload to locate `<project>/docs/accomplishments.md` and emits Antigravity's `injectSteps` payload (`systemMessage` for model context and `metadata.user_markdown` for the inline welcome banner).
- Added Antigravity `Model: "pro"` reviewer guidance to `/skills/code-review/SKILL.md`, added `--antigravity` test cases to `/hooks/test/test-git-hooks.sh`, and documented the third agent directory and installation commands in `/AGENTS.md` and `/README.md`.

### Why

Inspecting `/Users/maragubot/.gemini/config/plugins/fabrik` (created by `agy plugin install` on the repository root) and running `agy plugin validate` exposed three reasons a root conversion falls short:

1. Both Claude Code and Antigravity read `<plugin-root>/agents/*.md`, and `plugin.json` has no path override for `agents/`. Antigravity rejected `model: opus` in `/agents/builder.md` and `model: fable` in `/agents/writer.md` (`Invalid model tier ... The loader skips this agent`), and loaded `/agents/lead.md` without an explicit `tools` allowlist (defaulting to a minimal read-only toolset).
2. Antigravity runs hook commands with the plugin folder as `$PWD` rather than the open workspace, passing `.cwd` on stdin, and expects `{"injectSteps": [...]}` on stdout rather than Claude Code's `hookSpecificOutput.additionalContext`.
3. Installing from the repository root copied the entire working tree into `~/.gemini/config/plugins/fabrik`, including untracked/gitignored files like the 108 MB `live12-manual-en.pdf` and `.git`.

Nesting the bundle at `/.antigravity/fabrik/` isolates Antigravity's `agents/*.md` and `plugin.json` from Claude Code's root `agents/` while sharing skills and hook scripts from a single source of truth.

### What worked

`agy plugin validate` ("Checks a plugin the way the plugin loader reads it") gave immediate, authoritative feedback on manifest fields, symlink handling, hook paths, and agent frontmatter. Extending `/hooks/scripts/session-start.sh` with `--antigravity` instead of forking the script kept machine detection, `AGENTS.md` assembly, accomplishments lookup, and `install-git-hooks.sh` execution in one place.

### What didn't work

1. Running `git worktree add .claude/worktrees/antigravity-plugin -b antigravity-plugin main` inside the default terminal sandbox failed with:
   `fatal: cannot lock ref 'refs/heads/antigravity-plugin': Unable to create '/Users/maragubot/Developer/fabrik/.git/refs/heads/antigravity-plugin.lock': Operation not permitted`
   because the sandbox blocks writes into `.git/`. Re-running `git worktree add` outside the sandbox created the worktree cleanly, after which file edits and tests inside the worktree ran sandboxed.
2. Initially symlinking all of `/.antigravity/fabrik/hooks` to `../../hooks` caused `agy plugin validate /Users/maragubot/Developer/fabrik/.claude/worktrees/antigravity-plugin/.antigravity/fabrik --json` to emit a warning on `hooks/hooks.json`:
   `never loaded: plugin hooks are read only from hooks.json at the plugin root`
   Replacing that broad directory symlink with targeted symlinks for `hooks/git-hooks` and `hooks/scripts` removed the stray Claude Code `hooks/hooks.json` and `hooks/test/` from the Antigravity bundle and cleared the warning.

### What I learned

- Antigravity's `agy plugin install` dereferences symlinks when copying a local plugin directory, which means relative symlinks inside `/.antigravity/fabrik/` (`skills`, `logo.png`, `hooks/git-hooks`, `hooks/scripts`) work both when symlinked live into `~/.gemini/config/plugins/fabrik` and when copy-installed via `agy plugin install ./.antigravity/fabrik`.
- In Antigravity's `SessionStart` contract, setting `injectSteps[0].systemMessage.metadata.user_markdown` alongside `injectSteps[0].systemMessage.systemMessage` reproduces Claude Code's exact split between a short inline user welcome message and full model-only startup context.
- Antigravity caps inline skill bodies at 24,000 bytes (`skills/turbopuffer/SKILL.md` is 27,617 bytes and triggers a non-fatal truncation warning during validation, though `read_file` still reads the full file on demand).

### What was tricky

Making sure `/hooks/scripts/install-git-hooks.sh` resolves `../git-hooks` identically whether invoked directly from `/hooks/scripts/session-start.sh`, through the symlinked `/.antigravity/fabrik/hooks/scripts/session-start.sh`, or from a dereferenced copy installed in `~/.gemini/config/plugins/fabrik/`. Linking both `hooks/git-hooks` and `hooks/scripts` inside `/.antigravity/fabrik/hooks/` preserves the `../git-hooks` sibling relationship in every mode.

### What warrants review

- Compare `/.antigravity/fabrik/agents/{lead,builder,writer}.md` against `/agents/*.md` and `/.codex/agents/*.toml` to verify semantic alignment of responsibilities, tool grants, model tiers, and workspace boundaries.
- Check `/hooks/scripts/session-start.sh` in both default and `--antigravity` modes (`bash hooks/test/test-git-hooks.sh`).
- Confirm `~/.gemini/config/plugins/fabrik` is pointed at `/.antigravity/fabrik` (replacing any earlier root-installed copy) so a fresh `agy` session picks up all three agents and the `SessionStart` hook.

### Future work

- Trim `/skills/turbopuffer/SKILL.md` below 24,000 bytes by moving detailed API reference sections into `/skills/turbopuffer/references/` if `/turbopuffer` slash-command inline expansion ever hits the truncation cap in practice.

## Step 2: Pivot to root-level GitHub install and verify live

**Author:** builder

### Prompt Context

**Verbatim prompt:** "Ignore the agents for now, make everything else installable and check that it works." (Handed down through the lead's Step 2 brief, followed by the lead's instruction to omit `metadata` from Antigravity's `systemMessage` and prepend `$SYSTEM_MESSAGE` instead.)

**Interpretation:** Remove the `/.antigravity/fabrik/` nested bundle prototype, revert sub-agent directory docs back to `agents/` and `.codex/agents/`, test whether root-level `/.antigravity-plugin/plugin.json` and `/hooks.json` install cleanly alongside Claude Code's `/agents/*.md`, harden `/hooks/scripts/session-start.sh` and `/hooks/test/test-git-hooks.sh`, and verify installation and `SessionStart` injection live with `agy -p`.

**Inferred intent:** Let Markus install `fabrik` directly via `agy plugin install https://github.com/maragudk/fabrik` without maintaining a separate `.antigravity/` subdirectory or duplicating/porting sub-agents yet, while ensuring skills and `SessionStart` context injection actually work in a real `agy` session.

### What I did

Removed `/.antigravity/` from the worktree and restored `/AGENTS.md` and `/README.md` to `HEAD` before applying the root-level Antigravity setup:

- Added `/.antigravity-plugin/plugin.json` (`name`, `description`, `logo: "logo.png"`) and root `/hooks.json` running `./hooks/scripts/session-start.sh --antigravity` with `timeout: 60`.
- Updated `/hooks/scripts/session-start.sh` to enter Antigravity mode on `--antigravity` or when `PLUGIN_ROOT` is set without `CLAUDE_PLUGIN_ROOT`, default `PROJECT_DIR` to `""` in that mode, extract `([.cwd?, .workspacePaths[0]?] | map(select(type == "string" and length > 0)) | first) // empty` directly from stdin via `jq`, guard the `docs/accomplishments.md` check on `[ -n "$PROJECT_DIR" ]`, and emit `injectSteps[0].systemMessage.systemMessage` with `$SYSTEM_MESSAGE` prepended (`"$SYSTEM_MESSAGE\n\n$CONTEXT"`) and no `metadata` map.
- Expanded `/hooks/test/test-git-hooks.sh` to `unset PLUGIN_ROOT CLAUDE_PLUGIN_ROOT` at startup and cover Antigravity mode against a decoy `$T/plugin-dir/docs/accomplishments.md`, fresh `XDG_CONFIG_HOME` hook installation, `cwd: ""` and `cwd: null` fallbacks to `workspacePaths`, malformed `workspacePaths`, empty and invalid JSON stdin, `PLUGIN_ROOT` auto-detection, `--antigravity` overriding `CLAUDE_PLUGIN_ROOT`, `PLUGIN_ROOT` + `CLAUDE_PLUGIN_ROOT` staying in default mode, foreign `core.hooksPath` warnings, and explicit `metadata == null` regression checks.
- Updated `/skills/code-review/SKILL.md` (`TypeName: "research"` and `Model: "pro"`), added `### Antigravity` (`agy plugin install https://github.com/maragudk/fabrik`) to `/README.md`, and documented `/.antigravity-plugin/` and `/hooks.json` in `/AGENTS.md` (keeping two sub-agent formats and crediting both Claude Code and Codex for `/hooks/`).
- Ran competing two-subagent code review (`research` on `pro`), fixed reviewer findings (optional indexing `.cwd?` / `.workspacePaths[0]?`, removing single-use `INPUT`, clarifying the `systemMessage.metadata` comment without leaking internals, fixing `/AGENTS.md` `/hooks/` attribution, and filling edge-case test gaps), staged the clean worktree into `/tmp/fabrik-agy-stage` (excluding `.git`, `.claude`, `.worktrees`, `.env`, and `*.pdf`), installed with `agy plugin install /tmp/fabrik-agy-stage`, and verified live via `agy plugin list --json` and `agy -p` from `/tmp`.

### Why

Installing from GitHub (`agy plugin install https://github.com/maragudk/fabrik`) targets the repository root directly, so root `/.antigravity-plugin/plugin.json` and `/hooks.json` are needed unless `.claude-plugin/` staging suffices; empirical testing showed `agy plugin install` succeeds with root manifests while skipping incompatible `/agents/*.md` files at load time. Supporting `PLUGIN_ROOT` auto-detection alongside `--antigravity` also keeps `/hooks/scripts/session-start.sh` resilient across both root `/hooks.json` and converted Claude Code configs. Live `agy -p` testing was essential because unit tests only validated the documented `metadata.user_markdown` JSON shape, whereas `agy` 1.5.16 panicked on the non-empty `metadata` map at runtime.

### What worked

- Empirical staging into `/tmp/fabrik-agy-test` and `/tmp/fabrik-agy-stage` confirmed `agy plugin install` exited 0 and registered 36 skills, 1 agent (`lead`), and 1 hook (`fabrik`).
- Re-running `bash /Users/maragubot/Developer/fabrik/.claude/worktrees/antigravity-plugin/hooks/test/test-git-hooks.sh` after all fixes passed `369 passed, 0 failed`, and `git diff --check` exited 0.
- Final `agy plugin list --json` listed `fabrik` enabled at `/Users/maragubot/.gemini/config/plugins/fabrik`, and `cd /tmp && agy -p "Reply in one short sentence: what is my name, what is your name, what machine are we running on, and do you have the dad-joke skill?"` replied: `You're Markus, I'm maragubot, we're running on your Mac mini (\`maragubots-Mac-Mini.local\`), and yes, I have the \`dad-joke\` skill.`

### What didn't work

1. `git -C /Users/maragubot/Developer/fabrik/.claude/worktrees/antigravity-plugin checkout -- AGENTS.md README.md` failed inside the sandbox because writing `.git/worktrees/antigravity-plugin/index.lock` in the main checkout's `.git` directory is blocked:
   `fatal: Unable to create '/Users/maragubot/Developer/fabrik/.git/worktrees/antigravity-plugin/index.lock': Operation not permitted`
   Restored both files read-only from `git show HEAD:<path>` instead.
2. `agy plugin validate /tmp/fabrik-agy-test --json` exited 1 (`2 errors, 4 warnings`) on `/agents/builder.md` (`Invalid model tier opus. The loader skips this agent`) and `/agents/writer.md` (`Invalid model tier fable. The loader skips this agent`), plus warnings on missing `version` in `/.antigravity-plugin/plugin.json`, `/AGENTS.md`, `/hooks/hooks.json`, and `/skills/turbopuffer/SKILL.md`. `agy plugin install /tmp/fabrik-agy-test` still succeeded (exit 0) by skipping the two invalid agents at load time.
3. The first live `cd /tmp && agy -p "Reply in one short sentence: what is my name, what is your name, and do you have the dad-joke skill?"` saw `dad-joke` but did not receive `SessionStart` context:
   `I don't know your name yet, my name is Antigravity, and yes, I have the \`dad-joke\` skill.`
   Running with `--log-file /tmp/agy-verify.log` revealed `agy` 1.5.16 panicked inside `CallSessionStartHook` when scrubbing `systemMessage.metadata`:
   `E1124 11:47:58.482072    1124 hookcaller.go:56] hook "jsonhook__fabrik_SessionStart_0_0" panicked: type mismatch: cannot convert string to message`
   `google3/third_party/jetski/cortex/utils/utils.scrubMessage.1.1(...)` / `third_party/jetski/cortex/utils/proto_utils.go:34`
   `E1124 11:47:58.482159    1124 provider.go:80] session start hook "jsonhook__fabrik_SessionStart_0_0" failed: hook jsonhook__fabrik_SessionStart_0_0 panicked: type mismatch: cannot convert string to message`
   Removing `metadata` from `injectSteps[0].systemMessage` and prepending `$SYSTEM_MESSAGE` into `systemMessage` resolved the panic (verified both via a temporary `/tmp/agy-hook-test/.agents/hooks.json` and after re-installing `/tmp/fabrik-agy-stage`).
4. Adding a bash `[[ ... ]]` expression directly as arguments to `check` in `/hooks/test/test-git-hooks.sh` failed because `check` invokes `"$@"`:
   `/Users/maragubot/Developer/fabrik/.claude/worktrees/antigravity-plugin/hooks/test/test-git-hooks.sh: line 54: [[: command not found` (`362 passed, 1 failed`). Replaced it with `jq -e '... | startswith("Welcome to fabrik. Warning: Secret scanning is not active")'`.

### What I learned

- `agy plugin install` does not abort on per-agent model validation errors in `/agents/*.md`; it skips `builder` and `writer` and installs `lead`, all 36 skills, and root `/hooks.json`.
- In `agy` 1.5.16, Antigravity's documented `metadata.user_markdown` field on `injectSteps[].systemMessage` triggers a Go protobuf reflection panic (`utils.scrubMessage` in `proto_utils.go:34` assumes map values are messages on `map<string, string> metadata`) and causes the entire `SessionStart` hook output to be dropped.
- `jq`'s `[.cwd, .workspacePaths[0]]` throws before `map` runs if `.workspacePaths` is non-array (such as a string), silently discarding a valid `.cwd` when stderr is suppressed; `[.cwd?, .workspacePaths[0]?]` avoids that trap.

### What was tricky

- Remembering to test `agy -p` in a neutral directory (`/tmp`) rather than the repository directory (which has its own `/AGENTS.md`), and diagnosing why `SessionStart` silently disappeared without failing the CLI command itself — `agy` swallowed the panicked `SessionStart` hook in logs while continuing the turn with no startup context.

### What warrants review

- Inspect the uncommitted diff across `/AGENTS.md`, `/README.md`, `/.antigravity-plugin/plugin.json`, `/hooks.json`, `/hooks/scripts/session-start.sh`, `/hooks/test/test-git-hooks.sh`, `/skills/code-review/SKILL.md`, and `/docs/diary/2026-11-24-antigravity-plugin.md`.
- Confirm the intentional duplicate warning wording in Antigravity `systemMessage` when `core.hooksPath` is foreign (`Welcome to fabrik. Warning: ...` on line 1 for user preview plus `## Secret scanning\n\nWarning: ...` in the body).
- After merging/pushing to GitHub, run `agy plugin install https://github.com/maragudk/fabrik` to test the remote URL path directly.

### Future work

- Decide whether to port `/agents/{builder,lead,writer}.md` into Antigravity-compatible definitions or suppress the 2 agent load errors once Antigravity agent support is prioritized.
- Revisit `metadata.user_markdown` in `/hooks/scripts/session-start.sh` if a future `agy` release fixes the `utils.scrubMessage` map panic.
