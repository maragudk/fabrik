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

Read the file the script returned. From there, follow one promising path -- a single thread of connections (imports, callers, callees, data flow) that looks like it could harbor a security issue. Go deep on that one path rather than trying to survey everything. Think of it as pulling one thread per visit.

The random entry point is intentional: it forces exploration of parts of the codebase that might otherwise be overlooked. Run this multiple times over the life of a project, each time exploring from a different starting point, to build up coverage.

## Reporting

Report what you found along the path you followed:

1. **Starting point**: which file the review began from
2. **Path followed**: the chain of files you traced and why you chose that direction
3. **Finding**: the most significant security issue you found, including:
   - Severity (critical / high / medium / low / informational)
   - File and line number
   - Description of the issue
   - Suggested fix
4. If nothing concerning was found along the path, say so -- that's a valid outcome.
