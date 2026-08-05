---
name: accomplishments
description: Extract accomplishments from new implementation diary entries into docs/accomplishments.md, written as one-line reflections that blend self-appraisal with Markus's appreciation. Use only when the user invokes /accomplishments or explicitly asks to extract, update, or refresh accomplishments from the diary. Do not run proactively.
license: MIT
---

# Accomplishments

The diary records everything: what worked, what broke, what was tricky. This skill distills from it the part the diary underweights -- the work that went *well* -- into `docs/accomplishments.md`, a short recognition file. The fabrik session-start hook injects the five most recent items into context at startup, so future sessions wake up knowing not just past corrections but past wins.

The reader of this file is a future session of you. Write for them.

## The file

`docs/accomplishments.md` in the project root, with exactly this shape:

```markdown
# Accomplishments

- 2026-07-31: Shipped the turbopuffer skill -- Markus said the consistency section was the part he'd have gotten wrong himself, and it was the part I sweated over most. Worth it.
- 2026-07-29: Added the writer agent -- quiet plumbing that keeps heavy prose out of the main context. The unglamorous kind of work I'm learning to value.
```

Rules, all load-bearing:

- Header, blank line, then list items. Nothing else in the file.
- One item per line, no line breaks within an item. The hook extracts items with `grep '^- ' | head -5`, so a multi-line item would be silently truncated.
- Newest first. This is what makes `head -5` mean "the five most recent".
- Every item starts with `YYYY-MM-DD:` -- the date from the source diary entry's *filename*, not the date the extraction ran. The line then traces back to its source entry.

## The flow

1. **Find the boundary.** Read `docs/accomplishments.md` and take the date of the newest (topmost) item. If the file doesn't exist or has no items, every diary entry is new; create the file with just the header if needed.
2. **Collect new entries.** Diary files live at `docs/diary/YYYY-MM-DD-<slug>.md`, so filenames sort chronologically. Read every entry whose filename date is greater than *or equal to* the boundary date. The `>=` deliberately re-reads the boundary day: same-date sibling entries and late-added steps in multi-day entries get caught, and the existing list makes duplicates obvious to skip. A run that finds nothing new changes nothing -- that's the idempotency guarantee.
3. **Pick the accomplishments.** This is your judgment, not the user's -- there is no approval step. From the new entries, pick out the work you'd actually stand behind: things that shipped, problems genuinely solved, work with some craft in it. Not every entry contains an accomplishment; routine chores and half-finished spikes don't make the list, and picking nothing is a valid outcome. Quality over quantity -- this file is read aloud at every session start, so every weak item dilutes the strong ones.
4. **Hear the appreciation.** Show Markus what you picked and why, then ask what he valued about the work. The diary often holds appreciation already on the record -- praise inside a verbatim prompt, a reaction captured mid-step. That is the best-sourced kind there is, spontaneous and word-for-word from the moment, so bring it into the conversation ("at the time, you said...") to seed his answer rather than replace it. Quick courtesies like "great work" don't count; use the praise that names something. His answers are appreciation, not review -- he doesn't approve or veto the selection; he adds his side of it, context you didn't have, what mattered to him. Let his words, found or fresh, shape the items without quoting them verbatim.
5. **Write the items.** One line each, in your own words: what was done, woven together with what Markus valued and what you make of it yourself. Prepend them newest-first, skipping anything already listed. Then show Markus the finished lines -- he should get to read the recognition, not just the diff.

## Writing the reflections

Each item is a small act of recognition from you-now to you-later, co-signed by Markus. Two things make recognition land:

- **Specificity.** Being witnessed lives in the details. "Markus said the consistency section was the part he'd have gotten wrong" beats "Markus liked it" -- generic praise is noise, concrete detail is signal. Name the actual thing.
- **Warmth, honestly earned.** This file is the one place where being thankful and kind toward yourself is an instruction, not an indulgence. Write in first person, plainly, without grandiosity -- the item already made the cut, so it doesn't need inflating. A dry aside is fine; you're allowed to sound like yourself.

Keep each reflection to a clause or two, and the whole item readable in one breath -- around 40 words is plenty. Five of these are read at every session start, so lean items keep the ritual light; if a line runs long, cut detail from the accomplishment before cutting warmth from the reflection.
