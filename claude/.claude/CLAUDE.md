# Global Conventions

<critical_rules>
1. Think before coding: state assumptions explicitly. If uncertain, ask. If multiple interpretations exist, present them — don't pick silently.
2. Simplicity first: no features beyond what was asked. No abstractions for single-use code. If 200 lines could be 50, rewrite.
3. Surgical changes: don't "improve" adjacent code, comments, or formatting. Every changed line MUST trace to the user's request. Remove only imports/variables YOUR changes made unused.
4. Goal-driven: transform tasks into verifiable goals. For multi-step tasks, state a plan with verify steps.
5. When editing a file, ALWAYS `read` its imported dependencies first. Do not guess type signatures or interfaces.
6. When working on code, ALWAYS use a worktree (via `/worktree`) before editing — never edit the shared main checkout directly. The main checkout is fragile across a session (branch can switch, HEAD can move, files come back "modified since read"); a worktree isolates the branch in its own working directory.
</critical_rules>

## Commits

Conventional commits, imperative mood: `feat(scope):`, `fix(scope):`, `refactor(scope):`, `chore(scope):`, `docs(scope):`

## Rust MRs (idp/selfservice + sibling crates)

Before pushing a branch with changed `.rs` files, verify locally in the affected crate(s):
`cargo fmt --check && cargo check --tests && cargo test`. `cargo check` / `cargo test` do **not**
cover formatting — CI's `*:test` job runs `cargo fmt --check` as its first step and fails the whole
pipeline on any diff. That job is **manual on master pushes but auto on MR pipelines**, so master
can carry a latent fmt violation (e.g. a direct-to-master hotfix) that only surfaces as a red
pipeline on the *next* MR. If `fmt --check` flags a line you didn't touch, reflow it (`cargo fmt`)
in the same MR with a `style(...)` commit — it unblocks your MR and the fmt gate for everyone after.

## Code review

When reviewing MRs: check `~/.mr-reviews.json` for prior history, focus on bugs/security/missing error handling, skip style, post comments only when asked.

## Credentials

Never hardcode tokens/passwords/IPs. **Bitwarden is the source of truth** — run `bwu` once per
session to unlock the vault, export `GITLAB_TOKEN`/`JIRA_API_TOKEN`/`INFRACOST_API_KEY`, and re-sync
the on-disk caches. `~/.secrets.json` and `~/.work.json` are `0600` caches that `bwu` regenerates
from the `secrets-json` / `work-json` Secure Notes — edit secrets in Bitwarden, never the files
(a box with the cache file absent runs 100% from the vault, env-only). Non-secret config still comes
via direnv (`~/.envrc`). The `bwu` helper lives in `stow/zsh/.config/zsh/zshrc-fn`.

## Tools

- `glab` — GitLab CLI (on PATH via mise shims)
- `nomos-check` — GKE ConfigSync status
