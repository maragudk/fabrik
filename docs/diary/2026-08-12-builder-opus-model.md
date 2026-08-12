# Diary: Default builder and writer sub-agents to the Opus model

Markus finds Fable too slow for builder runs without a matching quality gain. The builder and writer sub-agents have no `model` frontmatter, so they inherit the caller's model -- typically Fable, since the lead runs on it. This task makes Opus the default for both, with a documented per-spawn escape hatch back to Fable.

## Step 1: Requirements refinement and mechanism verification

**Author:** lead

### Prompt Context

**Verbatim prompt:** "I'd like to change the builder subagent to generally (always?) use the Opus model. Fable is really slow, and I haven't seen the output be considerably better. Frontmatter change, or guidance for the lead (who is generally Fable) who can upgrade to Fable for the builder if needed?" Followed mid-turn by: "Also test briefly that overriding the model is actually possible"

**Interpretation:** Markus wants builder runs to stop defaulting to Fable. He posed two implementation options -- a `model` frontmatter change on the agent definition, or prose guidance telling the lead to pass a model override when spawning -- and asked for a recommendation. The follow-up asked for a quick empirical check that per-spawn model overrides actually work before we document them.

**Inferred intent:** Faster iteration on everyday builder work without losing the option of top-tier capability for genuinely hard tasks. The change should be reliable (not dependent on an agent remembering guidance) and cheap to maintain.

### What I did

Read `/agents/builder.md`, `/agents/lead.md`, and `/agents/writer.md` -- none set `model` in frontmatter, so all inherit the caller's model. Recommended the frontmatter approach and confirmed with Markus via a structured question: `model: opus` frontmatter on both builder and writer, plus one sentence in `lead.md` documenting the `model: fable` per-spawn override for hard tasks. Created worktree `builder-opus-model`, spawned two probe agents to verify the override mechanism (one with an explicit `model: opus` override, one control with no override), and started this diary.

### Why

Frontmatter is deterministic -- every spawn gets Opus regardless of who spawns it -- while guidance-only keeps the slow default and depends on a Fable lead remembering to downgrade, which is the status quo failure mode. The Agent tool's `model` parameter takes precedence over agent-definition frontmatter, so the escape hatch exists mechanically; the `lead.md` sentence just makes leads aware of it. The probes verify that precedence claim empirically before we document it.

### What worked

The requirements conversation converged in one round: Markus accepted both recommendations (frontmatter + lead note, and including the writer in scope).

### What didn't work

Nothing failed at this stage.

### What I learned

Neither builder nor writer ever specified a model -- the Fable slowness was pure inheritance from the lead, not a deliberate choice anyone made.

### What was tricky

Testing the *frontmatter* half of the change in-session is not feasible: the `fabrik:builder` agent definition used by the Agent tool comes from the installed plugin, not from this worktree's edited files. The probes therefore test the override mechanism (the `model` parameter on spawn), which is the half that needs empirical confirmation; frontmatter model selection is standard Claude Code behavior.

### What warrants review

The exact wording of the `lead.md` sentence -- it should prompt the lead to consider Fable for hard tasks without inviting routine upgrades that reintroduce the slowness.

### Future work

If Opus builders ever underperform on a hard task, the escape hatch usage (or lack of it) would be the first thing to check.

## Step 2: Verify the model override mechanism

**Author:** lead

### Prompt Context

**Verbatim prompt:** "Also test briefly that overriding the model is actually possible"

**Interpretation:** Before documenting a `model: fable` escape hatch in `lead.md`, empirically confirm that the Agent tool's `model` parameter actually selects the requested model on spawn.

**Inferred intent:** Don't ship documentation that promises a mechanism nobody has seen work.

### What I did

Spawned three trivial probe agents that each self-report their model in one line: one with `model: opus`, one with no override (control), one with `model: fable`. Results: the `opus` probe reported Claude Opus 5, the `fable` probe reported Claude Fable 5, and the control -- expected to inherit Fable from the lead -- reported Claude Opus 5.

### Why

The frontmatter half of the change is standard Claude Code behavior and cannot be exercised in-session anyway (the installed plugin's agent definitions are used, not this worktree's files). The override half is what `lead.md` will promise, so that's what needed a live check.

### What worked

Both explicit overrides selected exactly the requested model, in both directions. The Fable result also proves the self-report method discriminates -- the probes aren't all just claiming Opus regardless.

### What didn't work

Nothing failed, but the control probe surprised: with no `model` set, the generic subagent ran Opus rather than inheriting the lead's Fable. The two first probes were therefore non-discriminating on their own; the third probe resolved that.

### What I learned

Subagent model defaults without frontmatter are ambient and not a reliable parent-inheritance -- which strengthens the case for pinning `model: opus` explicitly rather than relying on whatever the harness happens to default to.

### What was tricky

Model self-identification is only trustworthy because the harness tells agents their model; the discriminating Fable result is what makes the whole probe set credible.

### What warrants review

Nothing in code yet -- this step produced evidence, not changes.

### Future work

None beyond the implementation step that follows.

## Step 3: Pin builder and writer to Opus and document the escape hatch

**Author:** builder

### Prompt Context

**Verbatim prompt** (the lead's brief, quoting its Goal and Requirements; the process instructions about diary, git conventions, and not pushing are omitted): "Builder and writer sub-agents currently have no `model` frontmatter, so their model is whatever the harness ambiently defaults to (often Fable via the lead -- slow, with no evident quality gain). Make Opus their explicit default, with a documented per-spawn escape hatch back to Fable. 1. `agents/builder.md`: add `model: opus` to the YAML frontmatter (alongside `name`, `description`, `background`). 2. `agents/writer.md`: add `model: opus` to the YAML frontmatter, same way. 3. `agents/lead.md`: add one sentence where builder spawning is discussed (the paragraph starting "Do not implement the work yourself" or the "One builder is often enough" paragraph -- your judgment) saying that builders and writers run on the Opus model by default, and the lead can pass `model: fable` when spawning one for a genuinely hard task. The wording should prompt the lead to *consider* Fable for hard tasks without inviting routine upgrades that reintroduce the slowness. Keep it to one sentence. 4. `.claude-plugin/plugin.json`: bump the patch version (this is a change to existing functionality, not new functionality). 5. No README changes -- both agents are already listed and their descriptions don't change."

**Interpretation:** Implement the change the lead and Markus agreed on, exactly as scoped: two frontmatter lines, one sentence of lead guidance, one patch version bump, no README edit.

**Inferred intent:** Make the Opus default automatic rather than something an agent has to remember, while leaving Fable one parameter away for the rare task that warrants it.

### What I did

Added `model: opus` as the fourth frontmatter key in `/agents/builder.md` and `/agents/writer.md`, after `background: true`. Appended one sentence to the "One builder is often enough" paragraph in `/agents/lead.md`: "Builders and writers run on the Opus model by default; pass `model: fable` when spawning one only if the task is hard enough to be worth Fable's slower pace." Bumped `/.claude-plugin/plugin.json` from `0.32.1` to `0.32.2`.

### Why

Frontmatter carries the default, so no agent has to remember it. The lead sentence went into the spawn-decision paragraph rather than the "Do not implement the work yourself" paragraph because that paragraph is already about *how to spawn* -- how many builders -- which makes the model choice a natural neighbour, whereas the earlier paragraph is about the lead's own boundaries. Phrasing it as "only if the task is hard enough to be worth Fable's slower pace" names the cost of the upgrade in the same breath as the option, which is what discourages reaching for it by reflex. The version bump is a patch because both sub-agents already existed; only their default model changed.

### What worked

The change is four lines across four files, and the lead's brief left nothing to guess at. `python3 -c "import json; json.load(...)"` confirmed the bumped `plugin.json` still parses.

### What didn't work

Nothing failed.

### What I learned

`gh issue list` returns nothing for this repo -- there are no open issues, so the git skill's "reference the relevant issue" step has nothing to attach here, and recent commits confirm the convention (they reference PRs via merge commits, not issues).

### What was tricky

The one placement wrinkle: the sentence mentions writers two paragraphs before `lead.md` introduces the writer teammate. Splitting it into two sentences in two paragraphs would have broken the one-sentence constraint, and a lead reading top to bottom reaches the writer paragraph moments later, so the forward reference is cheap.

### What warrants review

The `lead.md` sentence's tone -- whether "only if the task is hard enough to be worth Fable's slower pace" pushes hard enough against routine upgrades -- and its placement in the spawn-count paragraph rather than the one above it. Everything else is mechanical. To validate the frontmatter half, the plugin has to be installed at `0.32.2` and a builder spawned with no `model` override; it should report Opus.

### Future work

None. If the escape hatch turns out to be either never used or used constantly, that's the signal to revisit the wording.
