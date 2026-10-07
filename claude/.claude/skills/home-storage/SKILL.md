---
name: home-storage
description: "Keep this GCP dev box's home disk from filling up. Scans ~/work for reclaim candidates (Rust target/, node_modules, .terragrunt-cache — spread across dozens of git worktrees) and reclaims them per category with confirmation, while NEVER touching a directory that a live Claude Code session, build, or editor is using. Triggers: 'home is full', 'running out of disk', 'disk space', 'free up space', 'what's eating my disk', 'clean up work dirs', 'home disk full'."
argument-hint: "Optional: 'scan' (report only) or categories to reclaim (rust node-modules terragrunt go caches worktrees all)"
---

# home-storage

Contains disk usage on this dev box (`/home/<user>`, ~157 GB partition). The dominant consumer is regenerable build output — dozens of git worktrees under `~/work` each carrying full Rust `target/` trees (measured at **72.5 GB** of `target/` alone), plus `node_modules` and `.terragrunt-cache`.

**Distinct from `wsl-storage`**, which is for the WSL laptop. This skill runs here, on the dev box, and its defining feature is that it **will not disrupt any currently-active Claude Code session** — multiple `claude --teammate-mode` sessions run concurrently on this box and build in these very worktrees.

## When to use

- "home is full", "running out of disk on the dev box", "free up space", "what's eating my disk", "clean up my work dirs".
- Proactive checkups: "how's my home disk".

## Files

- `scripts/homedisk-scan.sh` — read-only. Home usage + size of each reclaim category, split into **reclaimable** vs **busy/skipped**, plus worktree inventory. Touches nothing.
- `scripts/homedisk-reclaim.sh` — non-interactive. Acts ONLY on categories passed as flags, refuses with none, supports `--dry-run`.
- `scripts/lib-busy.sh` — shared busy-detection (see below). Both scripts source it.

## The busy guard (why this is safe)

A worktree is treated as **BUSY** and skipped if ANY of:
1. A running process owned by the user has its **cwd at-or-under** the worktree (catches Claude sessions, shells, `cargo`, `terragrunt`).
2. `lsof` reports an **open file** under the worktree (a build writing `target/`, `rust-analyzer`, an editor buffer).
3. Its `target/` or `node_modules/` was **modified in the last 45 min** (`HOMEDISK_BUSY_MTIME_MIN`) — an in-flight build the process scan might momentarily miss.

The reclaim script **re-computes** busy state at delete time (not just at scan time) and skips per-directory. There is an `--include-busy` escape hatch that disables the guard — do **not** use it unless the user explicitly insists and understands they may break a running build.

## Workflow

1. **Scan first**, always — even if the user named categories:
   ```bash
   bash ~/.claude/skills/home-storage/scripts/homedisk-scan.sh
   ```
   Present a short table: home usage, and per category the **reclaimable** figure (busy is excluded). Lead with the biggest win (`rust`).

2. **Propose**, don't auto-run. Recommend biggest-first from what's actually reclaimable:

   | Category | Frees | Risk |
   |---|---|---|
   | `rust` | all `target/` under `~/work` (the big one) | next build in that worktree = full rebuild |
   | `node-modules` | `node_modules` under `~/work` | `yarn`/`npm install` restores |
   | `terragrunt` | `.terragrunt-cache` dirs | re-inits on next `terragrunt` run |
   | `go` | `go clean -cache` | re-download on next build |
   | `caches` | `~/.cache/{uv,ms-playwright,trivy,puppeteer}` | re-download on next use |
   | `worktrees` | **report only** — prunes stale refs, lists clean+merged worktrees as removal candidates | never auto-removes |
   | `all` | rust + node-modules + terragrunt + go + caches (NOT worktrees) | — |

3. **Confirm**, then reclaim only the approved set. Offer `--dry-run` first if the user is cautious:
   ```bash
   bash ~/.claude/skills/home-storage/scripts/homedisk-reclaim.sh --dry-run rust node-modules
   bash ~/.claude/skills/home-storage/scripts/homedisk-reclaim.sh rust node-modules
   ```

4. **Report** the before/after home `Used` delta the script prints, and how many busy dirs were skipped (suggest a later re-run to reclaim those once idle).

## Guardrails

- Never run `homedisk-reclaim.sh` without naming categories — it refuses by design.
- Never reclaim a category the user didn't approve. Default to `--dry-run` when uncertain.
- **Never** pass `--include-busy` unprompted — the whole point is not disrupting live sessions.
- `worktrees` only reports; actually removing a worktree is a separate, explicit `git worktree remove` the user runs after reviewing the candidates (candidates are clean AND merged only; dirty/unmerged/busy are kept).
- `rust` means the next build in each cleaned worktree is a full rebuild — call that out.
