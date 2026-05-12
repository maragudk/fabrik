---
name: spec
description: Write and iterate on a project spec (docs/spec.md) that defines what the product is and why it exists. Use this skill when the user asks to create or update a spec, says "let's spec this out", or when a product decision comes up in conversation that should be captured in the spec. Also use proactively when the user is about to start building something that doesn't have a spec yet.
license: MIT
---

# Spec

The spec is the living product document. It defines _what_ to build and _why_. It does not define _how_ -- that belongs in CLAUDE.md, skills, and the code itself.

The spec lives at `docs/spec.md`. Create the `docs/` directory if it doesn't exist.

## When to use this skill

- The user explicitly asks to create or update a spec.
- A product decision comes up in conversation that should be captured. In this case, nudge: "This sounds like it belongs in the spec. Want me to add it to docs/spec.md?" If the user says no, move on.

## Creating a new spec

Follow the brainstorm pattern: one question at a time, multiple choice where possible.

### Flow

1. Walk through the spec sections one at a time. For each section, ask focused questions to draw out what the user actually wants. Don't assume -- even for projects that sound straightforward, the interesting constraints are the ones the user hasn't said yet.

2. Once all sections are covered, write the spec section by section, asking for approval after each before moving to the next.

3. Assemble approved sections into `docs/spec.md`.

## Updating an existing spec

1. Read `docs/spec.md` first.
2. Ask what the user wants to change or add.
3. Walk through just the affected sections with the same propose-and-confirm cadence.
4. Show the changes for approval before writing.

## Proactive nudge

When a product decision comes up during other work (implementation, brainstorm, etc.), suggest capturing it in the spec. If the user agrees, read the existing spec, propose where the decision fits, and show the update for approval.

## Spec structure

The spec always has these sections in this order:

```markdown
# [Project Name]

## Objective
What is this? One paragraph. Name the problem, the audience, and the core value proposition.

## Users
Who uses this and what do they care about? Describe distinct user types or personas if there are more than one.

## Features
What can users do? Organize by area. Each feature is a short description of observable behavior, not implementation detail.

## Non-goals
What this project deliberately does not do. Explicit non-goals prevent scope creep and give contributors permission to say no.

## Constraints
Hard requirements that shape decisions: regulatory, performance, compatibility, data residency, budget, etc. Only include real constraints, not preferences.

## Success criteria
How do we know this is working? Concrete, observable indicators -- not vanity metrics. "Users can complete X without Y" is better than "increase engagement".

## Open questions
Decisions not yet made. Each entry should state the question and why it matters. Remove entries as they get resolved into other sections.
```

## What does NOT belong in the spec

Implementation details belong elsewhere:

- **Tech stack, project structure, commands, code style, testing, git workflow** -- these go in CLAUDE.md or in skills. The spec should not duplicate them.
- **Architecture and system design** -- this is implementation, not product definition.
- **Task lists and timelines** -- these are project management, not product definition.

If you find yourself writing about _how_ something is built rather than _what_ it does or _why_ it matters, it doesn't belong here.

## Writing guidelines

- Be concise and specific. The spec is a reference document, not prose.
- Describe behavior from the user's perspective, not the system's internals.
- Use concrete examples over abstract descriptions. "A user searches by company name and sees matching results within 200ms" not "fast full-text search".
- Non-goals and constraints are as important as features. Spend real time on them.
