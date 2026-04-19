# fabrik

A Claude Code plugin marketplace (`maragu`) with a plugin (`fabrik`) that bundles skills, hooks, and agents.

## Structure

- `.claude-plugin/` -- marketplace.json + plugin.json (plugin version lives here)
- `skills/` -- all skills (copied from maragudk/skills)
- `agents/` -- sub-agents (lead, builder, qa)
- `hooks/` -- hooks.json + scripts (session start welcome message, AGENTS.md injection)
- `docs/diary/` -- implementation diaries

## Versioning

Bump the version in `.claude-plugin/plugin.json` after any change that should be picked up by users. Remote installs are cached by version -- without a bump, updates won't propagate.

Each new version should also have a GitHub release. Create a git tag (e.g. `v0.8.0`) on the version bump commit, push it, and create a release with `gh release create`.
