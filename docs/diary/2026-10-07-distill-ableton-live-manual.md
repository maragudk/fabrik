# Diary: Distill the Ableton Live 12 manual into an `ableton-live` skill

Turn the 1039-page Ableton Live 12 Reference Manual (`live12-manual-en.pdf` in the repo root, gitignored) into a fabrik skill that helps an assistant answer "how do I X in Live" and "which device for Y" questions for Markus's electronic music production on macOS.

## Step 1: Fan out, distill, synthesize

**Author:** main

### Prompt Context

**Verbatim prompt:** `/fabrik:distill-book ableton-live*.pdf`

**Interpretation:** Run the distill-book workflow on the Live manual. The glob matched nothing, but the only PDF in the repo root is `live12-manual-en.pdf`, so that is the book. The deliverable in a skills repo is a skill, not a report.

**Inferred intent:** Get a reusable, trustworthy Live 12 reference into fabrik so future sessions can give exact, device-specific, shortcut-aware answers instead of generic DAW advice.

### What I did

Extracted the PDF text with `pdftotext` (the file is pandoc/WeasyPrint-generated, so the text is clean) and read the bookmark outline with `pypdf` to get chapter page ranges. Split the 42 chapters into 33 chunks: the two giant device-reference chapters (audio effects, 139 pages; instruments, 120 pages) into three and two parts by device, and runs of tiny chapters (MPE/audio-to-MIDI/grooves/tuning, bounce/comping/stems, sync/CPU/fact sheets, accessibility/shortcuts, Max for Live) merged. Only the shortcuts chunk used `pdftotext -layout`, to keep the tables' columns.

Spawned one Opus subagent per chunk with a lens tuned to the goal: exact UI locations, macOS shortcuts, the parameters that change the sound, rules of thumb, gotchas, edition and Live 12 notes. Each wrote a Markdown overview to the scratchpad and replied with a token. Read all 33 overviews back (about 40k words), then assembled them into 14 themed reference files under `/skills/ableton-live/references/` with a small Python script that demoted headings, added a contents list, and stripped the subagents' "not covered in this chapter" meta-notes. Wrote `/skills/ableton-live/SKILL.md` by hand: mental model, a router table to the references, the dozen recipes people ask for most, a "which device" table, Live 12 features, a gotcha checklist, and essential shortcuts. Added the README entry.

### Why

The manual is far too big for one context window, and a flat summary would be useless for the actual use case. The per-chapter lens asked for operating knowledge, and the SKILL.md layer adds the judgment: what to reach for, what trips people up, where to read more.

### What worked

The pandoc-generated PDF gave clean text with no OCR or layout fixes needed. The subagents stayed well inside their word budgets and flagged when the brief named something the chapter didn't contain (plug-in latency, Granulator), which kept hallucinated content out. Concatenating the overviews into themed references rather than rewriting them preserved the detail and kept the orchestrator's work to synthesis.

### What didn't work

The concurrency cap is 20 subagents. Launching 33 in one batch returned `Concurrent subagent limit reached. You can run 20 subagents at once.` for the last 13, so those went out as slots freed. One agent (audio effects part B) reported `done 29b` after 10 seconds without writing its file; a follow-up message asking it to verify with `ls` got the real file written. I also miscounted which chunk had failed to launch and only noticed chapter 27 (clip envelopes) was missing when listing the overview directory at the end.

### What I learned

With more chunks than the cap, plan the batch in two waves from the start and verify the output directory against the chunk list before synthesis, rather than trusting the "done" tokens. A short "verify the file exists with ls before replying" line in the subagent prompt is cheap insurance.

### What was tricky

Deciding what counts as sourced. The subagents occasionally added their own knowledge (edition availability for audio-to-MIDI, where Granulator ships). I kept the ones that were flagged as such and reworded the one that stated a Suite-only claim for stem separation the manual doesn't make. SKILL.md's "Devices new in Live 12" line was trimmed to what the overviews actually support.

### What warrants review

`/skills/ableton-live/SKILL.md` is the part written from judgment rather than extraction; the recipes and the "which device" table are the places to check against how Markus actually works. The shortcut tables in `/skills/ableton-live/references/keyboard-shortcuts.md` were copied by a subagent from layout-mode text and are worth a spot check against the manual's chapter 42. The skill-creator eval loop (test prompts, with and without the skill) was not run because the session was autonomous; it is the natural next step if the skill underperforms.

### Future work

Run the skill-creator eval loop and description optimizer once Markus has tried the skill on a few real questions. Push 3 is not in this manual and would need its own source. The `.gitignore` already excludes `*.pdf`, so the source manual stays local.
