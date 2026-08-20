# Diary: Give the builder a post-build checklist

The builder's self-review lived in a prose paragraph that described two phases -- read the diff, then run tests and linters. Markus wanted two things added to it: a check that new code comments follow the comment rules in the language skill (builders keep writing comments that reference callers), and a second-opinion pass after self-review fixes. He also asked whether the surrounding prose should be reshaped into checklist form. This task turns the post-build phase into an explicit checklist covering review, comments, lint, tests, second opinion, diary, decisions, and the report back.

## Step 1: Brainstorm the checklist and implement it

**Author:** main

### Prompt Context

**Verbatim prompt:** "I'd like to add a checklist for the builder after it has built something that it must check (where it applies):

- Check all new code comments, if any, for adherence to the comment-specific rules in e.g. the "go" skill (because I have a problem with it frequently making comments about outer layers / calling code)
- Use the second opinion skill as a review pass after fixing stuff from self-review

Maybe we should reword some of the existing stuff to be in this checklist-shape as well?"

Refined across three follow-ups: "First point: just 'Use the code-review skill for self-review and fix the issues you agree with' / Re. tests and lint: prefer tests you introduced, then tests in the same package, then all tests with the -short flag, and only if needed, the whole test suite. Remember that CI catches bad tests too. Running lint is cheap and fine. / If codex auth fails, it should stop and report that immediately, then resume once fixed."; "Maybe broaden the codex failure to 'if the second opinion skill fails running for whatever reason, stop and...' or something liek that"; "Also, we should probably mention the second-opinion skill with the other skills mentioned further up."

**Interpretation:** Replace the builder's self-review prose with a checklist section, add the comment check and the second-opinion pass, and keep the reshaping bounded to the post-build phase rather than the whole definition.

**Inferred intent:** Make the steps a builder must not skip legible as steps. Prose invites a builder to satisfy the gist; a checklist makes each omission visible, which matters most for the checks that are easy to skip -- comment discipline and an independent review pass.

### What I did

Brainstormed the design with three multiple-choice questions (scope of the checklist shape, when the second opinion fires, how to word the comment item), then implemented in `/agents/builder.md`: replaced the self-review paragraph and the diary/decisions paragraph with a `## Before reporting back` section holding eight checklist items -- self-review via the code-review skill, the comment check, lint, tiered tests, the conditional second opinion, the diary entry, decisions, and the report. Added `second-opinion` to the companion-skills line. Ported the same section to `/.codex/agents/builder.toml` in Codex terms (parent agent instead of lead, follow-up task instead of `SendMessage`). Bumped `/.claude-plugin/plugin.json` from `0.35.0` to `0.35.1`.

### Why

The second opinion is gated on "anything beyond a small, obvious change" rather than fired every run: it costs several minutes of codex time and allowance per builder, which a one-file fix doesn't warrant. Markus took that trade knowing the judgment call is the builder's and will sometimes be wrong.

The comment item points at the language skill instead of restating its rules, so the rules stay single-sourced in `/skills/go/SKILL.md`, but it names the outward-looking-comment trap explicitly because that is the rule that actually gets broken.

The test item is tiered -- tests you introduced, their package, `-short` across the suite, full suite only if warranted -- because CI is the backstop for what a builder's local run misses. Lint stays unconditional since it is cheap.

### What worked

The brainstorm's multiple-choice questions carried preview blocks showing the literal checklist text each option would produce, so Markus was choosing between artifacts rather than descriptions. All three questions converged in one round each.

### What didn't work

Nothing failed. My first draft of the second-opinion failure handling was wrong in substance rather than mechanics: I proposed that a builder unable to run codex should note it and carry on. Markus reversed it to stop and report immediately, then resume once fixed, and then broadened it from "auth failed" to any failure mode.

### What I learned

The second-opinion skill's own description says "use only when the user explicitly asks -- do not use proactively", which reads as a conflict with a builder definition that tells it to run one. It isn't: a builder following its own definition is following an instruction, not acting proactively, and it invokes the skill by name rather than relying on description-triggered activation. Worth remembering before someone "fixes" the apparent contradiction.

### What was tricky

The stop-and-report item sits before the diary item, so a builder that halts on a broken second opinion has not written its diary entry yet -- it writes it when the lead resumes it. That ordering is deliberate: moving the diary earlier would mean writing up a review pass that hadn't happened.

The Codex port needed the failure clause translated, not copied: `SendMessage` and "the lead" are Claude Code terms, so the TOML says the parent agent sends a follow-up task.

### What warrants review

The gate wording on the second-opinion item -- whether "anything beyond a small, obvious change" lands in the right place, or whether builders will read their own work as small and obvious more often than they should. Also worth checking that the two builder definitions stayed semantically aligned; they were written from the same section but in different terms.

### Future work

The writer sub-agent has a comparable prose paragraph about reviewing its own output. If the checklist shape proves to help the builder, the same treatment is available there.
