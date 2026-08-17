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

## Pull request descriptions

- Don't include sections that mirror what CI reports. Test Plan, Quality Gates, "ran build/lint/tests, all green" status -- skip them all. CI is the source of truth; freezing a snapshot into the PR body is noise.
- Skip the "## Summary" header too -- just write the bullet points directly.
- Before merging, refresh the PR title and description so they match what actually shipped. A branch drifts as review feedback lands, leaving a title or body written for the first commit stale.

## Screenshots in pull requests

- A PR with user-facing changes gets screenshots of them in the PR description, under a `## Screenshots` heading with a short `### <what it shows>` heading per image.
- Upload them as real GitHub attachments so they survive branch cleanup. There is no API for attachments (and release assets don't fit: repos with immutable releases refuse uploads after publish), so drive github.com itself with playwright-cli signed into GitHub: open the PR description's edit form, click "Attach files", upload one image per file chooser, and collect the inserted `user-attachments` URLs (a snapshot suffices -- `eval` can be blocked in isolated sessions, and snapshots collapsing newlines doesn't matter for URLs). Then cancel the form edit -- the uploads persist -- and set the final body with `gh pr edit <n> --body-file <file>` referencing those URLs.
- The signed-in login lives in one specific persistent profile directory (a one-time headed login per machine). playwright-cli derives the profile directory from session name + working directory, so a bare `--persistent` from anywhere else -- a worktree, a differently-named session -- opens a fresh, logged-out browser. Point at the existing signed-in profile explicitly with `--profile=<path to that profile directory>`. If the browser still isn't signed in, stop and ask the user to log in -- never go looking for sessions in cookie databases, other profile directories, or running browser processes.
- Stage the images inside the repository working directory before uploading; playwright-cli refuses files from outside its allowed roots.
- A failed upload attempt consumes the file chooser -- click "Attach files" again before every retry.
- Delegate the browser-driving to a subagent handed the image paths, the PR number, and the profile path; it's mechanical ref-clicking that shouldn't consume the main conversation's context.

## Merging pull requests

- Prefer merge commits: `gh pr merge --merge`. Merge settings vary by repo -- some disallow squash merging entirely, some still use it -- so don't reach for `--squash` by default; if a merge method is rejected, check the repo's recent history for what it actually uses.
