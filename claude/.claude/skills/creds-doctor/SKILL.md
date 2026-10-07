---
name: creds-doctor
description: "Diagnose where your bwu-loaded credentials are visible and why. Triggers: creds doctor, why can't X see my token, why is GITLAB_TOKEN empty, did bwu work, keyring vs env, bwu status, credential propagation, do I need to run bwu."
---

# creds-doctor

Answers "why does process X see my GitLab/Jira token but process Y doesn't?" by checking the two stores `bwu` writes to and reporting where creds are live.

## The model (one paragraph)

`bwu` loads creds into **two stores with different scope**:

- **Kernel user keyring `@u`** — per-UID, in kernel memory, wiped on reboot. The source of truth. Shared by every process of this UID **only while each key's user permission byte grants READ** (`0x3f3f0000`): searching `@u` works regardless, but *reading* needs either that byte or **possession**, and shells that outlived their login (tmux panes, claude — `pam_keyinit force revoke`) possess nothing. Read via the sourceable `~/.local/bin/gl-load-creds` (precedence: env → `@u` → `~/.secrets.json`/`~/.work.json`) or zsh `bw_keyring_hydrate`.
- **Process env** (`export GITLAB_TOKEN=…`) — per-process, **frozen at spawn**; only reaches the shell `bwu` ran in (+ children spawned after). You cannot inject env into an already-running sibling.

So the tmux sysstat bar and Claude Code's Bash tool pick up one `bwu` from any pane (they read the shared keyring), while a sibling shell's `$GITLAB_TOKEN` stays empty (its env froze at spawn) until it re-sources `gl-load-creds` — or, since the precmd top-up, at its next prompt. Full write-up in memory `bwu-cred-propagation`.

**The third failure mode (2026-07-29):** `bwu` run from a possession-less shell writes the keys fine but its `keyctl setperm` is silently denied, leaving every key at the kernel default **user=VIEW-only** — `keyctl search` ✓ everywhere, every `keyctl print` denied, all shells hydrate empty, while systemd `--user` units (which possess `@u` via the manager) keep working. The doctor detects it per-key; `--repair` fixes it via a transient systemd unit; `bwu` now verifies and self-heals the same way.

## Files

- `creds-doctor.sh` — prints a presence/absence report for the keyring, this process's env, the on-disk caches, a **live MCP-auth probe** (`claude mcp list`, separate store from the keyring), and an end-to-end fresh-shell hydration test. **Never prints secret values** (only set/empty + lengths + key presence).

## Instructions

Run the doctor and interpret it for the user — don't delegate to a subagent (a subagent may not share this UID's env, which would skew the env section):

```bash
bash ~/.claude/skills/creds-doctor/creds-doctor.sh
```

Then read the **Verdict** and translate it into the user's actual situation:

| Symptom in report | Meaning | Fix |
|---|---|---|
| `@u` has `gl:token`, end-to-end ✓ | Creds loaded; source of truth healthy | Nothing — same-UID processes can hydrate |
| `@u` has `gl:token` but **this env empty** | Frozen-snapshot: this process started before `bwu` | `source ~/.local/bin/gl-load-creds` here; or relaunch the process from a bwu'd pane; interactive zsh self-heals at the next prompt (precmd top-up) |
| key **present but user=VIEW-only** (✗ per-key line) / end-to-end ✗ | `bwu` ran from a shell with a revoked session keyring; its setperm was denied and readers get nothing while `keyctl search` still succeeds | `creds-doctor --repair`, or re-run `bwu` (it now verifies + self-heals via systemd) |
| Session keyring **REVOKED** | This shell outlived its login (`pam_keyinit force revoke`) — normal for tmux/claude; harmless while perm bytes are right | Nothing by itself; it only matters combined with VIEW-only keys |
| `@u` `gl:token` **absent** / end-to-end ✗ | `bwu` not run this boot (keyring wiped on reboot) | Run `bwu` once |
| `keyctl MISSING` | Host has no kernel keyring | Rely on `~/.secrets.json`/`~/.work.json` caches instead |
| MCP section: Atlassian **NEEDS AUTH** | Jira/Confluence MCP OAuth expired — independent of the keyring | `/mcp` in Claude Code to re-auth; the keyring `jira:token` won't help (see memory `jira-rest-token-dead`) |

Always remind, when relevant:
- **Subagents** I spawn **inherit this session's env** (verified) — so a `claude` launched after `bwu` hands them the creds too. The only gap is a session launched *before* `bwu`; there, like the main loop, they source `gl-load-creds` (live keyring), and the `gl-*`/`glab` tools they call already do this. So this is rarely a real problem — don't over-warn (supersedes the older `mr-review-subagent-auth` worry, which was intermittent).
- **MCP auth is a separate store** — the doctor now probes it live (`claude mcp list`), so a green keyring section says nothing about MCP health; **read the MCP section**. Atlassian/Jira authenticate via their own OAuth, not the keyring's `jira:token`.
- Each Claude **Bash tool call is a fresh shell**, so a `source` in one call doesn't carry to the next; re-source per call or rely on the `gl-*`/`glab` tools that source it themselves.

## Examples

- `/creds-doctor` — full report + verdict
- "why is my GITLAB_TOKEN empty in this pane?" → run it; almost always the frozen-snapshot row
- "did bwu actually work?" → run it; check `@u` has `gl:token` and end-to-end ✓
