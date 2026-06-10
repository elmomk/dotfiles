---
name: wsl-storage
description: "Contain WSL/Windows storage so the disk doesn't fill up. Scans drive + WSL vdisk usage (via wsl-monitor) and reclaims space (adapted from wsl-cleanup) per category with confirmation. Triggers: 'storage full', 'running out of disk', 'clean up WSL', 'disk space', 'laptop is full', 'free up space', 'wsl cleanup'."
argument-hint: "Optional: 'scan' (report only) or categories to reclaim (podman mise rust go apt journal trash nvim-bak all)"
---

# wsl-storage

Keeps the laptop's disk under control by wrapping the user's existing `wsl-monitor` (usage check) and `wsl-cleanup` (reclaim) scripts. Because `wsl-cleanup` is interactive (`read -p` prompts that hang when run by the model), this skill uses two non-interactive helpers instead: a read-only scan and a flag-driven reclaim that only touches categories the user approves.

## When to use

- "I'm running out of disk", "storage is full", "my laptop is about to explode", "free up space", "clean up WSL".
- Proactive checkups: "how's my disk", "what's eating space".

## Files

- `scripts/wsl-scan.sh` — read-only. Drive usage + size of every reclaim candidate. Touches nothing.
- `scripts/wsl-reclaim.sh` — non-interactive cleanup. Acts ONLY on categories passed as flags. Supports `--dry-run`.

Canonical originals live at `~/dotfiles/wsl/bin/wsl-monitor` and `~/dotfiles/wsl/bin/wsl-cleanup` (also deployed to `~/bin/`). This skill does not modify them.

## Workflow

1. **Scan first** — always start here, even if the user named categories:

   ```bash
   bash ~/.claude/skills/wsl-storage/scripts/wsl-scan.sh
   ```

   Present a short table: current C:/D:/WSL usage and the biggest reclaim candidates. Note that the WSL virtual disk does **not** shrink on its own — deleting files inside frees space for WSL but the `.vhdx` only returns space to Windows after a compact (see Reclaiming to Windows below).

2. **Propose**, don't auto-run. Recommend the categories that will actually move the needle (biggest first). Categories:

   | Category | Frees | Risk |
   |---|---|---|
   | `terragrunt` | `.terragrunt-cache` dirs under `~/work` (usually the biggest) | re-inits on next `terragrunt` run |
   | `node-modules` | `node_modules` dirs under `~/work` | `npm/yarn install` to restore |
   | `podman` | images/containers/volumes | re-pull on next use |
   | `terraform-d` | `~/.terraform.d` provider plugin cache | re-download on next init |
   | `caches` | `~/.cache/{ms-playwright,puppeteer,trivy,uv}` | re-download on next use |
   | `rust` | `target/` dirs under `~/work` | next build is a full rebuild |
   | `go` | go module cache | re-download on next build |
   | `mise` | tool cache + unused versions | re-download if needed |
   | `trash` | `~/.local/share/Trash` | permanent delete |
   | `nvim-bak` | old `~/.local/share/nvim.bak` | permanent delete |
   | `apt` | apt autoremove + cache | needs sudo |
   | `journal` | journald logs >1 day | needs sudo |

3. **Confirm**, then reclaim only the approved set. Offer `--dry-run` first if the user is cautious:

   ```bash
   bash ~/.claude/skills/wsl-storage/scripts/wsl-reclaim.sh --dry-run podman rust
   bash ~/.claude/skills/wsl-storage/scripts/wsl-reclaim.sh podman rust
   ```

   `all` runs every category. `apt`/`journal` will prompt for sudo — if running non-interactively and they hang, tell the user to run that one in their own terminal.

4. **Report** the before/after WSL `Used` delta the script prints.

## Reclaiming space back to Windows (the vhdx)

Pruning frees space *inside* WSL but the ext4 `.vhdx` stays large. To return it to the C:/D: drive, the user must run this from **Windows PowerShell** (not WSL), after `wsl --shutdown`:

```powershell
wsl --shutdown
# Optimize-VHD needs Hyper-V; otherwise use diskpart compact vdisk
Optimize-VHD -Path "<path to ext4.vhdx>" -Mode Full
```

Surface this step only when the user's actual goal is freeing the Windows drive (C:/D: near full), not just making room inside WSL. Find the vhdx path under `%LOCALAPPDATA%\Packages\<distro>\LocalState\`.

## Automating it

A systemd user timer (`wsl-monitor.timer`) already runs `wsl-monitor` hourly and fires a Windows notification past the threshold (C:/D: 82%, WSL 120 GiB). If the user wants automatic *reclaim* too, propose a conservative scheduled `wsl-reclaim.sh podman go trash` (safe, auto-regenerating categories only) — but get explicit sign-off before adding anything to systemd or cron, and never auto-run destructive categories like `rust` or `nvim-bak`.

## Guardrails

- Never run `wsl-reclaim.sh` without naming categories — it refuses by design.
- Never reclaim a category the user didn't approve. Default to `--dry-run` when uncertain.
- `rust`, `nvim-bak`, `trash` are irreversible (rebuild / permanent delete) — call that out before running.
