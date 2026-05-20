---
name: distill-book
description: Distill a long book into a concise, structured set of learnings by processing it chapter by chapter with parallel subagents, then synthesizing the result -- optionally into a Claude Code skill. Works for any format the book comes in -- PDF, EPUB, Markdown, HTML, plain text. Use this skill whenever the user wants to summarize, distill, extract the core ideas from, or "turn into a skill" a book, ebook, manual, or other long-form document that is too large to read in one pass. Triggers include "distill this book", "summarize this book chapter by chapter", "extract the key principles from this PDF/ebook", "make a skill out of this book", or handing over a large multi-chapter document and asking what to learn from it.
license: MIT
---

# Distill a book

## The core idea

A book is too large to load into one context window and reason about well. So fan it out: split the book into chapters, hand each chapter to its own subagent that distills it in isolation, then read back the short overviews -- not the raw chapters -- and synthesize them.

The point is **context hygiene**: each subagent loads only one chapter, and the orchestrator never reads a full chapter, so the approach scales to any size of book. If you find yourself pulling raw chapter text into your own context, you've lost the benefit -- delegate it.

This skill stays deliberately high-level and format-agnostic. A book might arrive as a PDF, EPUB, Markdown, HTML, plain text, or something else; use whatever tools and methods suit that format. The workflow below is what matters, not the mechanics.

## When to use this skill

Use it when someone wants the core learnings out of a long document (book, manual, report) that's too big to read in one go -- especially when they want the result turned into a skill or a structured overview. For short documents that fit in context, just read them directly; this machinery is overkill.

## Workflow

1. **Check the source is usable, and flag problems before grinding.** Confirm you can get real, extractable text out of the document, whatever its format. Some formats need a step first -- a scanned PDF needs OCR, HTML may need its markup stripped -- while Markdown or plain text is ready as-is. Reach for the right tool for the format (for example, the `pdf` skill for PDFs). If the source won't yield usable text, say so up front rather than after a long process.

2. **Break it into chapters (or natural sections).** Read the book's own structure -- table of contents, headings -- to find the boundaries. Conventions vary wildly between books, so this is a judgment call, not a fixed rule; verify the split looks sane before spending tokens on it. If there are no clear chapters, fall back to Parts, sections, or sensible chunks, and say what you did. Usually skip front/back matter (preface, index, appendices) unless it's worth distilling.

3. **Distill each chapter in parallel.** Spawn one subagent per chapter, all in a single batch so they run concurrently. Each subagent prompt must be self-contained, and should include:
   - which chapter to read and the book/chapter title for context;
   - a **focus lens matched to the end goal** -- this matters more than anything else. For a coding skill, ask for principles and practices an engineer can actually apply (definitions, the why, concrete techniques, anti-patterns, rules of thumb), not a flat summary. For a book report, ask for narrative takeaways. The lens shapes everything downstream.
   - an instruction to **write its overview to a file and reply with only a short token** (e.g. "done ch5"). Writing to files keeps the overviews out of the orchestrator's context until you choose to read them.
   - a length target and a "don't pad" nudge.

4. **Synthesize.** Read the overviews back (they're small, but all together can be large -- page through them or use a synthesis subagent for a very large book). Then produce the deliverable: a distillation document organized by theme rather than chapter order, or -- if the goal is reusable guidance -- a skill, by handing off to the `skill-creator` skill. Distill into your own words; you generally don't need to quote the book.

5. **Clean up** any intermediate working files unless the user wants them kept.

## Keep in mind

- Subagents are independent with no shared memory -- every prompt stands alone.
- Respect copyright: this is for distilling a book the user has legitimately obtained into their own notes or tooling, not for reproducing it wholesale.
