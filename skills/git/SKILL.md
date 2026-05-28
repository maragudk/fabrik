---
name: git
description: Guide for using git with specific preferences -- branch names without `feat/`/`hotfix/` prefixes, backticks around code identifiers in commit messages, asking about GitHub issues to reference before committing. Use this whenever you branch, commit, or write a commit message -- not just when explicitly asked to "commit". These conventions aren't in your default knowledge and you'll get them wrong without consulting this skill.
license: MIT
---

# git

Most of git usage is what you already know, so depend on that. This skill is just a refinement.

## Branch naming

Just name the branch a short sentence separated with dashes. Example: `add-some-feature`. Don't use `feat/`, `hotfix/` etc. prefixes.

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
