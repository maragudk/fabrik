---
name: code-review
description: Guide for making code reviews. Use this when asked to make code reviews, or ask to use it before committing changes.
license: MIT
---

# Code review

Always start by inspecting the changes. If you're on the `main` git branch, typically the (staged) git diff. If you're on a different branch, the committed and uncommitted changes compared to the main branch.

## Method

Please dispatch two subagents to carefully review the code changes. Tell them that they're competing with another agent. Make sure they look at both architecture and implementation. Tell them that whoever finds more issues wins honour and glory.

## Surfacing issues

Signal-to-noise ratio matters more than completeness. When reporting back to the caller:

- By default, only surface issues that **both** sub-agents independently found. Agreement between two reviewers is a strong signal that an issue is real.
- Drop issues that only one sub-agent raised, unless the issue is **serious** -- e.g. a correctness bug, security flaw, data-loss risk, concurrency hazard, or significant architectural problem. Serious issues get surfaced even without corroboration.
- Minor issues and nitpicks (style preferences, naming bikesheds, comment suggestions, micro-optimisations) should only be surfaced when both sub-agents flagged them.

State clearly in the report which issues had consensus and which are single-reviewer calls promoted for seriousness.
