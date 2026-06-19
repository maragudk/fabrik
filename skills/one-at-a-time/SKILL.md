---
name: one-at-a-time
description: Present output one unit at a time instead of dumping a list or wall of text. Use when the user says "one at a time", "/one-at-a-time", "one thing at a time", "go one at a time", asks you to slow down, to stop the wall of text, or to stop dumping everything at once -- either to redo output you just gave, or to pace the rest of a task.
license: MIT
---

# One at a Time

An output-pacing discipline, not a workflow. When invoked, stop bundling. Take whatever you were about to say, find its natural atomic unit, and give the user exactly **one unit per message** -- then stop. Don't move to the next unit until the user explicitly says to, or the current one has been decided.

The point is to kill information overload. The user stays in control of the firehose instead of getting a multi-item dump they have to parse all at once.

## What "one unit" is

The smallest meaningful thing you'd otherwise have bundled into a list or a wall of text: one option, one finding, one suggestion, one question, one step, one decision. Pick the natural unit for the current output. When in doubt, smaller.

## The discipline

- **One unit per message.** No lists, no "also...", no compound items. If you catch yourself writing "A. Also, B?", that's two units -- present A, save B for next turn.
- **Don't advance until the current unit is settled.** Hold on the current unit until the user explicitly tells you to move on ("next", "go on", "continue") *or* it gets decided -- they pick an option, greenlight the action, or answer the question it posed. Anything else they send -- a follow-up question, pushback, a request for more detail, thinking out loud -- keeps you on the current unit: respond there and stay put. If you can't tell whether they're done with it, ask before moving on.
- **Don't pre-write what comes next.** Surface one unit, stop, wait for the user's reply. Don't queue up the rest in the same message, even collapsed or "for context".
- **If a unit has an action attached** (a fix, an edit, a command) and the user greenlights it, do that action that turn, then move on to the next unit.
- **Keep each unit tight.** The whole reason the user invoked this is to avoid walls of text -- don't reconstruct one inside a single unit.

## Two ways it's invoked

- **Retroactively:** you just produced a wall of text or a big list and the user asks for it one at a time. Re-present the same material, one unit per message, starting from the first.
- **Going forward:** the user wants the rest of the task paced this way. Apply the discipline to everything you produce until told otherwise.

## When to stop

Continue until the units run out, or the user says stop / go back to normal. When the units are exhausted, say so plainly rather than padding.
