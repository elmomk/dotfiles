---
name: review
description: Review uncommitted or staged changes for bugs, security issues, and code quality. Use before committing.
---

Review the current uncommitted changes in the repository.

## Steps

1. Run `git diff` and `git diff --cached` to see all changes
2. Review each changed file for:

### Correctness
- Logic errors, off-by-one, missing edge cases
- Proper error handling (no silent unwrap on user-facing data)
- Database queries use parameterized queries (no string interpolation)

### Security
- Auth checks: handlers accessing user data verify identity
- XSS: user content in HTML is escaped
- Path traversal: file ops sanitize user-provided paths
- No hardcoded secrets, API keys, or credentials
- Command injection: user input never interpolated into shell commands

### Rust quality (if Rust files changed)
- Proper use of `?` operator vs unwrap
- No unnecessary `.clone()` calls
- Consistent error types
- Borrow checker: index-based loops where needed

### Web quality (if HTML/JS files changed)
- No XSS via innerHTML with user data
- Event listeners cleaned up
- No memory leaks in animation loops

## Output

For each finding: **severity** (CRITICAL/HIGH/MEDIUM/LOW), **file:line**, **issue**, **suggested fix**.
If changes look good, say so explicitly.
