---
name: audit
description: Run a comprehensive codebase audit across architecture, quality, security, and performance dimensions. Dispatches specialized agents.
argument-hint: "[all|12factor|patterns|rust|security|smells|efficiency]"
---

Run a codebase audit on the Gorilla Coach project. Scope: $ARGUMENTS (default: all).

## Dispatch Table

Map the requested scope to agent(s):

| Argument | Agent(s) | Scope passed to agent |
|----------|----------|-----------------------|
| `all` (or empty) | audit-architecture, audit-quality, audit-security-perf | all dimensions |
| `12factor` | audit-architecture | 12-Factor only |
| `patterns` | audit-architecture | GoF patterns only |
| `rust` | audit-quality | Rust best practices only |
| `smells` | audit-quality | Code smells and dead code only |
| `security` | audit-security-perf | Security only |
| `efficiency` | audit-security-perf | Efficiency only |

## Execution

1. **Preparation:** Read CLAUDE.md to pass project context to agents.

2. **Dispatch:** Launch the appropriate agent(s) based on the argument. **CRITICAL: When multiple agents are needed (e.g., `all`), you MUST launch ALL of them in parallel by including multiple Agent tool calls in a single message.** Do NOT run them sequentially. Pass each agent a prompt that includes:
   - The specific dimension(s) to audit
   - The workspace root path: `/home/mo/data/Documents/git/gorilla_coach`
   - Instruction to read CLAUDE.md first

3. **Aggregation:** Wait for all parallel agents to complete, then produce a consolidated report:
   - Deduplicate findings that appear in multiple agents' results
   - Sort by severity: CRITICAL > HIGH > MEDIUM > LOW
   - Group by dimension

## Output Format

```
# Codebase Audit Report

**Scope:** [dimensions audited]
**Date:** [today]

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | N |
| HIGH | N |
| MEDIUM | N |
| LOW | N |

## Findings

### CRITICAL

[findings sorted by dimension]

### HIGH

[findings sorted by dimension]

### MEDIUM

[findings sorted by dimension]

### LOW

[findings sorted by dimension]

## Positive Observations

[well-implemented patterns worth preserving]
```

## Rules

- **Read-only** — no file modifications, no fixes
- Every finding must have a concrete `file:line` reference
- Respect CLAUDE.md conventions — don't flag things the project does intentionally
- Precision over recall — fewer accurate findings beat many speculative ones
- Acknowledge what's done well, not just problems
