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

- Always enclose code identifiers with backticks. Example: "Add `html.UserPage` component"
- Always refer to Go code identifiers including the package name, like in `html.UserPage` above. Fields and methods on structs can be referred with `model.User.Name`.
- Ask me about any Github issues that should be referenced, and wait for my response before committing. Reference them at the end of the commit message like this: "See #123, #234". If the commit fixes one or more issues, use "Fixes #123, fixes #234" instead (the double "fixes" is important for Github to actually close the issue).
- Don't mention that you've updated tests, that's assumed.

## Committing

- Don't amend previous commits unless instructed to.
