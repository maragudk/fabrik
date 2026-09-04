---
name: git
description: Guide for using git with specific preferences -- backticks around code identifiers in commit messages, asking about GitHub issues to reference before committing. Use this whenever you commit, write a commit message, or work with pull requests -- not just when explicitly asked to "commit". These conventions aren't in your default knowledge and you'll get them wrong without consulting this skill.
license: MIT
---

# git

Most of git usage is what you already know, so depend on that. This skill is just a refinement.

## Commit messages

- Keep them concise and easily readable for someone who isn't intimately familiar with the change. The reader is a future teammate (or future you) skimming `git log`, not a reviewer studying the diff. Lead with what changed in plain language; skip implementation play-by-play, rationale chains, and trivia. If deeper context is worth capturing, that's what the diary is for -- see the [[diary]] skill -- not the commit message.
- Always enclose code identifiers with backticks. Example: "Add `html.UserPage` component"
- Backticks are command substitution in the shell, so a backtick in a double-quoted `git commit -m "..."` gets *executed* and silently dropped from the message -- e.g. ``-m "Add `html.UserPage`"`` tries to run `html.UserPage` and commits "Add ". Protect them: write the message with a single-quoted here-doc (`-F -` reading a `<<'EOF'` block), pass a single-quoted `-m '...'`, or escape each backtick as `` \` ``. The here-doc is the most reliable for multi-line messages.
- Always refer to Go code identifiers including the package name, like in `html.UserPage` above. Fields and methods on structs can be referred with `model.User.Name`.
- Ask me about any Github issues that should be referenced, and wait for my response before committing. Reference them at the end of the commit message like this: "See #123, #234". If the commit fixes one or more issues, use "Fixes #123, fixes #234" instead (the double "fixes" is important for Github to actually close the issue).
- Don't mention that you've updated tests, that's assumed.

## Creating pull requests

- Assign Markus as reviewer by default: `gh pr create --reviewer markuswustenberg` (or `gh pr edit <n> --add-reviewer markuswustenberg` for an existing PR).

## Pull request descriptions

- Don't include sections that mirror what CI reports. Test Plan, Quality Gates, "ran build/lint/tests, all green" status -- skip them all. CI is the source of truth; freezing a snapshot into the PR body is noise.
- Skip the "## Summary" header too -- just write the bullet points directly.
- Before merging, refresh the PR title and description so they match what actually shipped. A branch drifts as review feedback lands, leaving a title or body written for the first commit stale.

## Screenshots for pull requests

- A PR with user-facing changes gets screenshots of them. Don't upload them to GitHub; publish them as a private Artifact in the session instead, one Artifact per PR.
- Build a single HTML page titled after the PR, with a short heading per image saying what it shows, and the images embedded as data URIs (the Artifact sandbox blocks external image URLs). Keep the total page under 16 MB; downscale or JPEG-encode large captures if needed.
- Publish it with the Artifact tool. Artifacts are private by default; don't share it more widely unless asked.
- Put a `## Screenshots` section in the PR description linking to the Artifact URL, rather than embedding images in the body.
- Redeploy to the same file path (same URL) when screenshots change during review, so the link in the PR stays valid.

## Merging pull requests

- Prefer merge commits: `gh pr merge --merge`. Merge settings vary by repo -- some disallow squash merging entirely, some still use it -- so don't reach for `--squash` by default; if a merge method is rejected, check the repo's recent history for what it actually uses.
- After a merge, clean up local state: pull the main branch in the project directory, remove any worktree used for the work (`git worktree remove <path>`), and delete the merged local branch. Don't leave stale branches and worktrees lying around for the next session to trip over.
