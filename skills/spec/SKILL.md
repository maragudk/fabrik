---
name: spec
description: Propose, agree, and write changes to a project's spec -- a short document, by default `docs/spec.md`, that holds only what the user and the agent working with them have explicitly agreed -- and to any other document the project says is treated the same way. Use whenever you are about to add to, change, or remove from such a document, even a single word; when the user says "let's put that in the spec", "add it to the spec", "is that in the spec?", or "should the spec say..."; when a sub-agent's work finds the spec silent on something, contradicting itself, or ruling out what the work needs; and when the user asks to start a spec. Consult it before touching the file. Not for ordinary documentation (README, guides, the diary, to-do notes) or for just reading the spec at the start of work.
license: MIT
---

# Spec

A project's spec is a short document, by default `docs/spec.md`, that holds only what the user and the agent working with them have explicitly agreed. It states what the product is and guarantees. Agents may own the code, but the user and the agent own the spec together, so no word of it changes without the user. A project can name further documents that work the same way (in its `AGENTS.md`, for example); everything here applies to them too.

## Starting a spec

Create a spec only when the user asks for one. Never create it unprompted. The file opens by stating its own rule:

```markdown
# Spec

This document holds only what <user> and <agent> have explicitly agreed to write here. Nothing is added or changed without that agreement. Keep it concise.
```

Use the user's name and your own. Then fill it the way any change is made, below.

## Making a change

1. **Check that it belongs** (see the next section). If it doesn't, say where it goes instead and put it there.
2. **Propose the exact wording** in a quote block, with where it goes, and ask for agreement:

   > Under **Storage**, after **Backups are daily**:
   >
   > > **Deleted data is gone after 30 days.** A deleted record can be restored for 30 days. After that, it is removed from the database and from backups.
   >
   > Agree to that wording?

3. **Revise until the user says yes.** They may reword it, add to it, or ask for it shorter, over several rounds. Show the full revised sentence each time, not a description of the change.
4. **Write it verbatim** once they agree explicitly. Don't polish it on the way in; a better word is a new proposal.

Put one change to the user at a time, and wait for the answer before raising the next. If an answer is vague, covers two proposals at once, or could mean something other than what you proposed, it is not agreement: ask what was agreed. Removing or rewording an entry, including one of your own, goes through the same steps.

## What belongs in it

Agreed rules about what the product is and guarantees: behaviour a user can rely on, architecture and formats that are expensive to change, and goals. Each entry is a bold short name followed by one to a few sentences, grouped under a few headings.

```markdown
## Storage

- **Deleted data is gone after 30 days.** A deleted record can be restored for 30 days. After that, it is removed from the database and from backups.
```

Before proposing, ask yourself: would the user call this a spec thing, or is it too low-level? These belong elsewhere:

- **Implementation detail and how something was done** -- read from the code, its tests, and the diary.
- **What is agreed but not built, and open design questions** -- in the project's to-do document.
- **A running list of what is supported or planned** -- in a roadmap.

The spec is read at the start of work on the project, so keep it short. When an entry grows, propose splitting its detail out to where it belongs.

## The spec is the newest word

Where the spec and an older conversation, note, or document differ, the spec holds. When the spec changes, bring the README, site, to-do entries, and anything else that restates the rule into line with it, as a follow-up job. Never change the spec to match them.

If the work turns out to need something the spec rules out, that is not a detail to decide alone. Stop that part of the work and bring it to the user as a proposed change.

## Who edits it

Only the agent talking with the user, and only after the user agrees. Builders, writers, and other sub-agents never edit the spec. When one finds it silent or contradictory, or in the way of the work, it says so in its report and includes a proposed sentence; the agent talking with the user takes that to the user as a proposal. When you brief a sub-agent on a project with a spec, tell it this.
