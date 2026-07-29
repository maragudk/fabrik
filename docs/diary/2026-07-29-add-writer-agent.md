# Diary: Add writer sub-agent

Add a `writer` sub-agent whose role is writing documentation and other long-form prose, so the lead and builder can delegate writing work instead of loading the ~12k-token `elements-of-style.md` into their own context.

## Step 1: Brainstorm and implement the writer agent

**Author:** main

### Prompt Context

**Verbatim prompt:** I'd like to create a "writer" agent. It's primary role should be to write documentation etc. It's main skill is the write-clearly-and-concisely skill, and used by the lead or builder to write, and not polluting their context. The writer should probably always read the whole skill and accompanying material. Let's brainstorm.

**Interpretation:** Design (via the brainstorm skill) and then add a third sub-agent to the plugin, alongside lead and builder, specialized in prose. It must always read the writing-clearly-and-concisely skill and its `elements-of-style.md` in full.

**Inferred intent:** Keep the token-heavy writing material out of the lead's and builder's context by giving that job to a dedicated agent, the same way builder keeps implementation out of the lead's context.

### What I did

Brainstormed the design with Markus, one question at a time, then implemented it:

- Created `/agents/writer.md`: a teammate for lead/builder that is also directly invokable. Its mandatory first action is reading the writing skill and `elements-of-style.md` in full. It takes a brief (what, audience, purpose, pointers), researches the source material itself, writes or revises files directly, and reports back a short pointer -- never the prose itself.
- Updated `/agents/lead.md`: spawn a writer teammate for documentation and prose deliverables instead of writing them itself or leaving them to a builder.
- Updated `/agents/builder.md`: hand documentation accompanying a change to a writer teammate, then review and commit its output.
- Added the `writer` entry to the "Available Sub-agents" list in `/README.md`.

### Why

The writing skill warns that `elements-of-style.md` costs ~12,000 tokens and suggests dispatching a subagent when context is tight. The writer agent turns that suggestion into a named, reusable role with a clear contract, so the material is always read in full but only ever by the agent that needs it.

### What worked

The brainstorm converged quickly with four multiple-choice decisions: teammate + direct use, deliver by writing files and reporting briefly, brief + own research, and leaving changes uncommitted for the caller to review.

### What didn't work

Nothing failed; the change is additive and touched no existing behavior.

### What I learned

Markus chose to have the writer leave its changes uncommitted, against my recommendation to commit. The rationale: the caller reviews prose the same way builder code is reviewed before it lands, and the writer never touching git state keeps the contract simple.

### What was tricky

Placement of the delegation guidance: lead's mention sits with the builder-spawning guidance, and builder's sits before self-review, since documentation is usually written near the end of implementation but must be reviewed and committed by the builder itself.

### What warrants review

Read `/agents/writer.md` as a prompt: does the input contract (brief with audience and purpose), the no-commit rule, and the "report is a pointer, not a copy" instruction come through unambiguously? Also check the two-sentence additions to `/agents/lead.md` and `/agents/builder.md` read naturally in context.

### Future work

Version bump to 0.28.0 with tag and GitHub release after the PR merges (Markus decides when).

## Step 2: First live run of the writer

**Author:** main

### Prompt Context

**Verbatim prompt:** Use the writer to check the readme

**Interpretation:** After reloading plugins, spawn the new writer sub-agent with a brief to review `/README.md` for accuracy and clarity -- its first live run.

**Inferred intent:** Test that the writer's contract (brief in, full skill read, own research, uncommitted edits, pointer report back) works in practice, on a real task.

### What I did

Spawned the writer with a brief (what, audience, purpose, pointers per its contract). It verified all 31 skill entries and all three sub-agent entries in `/README.md` against the repo, found one gap -- the Usage section told forkers to customize hooks without the README saying what they were -- and added an "Available Hooks" section documenting the SessionStart hook. I reviewed the diff and committed it.

### Why

A fresh agent definition is untested until it runs; the README check was a well-scoped first task that exercises every part of the contract.

### What worked

The whole contract held: the writer researched the repo itself, edited the file directly, left it uncommitted, and reported a short pointer with what it verified and what it changed -- no prose in the report. It even flagged that the change warrants a patch bump per repo convention.

### What didn't work

Nothing failed. One surprise: spawning it with `run_in_background: false` still ran it in the background, because `background: true` in its frontmatter wins.

### What I learned

The report-is-a-pointer instruction produces a genuinely useful review artifact: a list of claims verified, not just changes made. That made the caller-side review fast.

### What was tricky

Nothing -- the task was deliberately small.

### What warrants review

The new "Available Hooks" section in `/README.md`: one four-line addition; check the SessionStart description against `/hooks/hooks.json`.

### Future work

None. Markus decided the README addition doesn't warrant a patch bump; it rides along with the next release.
