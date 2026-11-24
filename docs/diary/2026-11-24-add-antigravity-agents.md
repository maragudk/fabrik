# Diary: Add Antigravity sub-agent definitions

Add semantic Antigravity definitions for `fabrik`'s `lead`, `builder`, and `writer` agents under `/.antigravity/agents/` (mirroring `/.codex/agents/`), update `/AGENTS.md` and `/README.md` to keep all three platforms in sync, and verify live discovery through `~/.gemini/config/agents`.

## Step 1: Shape requirements and delegate to builder

**Author:** lead

### Prompt Context

**Verbatim prompt:** Okay, so how do we get the agents working? A workaround just on this machine would also be fine for now. (Followed by: `1` selecting the `.antigravity/agents/` + `~/.gemini/config/agents` symlink option.)

**Interpretation:** Keep `/agents/*.md` untouched for Claude Code and add semantic Antigravity ports under `/.antigravity/agents/{lead,builder,writer}.md`, mirroring `/.codex/agents/`. Document the three-platform agent parity rule in `/AGENTS.md` and the Antigravity agent install step in `/README.md`, then verify that `~/.gemini/config/agents` loads all three agents and overrides the plugin's root `lead.md`.

**Inferred intent:** Make `lead`, `builder`, and `writer` work natively in Antigravity CLI across every repository on this machine without breaking Claude Code's root `/agents/` or duplicating the 36 skills.

### What I did

Created a fresh worktree at `.claude/worktrees/antigravity-agents` on branch `antigravity-agents` from `main` (`c18e037`), started this diary, and dispatched a builder subagent with full requirements for `/.antigravity/agents/{lead,builder,writer}.md`, `/AGENTS.md`, `/README.md`, live `agy agents` / `agy -p` verification, and competing code review.

### Why

Antigravity discovers global custom agents in `~/.gemini/config/agents/*.md` with higher precedence than plugin-bundled agents. Storing the Antigravity ports in `/.antigravity/agents/` avoids colliding with Claude Code's `/agents/*.md` during `agy plugin install https://github.com/maragudk/fabrik` while keeping all three harnesses aligned in version control.

### What worked

Creating the worktree cleanly from `c18e037` kept the main checkout untouched while the builder works.

### What didn't work

Nothing failed in this step.

### What I learned

Separating plugin installation (`agy plugin install https://github.com/maragudk/fabrik`) from global agent linking (`~/.gemini/config/agents`) lets `fabrik` support direct GitHub installs for skills and hooks while keeping platform-specific agent definitions cleanly isolated.

### What was tricky

Making sure the builder's live verification checks whether `~/.gemini/config/agents` already exists before touching it, and verifies that global `lead.md` overrides the plugin's `lead.md` without duplicate agent entries.

### What warrants review

- Semantic parity between `/agents/*.md`, `/.codex/agents/*.toml`, and `/.antigravity/agents/*.md`.
- Live `agy agents` output confirming `lead`, `builder`, and `writer` load cleanly with no `lead` collision.

### Future work

- Once merged to `main` and pushed, point `~/.gemini/config/agents` at `/Users/maragubot/Developer/fabrik/.antigravity/agents` on this machine.

## Step 2: Port Antigravity agent definitions, update docs, and verify discovery

**Author:** builder

### Prompt Context

**Verbatim prompt:** Add semantic Antigravity agent definitions under `.antigravity/agents/` (mirroring `.codex/agents/`), update `AGENTS.md` and `README.md`, and verify live discovery in `agy`.

**Interpretation:** Read `/agents/{lead,builder,writer}.md` and `/.codex/agents/{lead,builder,writer}.toml`, create semantic Antigravity ports under `/.antigravity/agents/{lead,builder,writer}.md` in the `.claude/worktrees/antigravity-agents` worktree, document three-platform sub-agent parity and global agent linking in `/AGENTS.md` and `/README.md`, verify discovery and global `lead` override live with `agy` via a temporary `~/.gemini/config/agents` symlink (then clean up the temporary link), self-review with two competing `research` reviewers (`Model: "pro"`), run checks, and append this diary step without committing.

**Inferred intent:** Give `agy` full working `lead`, `builder`, and `writer` agents across repositories without touching `/agents/*.md` for Claude Code or leaving `~/.gemini/config/agents` pointed at a temporary worktree.

### What I did

Created `/.antigravity/agents/lead.md`, `/.antigravity/agents/builder.md`, and `/.antigravity/agents/writer.md` with YAML frontmatter (`name`, matching `description`, `mainAgent`, `subagent`, `model: pro` on `builder` and `writer` with session-model inheritance on `lead`, and explicit `tools` allowlists) and translated Antigravity workflows (`invoke_subagent`, `send_message`, `manage_subagents`, `ask_question`, `Workspace: "inherit"` and `"share"`, `pro`/`flash`/`flash_lite`, explicit `<worktree>` propagation, and `git -C <worktree>` usage).

Updated `/AGENTS.md` to add `/.antigravity/agents/` under `## Structure` and update the `## Adding a new skill, sub-agent, or hook` parity rule across Claude Code (`/agents/<name>.md`), Codex (`/.codex/agents/<name>.toml`), and Antigravity (`/.antigravity/agents/<name>.md`). Updated `/README.md` under `### Antigravity` with the global `ln -s "$(pwd)/.antigravity/agents" ~/.gemini/config/agents` setup and under `## Available Sub-agents` to mention all three platforms.

Dispatched two competing `research` subagents (`Model: "pro"`) via `code-review` over the worktree diff, resolved all consensus findings across `/.antigravity/agents/lead.md`, `/.antigravity/agents/builder.md`, and `/README.md`, then ran final validation (`git diff --check`, `bash hooks/test/test-git-hooks.sh` passing `369 passed, 0 failed`) and live `agy` verification against a temporary `~/.gemini/config/agents` symlink before removing the temporary symlink.

### Why

Keeping Antigravity ports under `/.antigravity/agents/` preserves `/agents/*.md` for Claude Code and `/.codex/agents/*.toml` for Codex while giving `agy` valid model names (`pro`/`flash`/`flash_lite`), explicit `tools` allowlists, and accurate Antigravity worktree and `send_message` mechanics.

### What worked

With `~/.gemini/config/agents` linked to the worktree's `/.antigravity/agents`, `agy agents` listed a single `lead` (`mainAgent: true` only on `lead`), `cd /tmp && agy -p "List your available subagents and their names only."` listed `self`, `research`, `image-generator`, `builder`, `lead`, and `writer`, and `agy --agent lead` confirmed all 11 allowlisted tools and instructions using `invoke_subagent` rather than `EnterWorktree` -- proving the global `~/.gemini/config/agents/lead.md` overrode the plugin's read-only `/agents/lead.md`. After review fixes, `git diff --check` exited 0 and `bash hooks/test/test-git-hooks.sh` passed `369 passed, 0 failed`.

### What didn't work

Running `ls -la ~/.gemini/config/` and `agy agents` inside the default terminal sandbox failed because paths under `~/.gemini/` are outside the sandbox: `ls: /Users/maragubot/.gemini/config/: Operation not permitted` and `Failed to start: open /Users/maragubot/.gemini/antigravity-cli/installation_id: operation not permitted`. `rg -n '\.codex/agents|agents/' /Users/maragubot/Developer/fabrik/.claude/worktrees/antigravity-agents/ --glob '!docs/diary/*'` also failed inside the sandbox (`zsh:1: operation not permitted: rg`), so `git grep` was used instead. Temporary symlink creation, `agy` checks, and symlink removal were run outside the sandbox only after checking that `~/.gemini/config/agents` did not exist.

### What I learned

Competing `research` reviewers caught three subtle Antigravity workflow pitfalls that static parity checks missed: `Workspace: "share"` branches from the parent session's workspace and copies uncommitted files (including any untracked diary file, and branching from `main` when `agy` opened on `main`), so `builder` must switch to its own branch before running `git reset --hard <lead-branch>` and avoid staging copied `docs/diary/` files; `manage_subagents` (`Action: "kill"`) requires targeting only the finished builder's `conversationId` rather than `kill_all`, and builders must report their worktree path alongside their branch name before branch deletion; and a lone `builder` running under `Workspace: "inherit"` when `lead` started on `main` needs to propagate `<worktree>` to `git -C`, tests, `writer`, and `code-review`'s `research` reviewers.

### What was tricky

Making sure `/.antigravity/agents/lead.md` and `/.antigravity/agents/builder.md` accurately handle both starting points in Antigravity -- `agy` opened directly in a feature worktree versus `agy` opened on `main` where `lead` creates `.claude/worktrees/<feature>` -- while cleanly removing the temporary `~/.gemini/config/agents` worktree symlink afterwards so global `agy` config isn't left dangling once the worktree is removed.

### What warrants review

- Compare `/.antigravity/agents/{lead,builder,writer}.md` against `/agents/{lead,builder,writer}.md` and `/.codex/agents/{lead,builder,writer}.toml` for semantic parity and Antigravity-specific `Workspace: "share"` / `<worktree>` guidance.
- Inspect `/AGENTS.md` and `/README.md` diffs for three-platform parity wording and the `~/.gemini/config/agents` symlink warning.

### Future work

- Once `antigravity-agents` merges into `main`, point `~/.gemini/config/agents` at `/Users/maragubot/Developer/fabrik/.antigravity/agents`.

