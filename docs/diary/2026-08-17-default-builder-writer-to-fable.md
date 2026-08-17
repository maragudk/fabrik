# Diary: Default builder and writer sub-agents to the Fable model

Five days after #98 pinned the builder and writer sub-agents to Opus, Markus reversed course: Fable should be the default, with Opus one parameter away. The interesting part of this task wasn't the four-line change but the verification that preceded it -- the model-inheritance behavior that #98 measured no longer holds.

## Step 1: Verify how sub-agent model defaults actually behave

**Author:** main

### Prompt Context

**Verbatim prompt:** "Recently, we switched sub-agents to use Opus instead of Fable (builder/writer). I think I'd like to change the default to Fable, but still let it be settable to something else. Thoughts?" Followed after my recommendation by: "Are you sure they inherit the session model? There was no \"model\" frontmatter before, and I have a hunch they went to Opus then. Could you confirm somehow?"

**Interpretation:** Markus wanted an opinion on flipping the default back to Fable while keeping it overridable, then challenged my claim (sourced from the Agent tool's own documentation) that agents without `model` frontmatter inherit the caller's model. His hunch: pre-#98, frontmatter-less agents ran Opus, not the inherited Fable.

**Inferred intent:** Don't build the new default on an inheritance mechanism that may not exist. Confirm empirically before changing anything.

### What I did

Three rounds of evidence. First, `git show 925e450` and `/docs/diary/2026-08-12-builder-opus-model.md` -- the #98 diary records a live probe from 2026-08-12 where a control agent with no model override, spawned from a Fable caller, reported Opus, concluding "an ambient default, not inheritance". Second, two fresh probes (the frontmatter-less `fabrik:lead` and a generic `claude` agent, no override, spawned from this Fable session) both reported `claude-fable-5` -- consistent with inheritance but unable to distinguish it from an ambient default that happens to be Fable. Third, a discriminating probe: a parent pinned to `model: opus` instructed to spawn a child with no model parameter. Both reported `claude-opus-5`, proving the child inherits the caller's model rather than the session's Fable or a fixed default.

### Why

The two candidate designs were pinning `model: fable` in frontmatter versus dropping the `model` key and relying on inheritance. Which is safe depends entirely on what omission actually does, and the documentation had already been contradicted once by #98's measurements.

### What worked

The nested-parent probe design. A no-override probe from a Fable session is non-discriminating (both hypotheses predict Fable); routing the spawn through an Opus-pinned parent separates them cleanly. The #98 diary paid for itself here -- without its recorded control-probe result, Markus's hunch would have been unverifiable.

### What didn't work

Nothing failed, but the two evidence sets contradict each other: on 2026-08-12 a no-override agent from a Fable caller ran Opus; on 2026-08-17 the same experiment inherits the caller's model. Either the harness behavior changed in those five days, or the old agent-teams setup (pre-#100) behaved differently from background sub-agents. I can't distinguish those from here.

### What I learned

The behavior of *omitting* `model` frontmatter is not stable across harness versions -- it has been measured doing two different things five days apart. Any default that matters should be pinned explicitly; omission means "whatever the harness currently does".

### What was tricky

Model self-identification probes are only trustworthy when they can discriminate. The first two probes looked like confirmation but proved nothing on their own; recognizing that and constructing the Opus-parent variant was the actual work of this step.

### What warrants review

Nothing in code -- this step produced evidence. The probe results are summarized faithfully above; the raw agent replies lived only in-session.

### Future work

If a future harness change makes builders behave oddly model-wise, re-run the discriminating probe (pinned parent, no-override child) before theorizing.

## Step 2: Pin builder and writer to Fable and invert the escape hatch

**Author:** main

### Prompt Context

**Verbatim prompt:** "Let's do it"

**Interpretation:** Implement the change as scoped in conversation: flip the two frontmatter lines to Fable, invert the `lead.md` guidance sentence so Opus is the opt-down, patch version bump.

**Inferred intent:** Builders ship reviewed, merged code, and Markus is the only user paying the latency cost -- slow-and-smart is the right resting state. Opting down for an easy task is obvious in advance; opting up requires knowing a task is hard before the cheap model has botched it.

### What I did

Changed `model: opus` to `model: fable` in `/agents/builder.md` and `/agents/writer.md`. Rewrote the guidance sentence in `/agents/lead.md` to "Builders and writers run on the Fable model by default; pass `model: opus` when spawning one only if the task is simple enough that Fable's extra depth would be wasted on it." Bumped `/.claude-plugin/plugin.json` from 0.32.4 to 0.32.5. No README changes; both agents are already listed and their descriptions don't change, same reasoning as #98.

### Why

Pinning rather than omitting follows directly from Step 1: omission's meaning has shifted between harness versions, so it can't carry a default anyone relies on. The guidance sentence keeps #98's structure but inverts the polarity, naming the cost ("wasted") in the same breath as the option so leads don't downgrade by reflex -- the mirror of #98's wording, which guarded against reflexive upgrades. Patch bump because only the default of existing functionality changed.

### What worked

The change is the exact mirror of #98's, so its diary doubled as an implementation checklist -- including the "no README changes" call and the patch-versus-minor reasoning.

### What didn't work

Nothing failed at this stage.

### What I learned

Nothing new beyond Step 1's findings; this step was mechanical.

### What was tricky

Only the guidance wording: the failure mode to guard against flipped from "routine upgrades reintroduce slowness" to "routine downgrades reintroduce mediocrity", and the sentence had to push against the new one.

### What warrants review

The `lead.md` sentence's tone, as with #98. And the same validation caveat as then: the frontmatter half can only be truly exercised with the plugin installed at 0.32.5 -- spawn a builder with no `model` override and it should report Fable.

### Future work

None. If Fable builders feel too slow in practice, the escape hatch usage is the first thing to check -- and this time the escape hatch points down.
