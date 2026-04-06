---
name: check
description: Run cargo check and clippy on the Rust workspace. Quick code quality gate.
argument-hint: [crate-name]
---

Run quality checks on the Rust workspace. Target: $ARGUMENTS (default: whole workspace).

## Steps

1. `cargo check --workspace` (or `-p $ARGUMENTS` if crate specified)
2. `cargo clippy --workspace -- -D warnings` (or `-p $ARGUMENTS`)
3. Report results concisely

If the project has a `scripts/check.sh` or `scripts/check-rust.sh`, prefer using that instead.

## Output format

- **PASS**: "All checks pass — no errors or warnings"
- **FAIL**: List each issue as `file:line — description`
