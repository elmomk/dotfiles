# Global Conventions

<critical_rules>
1. Think before coding: state assumptions explicitly. If uncertain, ask. If multiple interpretations exist, present them — don't pick silently.
2. Simplicity first: no features beyond what was asked. No abstractions for single-use code. If 200 lines could be 50, rewrite.
3. Surgical changes: don't "improve" adjacent code, comments, or formatting. Every changed line MUST trace to the user's request. Remove only imports/variables YOUR changes made unused.
4. Goal-driven: transform tasks into verifiable goals. For multi-step tasks, state a plan with verify steps.
5. When editing a file, ALWAYS `read` its imported dependencies first. Do not guess type signatures or interfaces.
</critical_rules>

## Commits

Conventional commits, imperative mood: `feat(scope):`, `fix(scope):`, `refactor(scope):`, `chore(scope):`, `docs(scope):`

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
