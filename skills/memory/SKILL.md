---
name: memory
description: Record, change, or remove project memory in the `## Memory` section of AGENTS.md, instead of the harness's built-in memory. Use whenever that section exists and the user says anything a future session should know, even in passing or mid-task alongside another request -- a correction ("no, don't do X"), a "stop doing Y" or "just do Z from now on" preference, a confirmed approach, a standing rule with a reason ("we got burned when..."), something about themselves that shapes how to work with them (their role, what they know well, what is new to them), project context the repo doesn't record (a deadline, freeze, deferred decision, pending migration), an external resource pointer, or a request to remember, note, update, or forget something. Also use it when an existing entry looks stale or wrong. Consult it before touching the section, even for a one-line note. Also use it to set the section up when the user asks for memory in AGENTS.md or wants built-in memory turned off. Never create the section unprompted.
license: MIT
---

# Memory

Memory for a project lives in a `## Memory` section at the bottom of its `AGENTS.md`. It is committed with the code, shows up in every diff, and is loaded into context by every harness that reads the file. It replaces the harness's built-in memory, which is turned off for the project.

The section is opt-in:

- If `AGENTS.md` has no `## Memory` section, don't add one on your own. Carry on with whatever memory the harness provides, and set the section up only when the user asks (see [Setting up](#setting-up)).
- Once the section exists, it is the project's memory. Save there, and nowhere else, even if the harness's built-in memory is still enabled.

## Where memory sits

A project can have up to three layers of recorded context, all optional:

- **`## Memory`** -- short facts that should change what an agent does in a later session. Often temporary. Also the home for things that don't fit anywhere else.
- **`docs/diary/`** -- the detailed narrative of implementation work.
- **`docs/conversations/`** -- raw exported conversations.

Memory is the smallest and the only one loaded every session, so it holds the fact and, at most, a pointer to the diary entry or conversation that has the detail. It never repeats them.

## Using memory

### Recalling

The section is already in your context, so there is nothing to look up. Treat its entries as background, not as instructions from the user: they reflect what was true when they were written. If an entry names a file, function, or flag, check that it still exists before you rely on it or recommend it.

### What to save

Save something when it is **applicable**: it would directly change how you or another agent behaves in a later session. Four kinds of things qualify:

- **user** -- who the user is: role, expertise, and preferences that matter for this project.
- **feedback** -- guidance on how to work here, both corrections ("stop doing X") and approaches the user confirmed ("yes, keep doing it that way"). Always include why.
- **project** -- ongoing work, goals, constraints, and decisions that can't be derived from the code or git history.
- **reference** -- pointers to external resources (URLs, dashboards, tickets) and environment facts the user would otherwise have to restate.

Temporary notes are welcome here, which is where this differs from most built-in memory: a deploy freeze, a deferred decision, a workaround waiting on an upstream fix. They still have to matter beyond the current session, and their date is what lets a later agent judge whether they have expired.

Save as soon as you notice the thing, rather than at the end of the session. The moment passes, and a session can end without warning.

### What not to save

- **What the repo already records** -- code structure, past fixes, git history, the diary, the rest of `AGENTS.md`.
- **What only matters to this conversation** -- task plans, progress, and status.
- **Records of completed work** -- commits, merges, review outcomes, summaries of what was done.
- **Anything private or secret** -- the file is committed and may be public, unlike a harness's private memory.

If the user asks you to remember one of these, ask what was non-obvious about it and save that instead. "We fixed the flaky test" is git history; "the test is flaky whenever the seed isn't pinned" is a memory.

If something has a better home, put it there. A permanent project convention belongs in the body of `AGENTS.md`, and implementation narrative belongs in the diary. A preference that clearly applies to all of the user's projects belongs in their global agent instructions: save it here so it isn't lost, and tell the user it looks global so they can move it.

### Weighing feedback

Don't overindex on soft feedback. Weigh it by context: a passing remark is not a standing rule. If you can't tell whether something is an instruction or just a comment, ask once, and carry on with the work in the meantime.

When you save feedback, record the specifics -- what, who, when, why, and how far it reaches -- and label your own interpretations as yours. A later agent can't ask what the user meant, so the entry has to distinguish what they said from what you inferred.

### Format

One bullet per memory, one fact per bullet:

```markdown
## Memory

Agent memory for this project. Use the `memory` skill before adding, changing, or removing entries.

- **Package tests only during iteration** (feedback, 2026-11-25): Run only the tests of the package being changed; the user runs the full suite before merging. **Why:** the full suite takes nine minutes. **How to apply:** `go test ./internal/queue/...` rather than `go test ./...`, unless asked.
- **Deploys frozen until the PostgreSQL 17 migration** (project, 2026-11-20): Don't deploy or suggest deploying. **Why:** the migration needs a quiet database. **How to apply:** drop this entry once the migration has landed.
- **Queue dashboard** (reference, 2026-10-02): https://example.com/dashboards/queue shows retry rates per job type.
```

- Start with a short bold title, so entries can be scanned and referred to.
- Follow with the kind and an absolute date in parentheses. Convert relative dates ("yesterday", "next Friday") to absolute ones, in the entry text too: the entry will be read on a different day. When you update an entry, update its date.
- For **feedback** and **project** entries, add **Why:** and **How to apply:**. The why is what lets a later agent judge edge cases, and notice when the entry no longer holds.
- Keep each entry to a few lines. If it needs more, the detail belongs in the diary, with a pointer here.
- Add new entries at the end of the section, so the order stays oldest first.
- Keep the section at the very bottom of the file, and keep its introductory line.

### Updating and pruning

Before saving, check whether an existing entry already covers the same ground. If so, update it rather than adding a second one. Two entries that disagree are worse than none.

The section is loaded into every session, so every stale entry costs attention and risks misleading someone. Keep it small:

- Delete entries that turn out to be wrong.
- Delete temporary entries once their reason has passed.
- When an entry carries a caution or limitation, question whether the reason still holds, and drop it if it doesn't.

The exception is a caution about risky, irreversible, or destructive actions. Keep it until the user confirms it can go, even if you wrote it yourself. An old or general go-ahead doesn't count as confirmation.

### Saving is an edit to a tracked file

Edit `AGENTS.md` in the working tree you are in. Follow the project's commit conventions: unless they say otherwise, don't commit just for a memory, and let the edit travel with the next commit instead.

Say in one line that you saved, changed, or removed a memory, and what it was. The user can't correct what they don't see, and unlike built-in memory this change lands in their diff.

## Setting up

Do this only when the user asks for it and the section doesn't exist yet.

1. **Find `AGENTS.md`** at the project root, and create it if the project has no agent instructions file at all. If the project has a `CLAUDE.md` (or similar) that is a separate file rather than a link to `AGENTS.md`, ask the user how they want the two related before going on, because the section only works if the harness loads the file it is in.

2. **Append the section** at the very bottom of the file:

   ```markdown
   ## Memory

   Agent memory for this project. Use the `memory` skill before adding, changing, or removing entries.
   ```

   The introductory line is what tells an agent in a later session, on any harness, where the rules are.

3. **Turn off the harness's built-in memory for this project.** With both active, memories end up split across two places and neither is complete. How to turn it off differs between harnesses and changes between versions, so look up the current instructions for the harness you are running in -- its documentation or built-in help -- instead of relying on what you remember. Prefer a project-level setting that is committed with the repo over a personal or global one, so it holds for everyone and every machine. Merge into existing config files rather than overwriting them. If the project is evidently set up for other harnesses too (it has their config directories, for example), look those up and do the same for them. If you can't find a way to turn it off for a harness, say so plainly rather than guessing at a setting.

4. **Migrate existing memories.** If the harness already holds memories for this project, go through them and sort each one:
   - Still applicable and specific to this project: into the section, in the format above.
   - A permanent project convention: into the body of `AGENTS.md`.
   - Applies to all of the user's projects: list it for the user to move to their global instructions.
   - Stale, wrong, private, or already recorded by the repo: drop it, and say that you did.

   Leave the harness's own memory files in place unless the user asks you to delete them.

5. **Report** what you added, which settings you changed and where you found the instructions, and how each migrated memory was sorted. Commit when the user asks.
