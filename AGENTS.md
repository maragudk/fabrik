# fabrik

A Claude Code plugin marketplace (`maragu`) with a plugin (`fabrik`) that bundles skills, hooks, and agents.

This is built for Markus's own use -- others are free to use and copy it, but design decisions don't need to accommodate other users' setups, plans, or model access.

## Structure

- `.claude-plugin/` -- marketplace.json + plugin.json
- `.codex/agents/` -- Codex sub-agent definitions (semantic ports of `agents/`)
- `skills/` -- all skills (copied from maragudk/skills)
- `agents/` -- Claude Code sub-agent definitions (builder, lead, writer)
- `hooks/` -- hooks.json + scripts (session start welcome message, AGENTS.md injection)
- `docs/diary/` -- implementation diaries

## Adding a new skill, sub-agent, or hook

Sub-agent definitions exist in two platform-specific formats: Claude Code uses `agents/<name>.md`, while Codex uses `.codex/agents/<name>.toml`. Every logical sub-agent MUST exist in both directories. When adding, removing, or changing an agent, update both semantic versions in the same commit/PR. Keep their names, descriptions, responsibilities, and scope boundaries aligned, while translating platform-specific metadata and terminology rather than copying it literally.

When adding a new skill or sub-agent, you MUST also add a one-line entry to `README.md` in the same commit/PR -- skills go under "Available Skills", sub-agents under "Available Sub-agents". Both lists are alphabetical and use the format `- **name** - one-line description`. Each logical sub-agent gets one README entry, not one per platform format. Anything not listed in the README is invisible to anyone browsing the repo.
