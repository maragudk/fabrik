---
name: security-review
description: Perform a thorough security review of the project, starting from a randomly selected file. Use this skill when the user asks for a security review, security audit, vulnerability scan, or wants to check the codebase for security issues. Also trigger when the user mentions "check for vulnerabilities", "find security bugs", "OWASP", or any request related to assessing the security posture of the project.
license: MIT
---

# Security review

## Getting started

Pick a random starting point by running the bundled script:

```bash
bash scripts/random-file.sh
```

The `scripts/` directory is part of this skill, not the project repository.

Then begin a thorough security review starting from the file the script returned. The random entry point is intentional: it forces exploration of parts of the codebase that might otherwise be overlooked in a targeted review.

## Review process

Read the starting file and follow its connections (imports, callers, callees, data flow) outward. Look for security issues of any kind -- use your judgment about what matters given the codebase and technology stack.

## Reporting

After the review, produce a summary structured as:

1. **Starting point**: which file the review began from
2. **Files reviewed**: list of files examined during the review
3. **Findings**: each finding should include:
   - Severity (critical / high / medium / low / informational)
   - File and line number
   - Description of the issue
   - Suggested fix
4. **Areas not covered**: parts of the codebase that were not reached from the starting point, as a reminder for future reviews

Be honest about the scope. A single random-entry review will not cover the entire codebase -- that is by design. The idea is to run this multiple times over the life of a project, each time exploring from a different starting point.
