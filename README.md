# dotfiles

Personal configuration for my Linux machines, deployed with GNU stow.
Each top-level directory is a stow package mirroring `$HOME`.

## Machines

| Machine | What gets stowed |
|---------|------------------|
| **WSL2 (daily driver)** | `zsh-personal starship tmux gitconfig wsl claude` — `install.sh` defaults |
| **Arch desktop (legacy)** | GUI packages: `hyprland i3 alacritty dunst sxhkdrc leftwm regolith2_i3 udev` |
| **work dev-server** | not this repo — see *Two-repo setup* below |

## Install

```bash
git clone git@github.com:elmomk/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh          # tooling + default packages
PKGS="zsh-personal tmux" ./install.sh  # or pick packages explicitly
```

`install.sh` is idempotent: apt basics, mise/starship/neovim/bitwarden-cli
binaries, command shims, then stow. GUI and editor packages (`lazyvim`,
`mo-vim`) are opt-in via `PKGS`.

## Notable packages

| Package | Contents |
|---------|----------|
| `zsh-personal` | `~/.zshenv` + `~/.zshrc-{personal,work,fn,zinit}` modules; your `~/.zshrc` sources `~/.zshrc-personal` |
| `wsl` | `~/bin` toolbox, mise config, systemd user units (wsl-monitor), `~/work/.envrc` |
| `scripts` | portable tools in `scripts/bin` (tmux popups, gl-* GitLab helpers, open-url); `wsl/bin` symlinks into it |
| `claude` | Claude Code: `CLAUDE.md`, commands, skills, statusline. `settings.json` is machine-local — seeded from `settings.template.json`, never stowed (Claude writes into it) |
| `tmux`, `starship`, `gitconfig` | what it says on the tin |

## Two-repo setup

This public repo is the source of truth for personal config. Work/internal
tooling (cluster scripts, internal GitLab helpers, work Claude commands) is
**deliberately gitignored here** — its durable home is the company-internal
`shared-dotfiles` repo, which also carries the dev-server setup (its own stow
tree + installer). A manifest-driven `sync.sh` / `reverse-sync.sh` pair in that
repo mirrors the shareable subset both ways.

## Secrets

None in this repo. Bitwarden is the source of truth; `bwu` (in `.zshrc-fn`)
loads tokens per session and refreshes the `~/.secrets.json` / `~/.work.json`
caches. See `scripts/bin/.secrets.json.example` / `.work.json.example` for the
expected shape.
