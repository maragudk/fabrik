# factory

A Claude Code plugin marketplace (`maragu`) with a plugin (`factory`) that bundles skills, hooks, and agents.

## Structure

- `.claude-plugin/` -- marketplace.json + plugin.json (plugin version lives here)
- `skills/` -- all skills (copied from maragudk/skills)
- `hooks/` -- hooks.json + scripts (session start welcome message, AGENTS.md injection)
- `docs/diary/` -- implementation diaries

## Versioning

Bump the version in `.claude-plugin/plugin.json` after any change that should be picked up by users. Remote installs are cached by version -- without a bump, updates won't propagate.
