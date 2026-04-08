# Diary: Add PO, builder, and QA subagents

Add three independent subagents to the fabrik plugin, enabling Claude to delegate to specialized roles: product ownership, implementation, and quality assurance.

## Step 1: Research subagent mechanism

### Prompt Context

**Verbatim prompt:** See issue 6.
**Interpretation:** Look at GitHub issue #6 and do what it says -- research how to create subagents in a Claude Code plugin.
**Inferred intent:** Lay the groundwork for adding subagents to the fabrik plugin.

### What I did
Researched Claude Code's subagent mechanism via documentation. Posted findings as a comment on issue #6.

### Why
The issue asked for research before implementation. Needed to understand the file format, discovery mechanism, and frontmatter fields before designing agents.

### What worked
The mechanism is straightforward: Markdown files with YAML frontmatter in an `agents/` directory, auto-discovered by Claude Code. No changes to `plugin.json` required.

### What didn't work
Nothing -- the research phase was clean.

### What I learned
Subagents in plugins cannot set `hooks`, `mcpServers`, or `permissionMode`. Agent names are namespaced under the plugin name (e.g., `fabrik:builder`). The `isolation: worktree` field gives agents their own working directory.

### What was tricky
Nothing particularly tricky at this stage.

### What warrants review
The research comment on issue #6 -- verify the documented fields and restrictions match current Claude Code behavior.

### Future work
None from this step.

## Step 2: Design and implement the three agents

### Prompt Context

**Verbatim prompt:** I want to have three subagents: PO, implementer, QA
**Interpretation:** Design and build three subagents for the fabrik plugin.
**Inferred intent:** Create specialized agents that Claude can delegate to during development workflows.

### What I did
Ran a brainstorm session to nail down the design, then created three files:
- `/agents/po.md` -- product owner, no worktree, nudged toward brainstorm/spec/design-doc/decisions skills
- `/agents/builder.md` -- builder (renamed from "implementer" during brainstorm), worktree-isolated, nudged toward go/git/diary skills
- `/agents/qa.md` -- QA critic, worktree-isolated, nudged toward code-review skill

All run on Opus. No tool or skill restrictions in frontmatter -- behavior guided by system prompts only.

### Why
The brainstorm surfaced key design decisions: independent invocation (no pipeline), worktree isolation for builder and QA, nudging over restricting, and Opus for all three.

### What worked
The brainstorm format worked well for iterating on design decisions one at a time. Keeping the system prompts short (10-15 lines each) made them easy to reason about and review.

### What didn't work
Nothing broke, but the initial name "implementer" was changed to "builder" mid-brainstorm -- a good call, it's more concise.

### What I learned
Keeping agent definitions minimal is a feature. The temptation is to over-specify tools and skills in frontmatter, but nudging via system prompt is more flexible and easier to iterate on.

### What was tricky
Balancing how much to say in the system prompts. Too little and the agent has no direction; too much and it becomes a straitjacket. Landed on brief role-setting + a few behavioral nudges.

### What warrants review
The system prompts themselves -- are they directive enough without being over-specified? Particularly the builder's TDD and diary guidance added after code review feedback.

### Future work
- Version bump and release once the PR is merged
- Test the agents in real workflows to see if the prompts need tuning
- Consider whether the PO should also run in a worktree (currently doesn't)
