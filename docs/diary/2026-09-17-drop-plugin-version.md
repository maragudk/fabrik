# Diary: Drop the plugin version

fabrik carried a semver `version` in `/.claude-plugin/plugin.json`, and every change that should reach installs needed a bump, a tag, and a GitHub release. Markus suspected the version could go entirely. This diary covers checking that, making the change, and cleaning up the release history afterwards.

## Step 1: Check whether dropping the version breaks anything

**Author:** main

### Prompt Context

**Verbatim prompt:** I think we can actually just drop the plugin version? Check whether that breaks anything, and whether we'll just update from "main" branch then.

**Interpretation:** Investigate, don't change yet. Find out whether Claude Code accepts a plugin manifest without a version, what it then uses as the install identity, and whether auto-update follows new commits on `main`.

**Inferred intent:** Get rid of the bump-tag-release ceremony on every PR if it buys nothing.

### What I did

Read `/.claude-plugin/plugin.json` and `/.claude-plugin/marketplace.json`, grepped the repo for version references, and inspected the local plugin install state under `~/.claude/plugins/`. Spawned a docs agent to read the Claude Code plugin reference and marketplace docs. Copied the repo into the scratchpad, removed the version with `jq 'del(.version)'`, and ran `claude plugin validate .` on the copy.

### Why

Markus asked two concrete questions: does it break, and do updates follow `main`. Both are answerable from docs plus the local cache, without touching the repo.

### What worked

The local cache was the strongest evidence. The official `code-review` plugin has no version and sits under `~/.claude/plugins/cache/claude-plugins-official/code-review/` in thirteen directories named by short commit SHA, with `lastUpdated` from the same day. fabrik, by contrast, was cached as `0.35.18` with a `gitCommitSha` from before the latest merge, which is version pinning in action. The docs agent then confirmed it: `version` is optional, git sources without one resolve to the commit SHA, and "git sources with no explicit version auto-update on new commits". Validation on the versionless copy passed with only a "consider adding a version" warning.

### What didn't work

Nothing failed. One dead end: I tried to match the cached SHA `ea0a38e1d671` against the marketplace checkout of `claude-plugins-official`, but that directory is not a git repository, so the match could not be made locally. The docs settled it instead.

### What I learned

Claude Code's version resolution order is marketplace entry version, then `plugin.json` version, then commit SHA for git sources. A version field is therefore purely a pinning mechanism. A `directory` marketplace source, which is what this machine uses for fabrik, still goes through the version cache rather than reading the directory live.

### What was tricky

The March bootstrap diary recorded that a fresh remote install showed zero skills until a version bump, which read as "a version is required". That was the version cache doing its job on a stale entry, not a requirement for the field.

### What warrants review

The claim that updates follow `main` rests on the docs and on the `code-review` precedent. The real test is the next merge: `~/.claude/plugins/installed_plugins.json` should show a new commit SHA as the fabrik version after the next plugin update.

### Future work

None beyond making the change.

## Step 2: Remove the version and everything that depended on it

**Author:** main

### Prompt Context

**Verbatim prompt:** Yes please.

**Interpretation:** Make the change on a branch and open a PR, as offered.

**Inferred intent:** Ship it.

### What I did

On branch `drop-plugin-version`: removed `version` from `/.claude-plugin/plugin.json`; removed the `jq -r '.version'` read and the now-unused `PLUGIN_DIR` variable from `/hooks/scripts/session-start.sh` and changed the welcome message to "Welcome to fabrik."; dropped "with the plugin version" from the SessionStart entry in `/README.md`; removed "(plugin version lives here)" from the structure list in `/AGENTS.md`; and removed two "version bump" mentions from `/skills/improve-skill/SKILL.md`. Ran the hook to confirm it still emits valid JSON with the context payload, ran `claude plugin validate .`, and opened PR #132. Also replaced my "version bump goes in the PR" memory with a note that fabrik has no version.

Initially I replaced the Versioning section in `/AGENTS.md` with a paragraph explaining why there is no version. Markus then said "Just drop the whole versioning section in AGENTS.md", so a second commit removed the section entirely and the PR body was updated to match.

### Why

Without a version, the hook would have printed "Welcome to the fabrik vnull", and `AGENTS.md` would have instructed future agents to bump a field that no longer exists.

### What worked

Running the hook script directly and piping through `jq` was a quick end-to-end check that the JSON was still well formed after the edit.

### What didn't work

Nothing failed.

### What I learned

The versioning rules had leaked into more places than `AGENTS.md`: the README hook description, the improve-skill instructions, and my own memory. Grepping for "version" across the repo before editing was worth the noise from unrelated hits in the modal, unsloth and nanobanana skills.

### What was tricky

Deciding what to keep in `AGENTS.md`. I first wrote an explanatory note, on the theory that a future agent would otherwise add a version back. Markus preferred no section at all, which is consistent with the "don't document the absence of things" instinct.

### What warrants review

`/hooks/scripts/session-start.sh` no longer references `PLUGIN_DIR` at all. Check that nothing else in the hooks expected that variable; nothing in the repo did at the time.

### Future work

None.

## Step 3: Delete all tags and releases after the merge

**Author:** main

### Prompt Context

**Verbatim prompt:** When this is merged, let's delete all git tags and GH releases

**Interpretation:** Wait for the merge, then remove the release history that the version field had produced. Merging itself is Markus's call.

**Inferred intent:** With no versions, the 112 tags and releases are dead weight that would confuse anyone browsing the repo.

### What I did

Started a background poll on `gh pr view 132 --json state` so the merge would trigger a notification. Markus merged with "merge 132" before it fired. After `gh pr merge 132 --merge --delete-branch`, I deleted every release with `gh release delete <tag> --yes --cleanup-tag`, pushed deletions for any remaining remote tags with `git push --delete origin`, and removed local tags with `git tag -d`. Verified zero releases, zero remote tags, zero local tags.

### Why

Releases and tags only made sense as a changelog keyed on the version. Without a version they point at nothing.

### What worked

`gh release delete --cleanup-tag` removes the remote tag in the same call, so the separate remote tag deletion step found nothing left to do. The whole sweep of 112 releases ran in one loop without a single failure.

### What didn't work

Nothing failed.

### What I learned

The Bash tool caps at ten minutes, so a merge watcher started this way expires quietly. I told Markus so up front, which turned out to matter less than expected because he merged within minutes.

### What was tricky

Deleting 112 releases is irreversible, so the instruction had to be explicit before running it. Markus gave it unprompted, and the merge instruction came separately, which matched the house rule that every PR is merged by a person.

### What warrants review

The GitHub releases page and `git tag` should both be empty. If any external link pointed at a release URL, it is now dead.

### Future work

The per-version directories under `~/.claude/plugins/cache/maragu/fabrik/` will now accumulate per commit instead of per version. Claude Code does not prune them either way. Not a problem yet.

## Step 4: Remove the gomponents skill

**Author:** main

### Prompt Context

**Verbatim prompt:** Thanks. Remove the gomponents skill, there's an official one now.

**Interpretation:** Delete `/skills/gomponents` and its README entry, since an official gomponents skill has superseded the bundled copy.

**Inferred intent:** Avoid two skills with the same name competing for the same triggers.

### What I did

Grepped for references to the skill outside its own directory, removed `/skills/gomponents/SKILL.md` and the README line on branch `remove-gomponents-skill`, and opened PR #133. Markus merged it with "merge 133". No tag or release, per the change above.

### Why

Duplicate skills with the same name and overlapping descriptions would both trigger, and only one of them is maintained upstream.

### What worked

The grep showed that the datastar skill and the builder agent name a gomponents skill as a companion, but only by name. Those references now resolve to the official skill, so they needed no edit.

### What didn't work

Nothing failed.

### What I learned

This was the first PR merged under the versionless setup, and it needed no post-merge ritual at all.

### What was tricky

Nothing. This was a two-file deletion.

### What warrants review

Confirm the official gomponents skill is installed wherever fabrik is used, otherwise the datastar skill's prerequisite line points at nothing.

### Future work

None.
