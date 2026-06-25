---
name: writing-clearly-and-concisely
description: Use when you write or revise a long-form document an audience will read—documentation, a README, a how-to or user guide, a spec, a design or decision doc, a blog post, a proposal, an announcement, or a standalone report or summary written for a person. Such writing should be clear, concrete, and tight, so draft it from the start by Strunk's Elements of Style (active voice; definite, specific, concrete words; omit needless words) instead of first-draft sprawl. Do NOT fire for short or code-adjacent text—commit messages, PR descriptions, release notes or changelogs, error messages, UI strings, code comments, config, version bumps, quick internal scratch notes, or the implementation diary. These exclusions win even when the text reaches an audience: a release note, changelog, or PR description is a working artifact, not a document drafted for readers.
---

# Writing Clearly and Concisely

## Overview

William Strunk Jr.'s *The Elements of Style* (1918) teaches you to write clearly and cut ruthlessly.

**WARNING:** `elements-of-style.md` consumes ~12,000 tokens. Read it only when writing or editing prose.

## When to Use This Skill

Use this skill when you write or revise a long-form document an audience will read:

- Documentation, README files, how-to and user guides
- Specs, design docs, decision docs
- Blog posts, proposals, announcements
- A standalone report or summary written for a person
- Editing any of the above to improve clarity

**If you're drafting a document an audience will read, use this skill.**

## When NOT to Use This Skill

Skip it for short or code-adjacent text—these aren't prose written for an audience:

- Commit messages, PR descriptions, release notes or changelogs
- Error messages, UI strings, code comments
- Config, version bumps, code, tests
- Quick internal scratch notes
- The implementation diary—it's agent context memory, not a document for readers

These exclusions win even when the text reaches an audience. A release note, changelog, or PR description is a working artifact, not a document drafted for readers—don't fire just because someone will read it.

## Limited Context Strategy

When context is tight:
1. Write your draft using judgment
2. Dispatch a subagent with your draft and `elements-of-style.md`
3. Have the subagent copyedit and return the revision

## All Rules

### Elementary Rules of Usage (Grammar/Punctuation)
1. Form possessive singular by adding 's
2. Use comma after each term in series except last
3. Enclose parenthetic expressions between commas
4. Comma before conjunction introducing co-ordinate clause
5. Don't join independent clauses by comma
6. Don't break sentences in two
7. Participial phrase at beginning refers to grammatical subject

### Elementary Principles of Composition
8. One paragraph per topic
9. Begin paragraph with topic sentence
10. **Use active voice**
11. **Put statements in positive form**
12. **Use definite, specific, concrete language**
13. **Omit needless words**
14. Avoid succession of loose sentences
15. Express co-ordinate ideas in similar form
16. **Keep related words together**
17. Keep to one tense in summaries
18. **Place emphatic words at end of sentence**

### Section V: Words and Expressions Commonly Misused
Alphabetical reference for usage questions

## Bottom Line

Drafting a document an audience will read? Read `elements-of-style.md` and apply the rules. Low on tokens? Dispatch a subagent to copyedit with the guide.
