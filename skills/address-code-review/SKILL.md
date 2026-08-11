---
name: address-code-review
description: Address code review feedback by walking through comments one at a time with the user. Use when the user has received code review comments — on a GitHub PR, in a document in the repo, or directly in conversation — and wants to work through them methodically. Also trigger when the user mentions "address review", "review comments", "PR feedback", or wants to respond to code review feedback.
license: MIT
---

# Address Code Review

Work through code review comments with the user, one comment at a time. Never present multiple comments at once.

**Critical rule:** Do not make any code changes — not a single edit — until every comment has been triaged with the user. Triage and implementation are strictly separate phases. Implementation only begins after the final comment has been discussed and a decision recorded.

**Auto-mode does not override this.** Auto-mode tells you to minimize interruptions and prefer action; this skill tells you to stop and wait for a decision after every single comment. When the two conflict, this skill wins — the user invoked it specifically to slow you down. Wait for the user's reply on each comment before moving to the next, even if it feels like you're stalling.

## Input sources

Comments may come from:

1. **GitHub PR** - Fetch inline and general comments using `gh api`
2. **Document in the repo** - Parse whatever markdown structure is found
3. **Conversation** - Comments given directly by the user

## Process

### 1. Collect feedback

- **GitHub PR**: Use GraphQL to fetch all comments in one go. Fetch inline review comments via `pullRequest.reviewThreads` and general PR comments via `pullRequest.comments`. Skip already-resolved threads (`isResolved`). Still present outdated but unresolved comments (`isOutdated`), noting to the user that the code has changed since the comment was left.
- **Document**: Read the file and extract review items.
- **Conversation**: Use the comments as provided.

### 2. Triage all comments

Walk through every comment, strictly one at a time. **No code changes during this phase.** No edits, no commits, no file writes for the fixes themselves. Only discussion and decision-recording.

For each comment:

1. Present the comment to the user.
2. Share your own assessment: agree, disagree, or propose an alternative. Explain your reasoning briefly.
3. Wait for the user to decide what to do (apply, skip, modify, etc.).
4. Record the agreed-upon action in your working notes. Do not touch the code.

For GitHub PR inline comments: immediately reply to the comment on GitHub and resolve the thread after discussion. (Replies and resolutions are not code changes — they are part of triage.)

Only after the last comment has been triaged, move on to step 3.

### 3. Apply changes

Now — and only now — implement the agreed-upon changes. Apply all agreed-upon code changes in one batch.

For GitHub PR general comments (which may contain multiple issues in one comment): post a single summary reply after all issues in that comment are addressed.

For document sources: update the document with status/progress as appropriate.

## GitHub CLI reference

| Action | Command |
|---|---|
| Fetch all comments | GraphQL query on `pullRequest.reviewThreads` (inline) and `pullRequest.comments` (general) |
| Reply to inline comment | `gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies -X POST -f body="..."` |
| Reply to general comment | `gh api repos/{owner}/{repo}/issues/{pr}/comments -X POST -f body="..."` |
| Resolve a thread | GraphQL mutation `resolveReviewThread(input: {threadId: "..."})` |
