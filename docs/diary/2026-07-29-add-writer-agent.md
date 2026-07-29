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
