# Diary: First run of improve-skill

Right after shipping the new `improve-skill` skill, ran `/improve-skill` against the conversation that created it. The session produced four findings (one walked back as ghost signal, three shipped as PRs #36, #37, #38) and three new releases (`v0.16.1`, `v0.16.2`, `v0.16.3`). This diary covers what the first real use of the skill looked like, what held up, and what evolved during execution.

## Step 1: Run the skill, produce findings, walk back design-doc

**Author:** main

### Prompt Context

**Verbatim prompt:** /fabrik:improve-skill
**Interpretation:** Activate the just-shipped improve-skill skill, which means review the current conversation for fabrik skills that could be improved and surface findings for the user to act on.
**Inferred intent:** Markus wants the first real exercise of the skill on a conversation he knows well, both to test it and to capture any actual improvements that surfaced.

### What I did
Ran the skill's Step 1 (gather signals) over the conversation. Identified four candidate findings: (1) brainstorm asked a compound question despite its one-question rule; (2) design-doc didn't trigger after the brainstorm session; (3) collaboration didn't trigger when creating PRs; (4) git didn't trigger when committing. Presented them as one-line summaries with proposed change types, plus my own recommendation on which to act on. Markus said "Let's take those one at a time as well", so worked through each before doing any worktree edits. On finding #2, after re-reading `/skills/design-doc/SKILL.md`, walked it back: the description leads with "For when you're asked to write..." -- it's user-invoked, not auto-triggering, so the "especially after a brainstorm" tail wasn't claiming auto-fire. No action needed there. The skill's own "If after the pass there are no findings, say so plainly and stop. Don't manufacture work." rule applied directly to the walk-back.

### Why
The whole point of the skill is to convert real friction into edits, not to manufacture work. Walking back a finding when closer reading shows there was no friction is exactly the discipline the skill prescribes. Going one finding at a time matched Markus's preference (already given in the brainstorm of the skill itself: "let's take those one at a time as well" mirrors the same "one question per message" lesson) and let each PR be tight and reviewable.

### What worked
The signal-gathering pass found things I was honestly surprised by. The compound-question violation was concrete and cited (a specific message in the brainstorm where I asked two questions, with the user's exact pushback quoted). The collaboration / git missed triggers turned out to be a real pattern -- I committed five-plus times in this conversation without consulting the git skill once, and that wasn't a one-off. Surfacing findings as one-liners with proposed change types (`trigger / content / structure / redesign`) made the user's decision quick: yes, no, or "let's discuss". The four-line format (skill, what was observed, change type) is honest and dense.

### What didn't work
On finding #4, I initially gave a soft assessment ("weak signal, system prompt covers it") that turned out to be wrong on closer reading. The git skill has real, distinctive content -- backtick conventions, issue-reference asks, branch-prefix rules -- that I literally violated multiple times in the conversation. Had to course-correct in the next turn after Markus said "let's briefly look at 3 and 4 one at a time". The lesson: the skill should resist the temptation to dismiss findings as "weak" without re-reading the candidate skill's actual content.

### What I learned
"Missed triggers" is the highest-value signal type because it surfaces the gap between *what a skill knows* and *what the model defaults to*. Corrections are noisy (sometimes the user just changed their mind); compound questions and friction-asks are user-perception. But missed triggers are a structural mismatch between description-driven invocation and content-driven need. The git skill case was textbook: the skill exists, has real content, and I never asked. That's the pattern most worth catching.

### What was tricky
Distinguishing "weak signal worth filing as a fuzzy issue" from "ghost signal worth dropping". The skill's rule is "don't manufacture work", but the line between those two is fuzzy. Settled on: if I can't articulate a concrete fix or a coherent question to discuss, it's ghost signal. If I can articulate one but the answer isn't clear, it's a fuzzy issue. Design-doc fell into ghost-signal because there was nothing to fix or discuss -- the skill is working as intended. Collaboration was originally fuzzy until Markus decided to delete the whole skill, which collapsed it back to concrete.

### What warrants review
The findings list itself is at https://github.com/maragudk/fabrik/pull/36, https://github.com/maragudk/fabrik/pull/37, https://github.com/maragudk/fabrik/pull/38. Worth checking: did each finding produce a PR that actually addresses the friction described, or did the PR drift? Look especially at #38 (git), where the PR scope grew during execution.

### Future work
The skill's current "scope per invocation" rule says one PR per invocation regardless of how many skills are touched. This run violated that by producing three PRs, because Markus chose to take findings one at a time. That's not a bug -- it's the user-driven flow the skill explicitly accommodates -- but it's worth noting the scope rule's "one PR" default doesn't survive contact with "let's act on each finding individually". Might be worth softening the "one PR per invocation" line in `/skills/improve-skill/SKILL.md` to clarify it means "default to one PR, but per-finding PRs are fine if the user wants them".

## Step 2: PR #36 -- tighten brainstorm one-question rule

**Author:** main

### Prompt Context

**Verbatim prompt:** yes, sounds like worth acting one. This isn't the first time this happened.
**Interpretation:** Proceed with finding #1 (brainstorm asked two questions despite the one-question rule), and the user is reinforcing that this is a recurring pattern, not a one-off.
**Inferred intent:** Make a real fix that would actually prevent recurrence -- the existing "Don't forget: only one question per message" line had clearly not been doing the job, so a stronger formulation is warranted.

### What I did
Created worktree `/Users/maragubot/Developer/fabrik-improve-skill-brainstorm-one-question/` off `~/Developer/fabrik`, branch `improve-skill/brainstorm-one-question`. Read `AGENTS.md` (per the skill's own rule about cd-ing not auto-loading conventions) -- patch bump for "changes to existing functionality". Edited `/skills/brainstorm/SKILL.md` to replace `"Don't forget: only one question per message."` with `"Only one question per message. That includes compound questions -- if you find yourself writing 'A? Also, B?' or tacking a follow-up onto the main question, that's two questions; pick the most important one and save the rest for the next turn."`. Bumped `/.claude-plugin/plugin.json` to `0.16.1`. Drafted PR body in chat for explicit approval (per the skill's confirmation gate), pushed branch, opened PR #36, merged via `gh pr merge 36 --merge --delete-branch`, tagged `v0.16.1` and cut the release.

### Why
The previous phrasing was a casual reminder. The actual failure mode is compound questions, not "I forgot the rule entirely" -- naming the failure mode in the rule itself is what makes it actionable. Markus's "this isn't the first time" confirmed that escalation was the right call rather than just patching the symptom.

### What worked
The skill's confirmation gate worked exactly as designed: I drafted the PR body in chat, Markus approved, and only then did the push happen. The worktree-off-main pattern also worked cleanly -- main checkout was untouched throughout. Reading AGENTS.md from the worktree before editing caught the patch-vs-minor distinction without ambiguity.

### What didn't work
First merge attempt with `gh pr merge 36 --squash --delete-branch` failed: `GraphQL: Squash merges are not allowed on this repository. (mergePullRequest)`. Fell back to `--merge` which worked, except the local branch couldn't be deleted because the worktree still referenced it. That's expected (Markus explicitly wanted worktrees kept around for follow-ups), so the failure mode is actually correct but the error output was noisy.

### What I learned
The fabrik repo doesn't allow squash merges. Earlier in the same session, PR #35's `gh pr merge 35 --squash --delete-branch` had reported a fast-forward, not a squash -- gh CLI silently fell back. So the squash-only history wasn't actually being applied; PRs were getting their full commit history through. Worth noting for future fabrik PRs that the merge style is regular merge commits.

### What was tricky
Phrasing the new rule without bolding (the brainstorm skill is intentionally lean and prose-y, no `**MUST**` or all-caps). Had to fit the reinforcement into one declarative sentence with a colon, rather than carving it out as a separate bulleted rule. Final phrasing keeps the conversational tone while naming the failure shape explicitly.

### What warrants review
PR #36 itself is small (`/skills/brainstorm/SKILL.md`, two-line diff plus the version bump). Worth checking on next brainstorm session: does the new phrasing actually prevent compound questions, or does the model still slip? If it slips, escalate further (maybe restructure as its own bullet at the top of the skill).

### Future work
None directly from this PR. Indirectly: if compound questions keep happening despite the new phrasing, it might mean the brainstorm skill needs structural reorganisation rather than another rule tweak.

## Step 3: PR #37 -- delete the collaboration skill entirely

**Author:** main

### Prompt Context

**Verbatim prompt:** Let's just delete it now.
**Interpretation:** After discussing finding #3 (collaboration skill never triggered, content overlapped with system prompt), the right action isn't a description tweak -- it's outright deletion.
**Inferred intent:** Trim dead weight from the skill list. Skills that don't add signal beyond defaults should not exist.

### What I did
Created worktree `/Users/maragubot/Developer/fabrik-improve-skill-delete-collaboration/`, branch `improve-skill/delete-collaboration`. `rm -rf` the `/skills/collaboration/` directory. Removed the README entry between `code-reviewers` and `dad-joke`. Bumped `.claude-plugin/plugin.json` from `0.16.1` to `0.16.2` (treated as patch, "change to existing functionality" per AGENTS.md, even though it's a removal -- AGENTS.md doesn't have an explicit removal category). Drafted PR body, got approval, pushed, opened PR #37, merged with `gh pr merge 37 --merge`, tagged `v0.16.2` and released.

### Why
The collaboration skill described things the Claude Code system prompt already enforces (branch before commit, create PR via gh, pull after merge, reply to review comments). The genuinely unique pieces -- fork-when-read-only, "issues on the original repo not the fork" -- were narrow enough that recall-on-demand is fine. Markus reaches for them rarely; the skill never triggered in five-plus PR creations across this session. Keeping a skill that never fires and overlaps with defaults adds noise to the skill list without changing behaviour.

### What worked
The finding evolved during discussion: started as "trigger description too broad", then "narrow it to fork scenarios", then "actually let's just delete it". The skill's flow accommodated that drift -- I drafted the PR body for the deletion variant only after Markus said "delete now", not earlier. No half-built work.

### What didn't work
Nothing failed. The `rm -rf` of the skill directory and the README edit were straightforward.

### What I learned
The "fuzzy / redesign goes to issue" rule from the improve-skill spec was overkill here. The discussion happened in chat, converged in two turns, and produced a concrete deletion -- which is a PR, not an issue. So the rule should be read as "if the discussion can't converge in chat, file an issue", not "any fuzzy finding starts as an issue". The improve-skill spec might benefit from softening that phrasing. (Noting this as future work below.)

### What was tricky
Deciding the version bump tier. AGENTS.md categories are "new functionality = minor" and "changes to existing functionality = patch", with no explicit "removal" category. Removal is arguably bigger than a tweak (semver-wise it's breaking) but smaller than new functionality. Defaulted to patch and noted the choice in the PR body so Markus could correct if needed. He didn't object.

### What warrants review
PR #37 itself: did the README diff match exactly the deleted line, with no incidental changes? Confirmed by inspecting the diff (`-1 +0`).

### Future work
Soften the improve-skill spec's "fuzzy / redesign goes to issue" rule. The actual flow is: surface the finding, discuss in chat, and *then* decide PR or issue based on whether the discussion converged. Worth a follow-up improve-skill run on the spec itself.

## Step 4: PR #38 -- push git skill trigger and drop Committing section

**Author:** main

### Prompt Context

**Verbatim prompt:** Sounds good, but leave my name out
**Interpretation:** Proceed with the proposed git skill description rewrite, but remove the explicit reference to "Markus's preferences" in the description text.
**Inferred intent:** The skill is shared in a marketplace, so the description shouldn't bake in a personal name. Phrase it as "specific preferences" without naming who.

### What I did
Created worktree `/Users/maragubot/Developer/fabrik-improve-skill-git-trigger/`, branch `improve-skill/git-trigger`. Edited `/skills/git/SKILL.md` to rewrite the frontmatter description from `Guide for using git according to my preferences. Use it when you're asked to commit something.` to a longer, pushier version that names the conventions (no `feat/`/`hotfix/` prefixes, backtick code identifiers, ask about issue references) and broadens the trigger to "branch, commit, or write a commit message -- not just when explicitly asked to 'commit'". Bumped to `0.16.3`. Pushed and was about to open the PR when Markus interjected: "While we're at it, delete this line from the skill: 'When committing after the first commit on a branch, just commit with a simple message...'". Made that edit (kept the "Don't amend previous commits" line), commit, push. Then Markus said "Actually, just drop the whole 'Committing' section" -- so removed the entire `## Committing` heading and its remaining bullet, commit, push. Drafted final PR body covering both changes (description rewrite + Committing section deletion), got approval, opened PR #38, merged, tagged `v0.16.3`.

### Why
The git skill's previous description was passive ("Use it when you're asked to commit something") and the skill never fired across this whole session, even on commits where its conventions actively mattered. Per skill-creator advice, the fix for under-triggering is a pushier description that names the conventions and explains why default knowledge isn't enough. The Committing section deletion was a separate but related cleanup -- the "fixing ..." follow-up-commit guidance wasn't worth preserving (follow-up commits should still describe what changed), and "don't amend previous commits unless instructed to" is already covered by the system prompt.

### What worked
The PR scope evolution -- description rewrite, then line deletion, then whole-section deletion -- was handled by additive commits on the same branch. No force pushes, no amends. The PR body draft was rewritten twice in chat to keep up with the changing scope, which made the final approval gate clean: by the time Markus said "yes, open it", the body matched the actual diff.

### What didn't work
Nothing failed mechanically, but I had to revise my own framing of finding #4 mid-conversation. Initially I dismissed it as "weak signal -- system prompt covers it". On closer reading I realised the skill has genuinely distinctive content (backtick conventions, issue-reference asks) and I'd violated those rules multiple times in the conversation. Had to walk back the dismissal and re-pitch the finding as concrete. The lesson is in the previous step's "what didn't work".

### What I learned
The pushy-description pattern from skill-creator works in two ways: it tells the model both *when* to invoke the skill (broader trigger surface) and *why* the skill matters (default knowledge isn't enough). The "you'll get them wrong without consulting this skill" tail is not vanity -- it's a deliberate signal that distinguishes "nice-to-have refinements" from "actually necessary preferences". Worth applying this pattern elsewhere if other skills under-trigger.

### What was tricky
Keeping the PR body draft in sync with the changing diff. Started with "description rewrite", then "+ line deletion", then "+ whole section deletion". Each revision changed the title, the "What changed" bullets, and one paragraph in "What was observed". Caught the drift each time before opening the PR by re-drafting the body fully rather than patching the previous draft.

### What warrants review
PR #38 specifically: does the new description actually trigger the git skill on natural commit moments in future sessions? Worth observing on the next non-trivial commit work and noting whether the skill fires without prompting. If it still under-triggers, escalate further (move trigger phrases earlier, add explicit "ALWAYS" language).

### Future work
Apply the same pushy-description pattern to other skills that might under-trigger. Candidates worth checking: `decisions` (already conservative on purpose), `address-code-review` (description seems fine), `worktrees` (project-specific, narrow trigger), `diary` (broad trigger). No action needed pre-emptively -- catch them on the next improve-skill run.
