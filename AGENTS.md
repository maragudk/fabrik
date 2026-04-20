# fabrik

A Claude Code plugin marketplace (`maragu`) with a plugin (`fabrik`) that bundles skills, hooks, and agents.

## Structure

- `.claude-plugin/` -- marketplace.json + plugin.json (plugin version lives here)
- `skills/` -- all skills (copied from maragudk/skills)
- `agents/` -- sub-agents (lead, builder, qa)
- `hooks/` -- hooks.json + scripts (session start welcome message, AGENTS.md injection)
- `docs/diary/` -- implementation diaries

## Adding a new skill, sub-agent, or hook

When adding a new skill or sub-agent, you MUST also add a one-line entry to `README.md` in the same commit/PR -- skills go under "Available Skills", sub-agents under "Available Sub-agents". Both lists are alphabetical and use the format `- **name** - one-line description`. Anything not listed in the README is invisible to anyone browsing the repo.

## Versioning

Bump the version in `.claude-plugin/plugin.json` after any change that should be picked up by users. Remote installs are cached by version -- without a bump, updates won't propagate.

New functionality (a new skill, sub-agent, hook, etc.) is a minor version bump. Changes to existing functionality are a patch version bump.

Each new version should also have a GitHub release. Create a git tag (e.g. `v0.8.0`) on the version bump commit, push it, and create a release with `gh release create`.
