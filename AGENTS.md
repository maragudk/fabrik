# fabrik

A Claude Code plugin marketplace (`maragu`) with a plugin (`fabrik`) that bundles skills, hooks, and agents.

This is built for Markus's own use -- others are free to use and copy it, but design decisions don't need to accommodate other users' setups, plans, or model access.

## Structure

- `.antigravity-plugin/` -- Antigravity plugin manifest (`plugin.json`)
- `.antigravity/agents/` -- Antigravity sub-agent definitions (semantic ports of `agents/`)
- `.claude-plugin/` -- marketplace.json + plugin.json
- `.codex/agents/` -- Codex sub-agent definitions (semantic ports of `agents/`)
- `skills/` -- all skills (copied from maragudk/skills)
- `agents/` -- Claude Code sub-agent definitions (builder, lead, writer)
- `hooks.json` -- Antigravity lifecycle hooks pointing at `hooks/scripts/session-start.sh`
- `hooks/` -- `hooks.json` (Claude Code and Codex) + scripts (session start welcome message, AGENTS.md injection, git hook installation)
- `hooks/git-hooks/` -- global git hooks with secret scanning, copied to `~/.config/fabrik/git-hooks/` by the session-start hook
- `hooks/test/` -- tests for the git hooks and their installer (`bash hooks/test/test-git-hooks.sh`)
- `docs/diary/` -- implementation diaries

## Build in worktrees

Always do implementation work in a git worktree under `.claude/worktrees/`, never directly in the main project directory on `main`. Running sessions load fabrik's skills, hooks, and agents from the main checkout, so half-finished edits there leak into them immediately. When the work is done, merge it into `main` (fast-forward where possible), then remove the worktree and its branch.

## Adding a new skill, sub-agent, or hook

Sub-agent definitions exist in three platform-specific formats: Claude Code uses `agents/<name>.md`, Codex uses `.codex/agents/<name>.toml`, and Antigravity uses `.antigravity/agents/<name>.md`. Every logical sub-agent MUST exist in all three directories. When adding, removing, or changing an agent, update all three semantic versions in the same commit/PR. Keep their names, descriptions, responsibilities, and scope boundaries aligned, while translating platform-specific metadata and terminology rather than copying it literally.

When adding a new skill or sub-agent, you MUST also add a one-line entry to `README.md` in the same commit/PR -- skills go under "Available Skills", sub-agents under "Available Sub-agents". Both lists are alphabetical and use the format `- **name** - one-line description`. Each logical sub-agent gets one README entry, not one per platform format. Anything not listed in the README is invisible to anyone browsing the repo.

Lifecycle hooks live in both `hooks/hooks.json` (Claude Code and Codex) and `hooks.json` at the repo root (Antigravity); keep hook additions or changes in sync across both.

## Vendored skills

`skills/modal/` is Modal's official skill, copied verbatim from `modal skills install`. Don't edit it by hand. To refresh it, run `modal skills install -y` in an empty temporary directory and replace `skills/modal/` with the resulting `.agents/skills/modal/`. GitHub push protection rejects the example Docker token in `references/guide/existing-images.md`, so redact that one value (`dckr_pat_<your-token>`) after copying.
