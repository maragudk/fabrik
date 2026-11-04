---
name: define-task
description: Define a task before work starts -- interview the user about it, agree on a goal, and agree on how to verify the goal is met. Use when the user wants to develop a new feature or start any non-trivial task, says "let's define the task", "let's brainstorm", "what should the goal be", or invokes /define-task.
license: MIT
---

# Define Task

Before anything gets built, settle three things with the user, in order.

## 1. Interview

Ask about the task until you understand what the user wants and why. Ask one question per message, and wait for the answer before you ask the next one. Read the project first (code, diary, docs), so you don't ask what it already answers. Push back on vague answers and unnecessary scope.

## 2. Goal

Propose a goal: a short statement of the outcome, not the implementation. Name what is out of scope if that isn't obvious. Refine it with the user until they agree.

## 3. Verification

Propose how to check that the goal is met. Prefer checks an agent can run, like tests, commands, or measurements. Where a check needs a human, write it as concrete steps. Every part of the goal needs at least one check, and each check must be able to fail. Refine it with the user until they agree.

## Output

End with the agreed **Goal** and **Verification**. If a diary entry is being started for the task, put both at the top of it, before the first step, so builders can work from them.
