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

Read the starting file and follow its connections (imports, callers, callees, data flow) outward. As you explore, look for issues across these categories:

### Input validation and injection
- SQL injection, command injection, template injection, path traversal
- Unsanitized user input reaching sensitive operations
- Missing or insufficient input validation at system boundaries

### Authentication and authorization
- Hardcoded credentials, API keys, or secrets in source code
- Missing or broken access control checks
- Insecure session management, weak token generation

### Data exposure
- Sensitive data logged, leaked in error messages, or returned in API responses
- Missing encryption for data at rest or in transit
- Overly permissive file permissions or directory listings

### Dependency and configuration risks
- Known vulnerable dependencies (check go.sum, package-lock.json, requirements.txt, etc.)
- Insecure default configurations
- Debug modes or development settings left enabled

### Cryptographic issues
- Use of weak or deprecated algorithms
- Improper random number generation for security-sensitive operations
- Missing integrity checks

### Concurrency and resource management
- Race conditions that could lead to security issues
- Missing rate limiting on sensitive endpoints
- Resource exhaustion vectors (unbounded allocations, missing timeouts)

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
