---
name: address-code-review
description: Address code review feedback by walking through comments one at a time with the user. Use when the user has received code review comments — on a GitHub PR, in a document in the repo, in review.jsonl, or directly in conversation — and wants to work through them methodically. Also trigger when the user mentions "address review", "review comments", "PR feedback", "review.jsonl", or wants to respond to code review feedback.
---

# Address Code Review

Work through code review comments with the user, one comment at a time. Never present multiple comments at once.

**Critical rule:** Do not make any code changes — not a single edit — until every comment has been triaged with the user. Triage and implementation are strictly separate phases. Implementation only begins after the final comment has been discussed and a decision recorded.

## Input sources

Comments may come from:

1. **`review.jsonl`** - A JSONL file at the repo root. Each line is a JSON object: `{"base":"<sha>","comment":"...","compare":"<sha>","endLine":45,"file":"main.go","startLine":42}`
2. **GitHub PR** - Fetch inline and general comments using `gh api`
3. **Document in the repo** - Parse whatever markdown structure is found
4. **Conversation** - Comments given directly by the user

When no explicit source is specified, check for `review.jsonl` at the repo root first. If it exists, use it.

## Process

### 1. Pull latest

Always run `git pull` first. The `review.jsonl` file (or other review artifacts) may have been pushed from elsewhere and not yet present locally.

### 2. Collect feedback

- **`review.jsonl`**: Read the file. Each line is one comment. Parse the JSON to get the file path, line range, and comment text. Use `base` and `compare` SHAs for context if needed.
- **GitHub PR**: Use GraphQL to fetch all comments in one go. Fetch inline review comments via `pullRequest.reviewThreads` and general PR comments via `pullRequest.comments`. Skip already-resolved threads (`isResolved`). Still present outdated but unresolved comments (`isOutdated`), noting to the user that the code has changed since the comment was left.
- **Document**: Read the file and extract review items.
- **Conversation**: Use the comments as provided.

### 3. Triage all comments

Walk through every comment, strictly one at a time. **No code changes during this phase.** No edits, no commits, no file writes for the fixes themselves. Only discussion and decision-recording.

For each comment:

1. Present the comment to the user.
2. Share your own assessment: agree, disagree, or propose an alternative. Explain your reasoning briefly.
3. Wait for the user to decide what to do (apply, skip, modify, etc.).
4. Record the agreed-upon action in your working notes. Do not touch the code.

For GitHub PR inline comments: immediately reply to the comment on GitHub and resolve the thread after discussion. (Replies and resolutions are not code changes — they are part of triage.)

Only after the last comment has been triaged, move on to step 4.

### 4. Apply changes

Now — and only now — implement the agreed-upon changes.

For `review.jsonl` sources, for each addressed comment:
1. Apply the code change.
2. Remove the addressed line from `review.jsonl`.
3. If `review.jsonl` is now empty, delete the file.
4. Commit the code fix and the `review.jsonl` update together.

For other sources, apply all agreed-upon code changes in one batch.

For GitHub PR general comments (which may contain multiple issues in one comment): post a single summary reply after all issues in that comment are addressed.

For document sources: update the document with status/progress as appropriate.

## GitHub CLI reference

| Action | Command |
|---|---|
| Fetch all comments | GraphQL query on `pullRequest.reviewThreads` (inline) and `pullRequest.comments` (general) |
| Reply to inline comment | `gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies -X POST -f body="..."` |
| Reply to general comment | `gh api repos/{owner}/{repo}/issues/{pr}/comments -X POST -f body="..."` |
| Resolve a thread | GraphQL mutation `resolveReviewThread(input: {threadId: "..."})` |
