#!/usr/bin/env bash
# install.sh — bootstrap for the personal (elmomk) dotfiles on a fresh box.
# Idempotent: safe to re-run. Ported from the shared-dotfiles installer and
# adapted to THIS repo's layout:
#   - stow packages live at the repo ROOT (not a stow/ subdir)
#   - shell modules come from the `zsh-personal` package: it stows
#     ~/.zshrc-{personal,work,fn,zinit}. Your own ~/.zshrc must source
#     ~/.zshrc-personal (the oh-my-zsh ~/.zshrc on existing boxes already does).
#   - ~/bin is the `wsl` package's bin/ (stowed), NOT a link to ~/.local/bin.
#
# Usage:
#   ./install.sh                                   # tooling + default packages
#   PKGS="zsh-personal tmux" ./install.sh          # stow only these packages
#   SKIP_APT=1 ./install.sh                        # skip the apt step
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$HERE"   # packages are top-level dirs in this repo

# ── 1. system packages (incl. shell deps; unzip is required for the bw cli) ───
if [[ "${SKIP_APT:-0}" != 1 ]]; then
  echo "==> apt"
  sudo apt-get update -qq
  sudo apt-get install -y stow zsh build-essential zoxide direnv bat fd-find ripgrep fzf unzip
fi

# ── 2. real dirs (so stow links files instead of folding ~/.config) ──────────
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/work/git"

# ── 3. mise — BINARY ONLY (tools installed ad hoc: `mise use -g <tool>`) ──────
if ! command -v mise >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/mise" ]]; then
  echo "==> mise"; curl -fsSL https://mise.run | sh
fi

# ── 4. starship prompt ───────────────────────────────────────────────────────
if [[ ! -x "$HOME/.local/bin/starship" ]] && ! command -v starship >/dev/null 2>&1; then
  echo "==> starship"; curl -sS https://starship.rs/install.sh | sh -s -- -b "$HOME/.local/bin" -y
fi

# ── 5. neovim (recent — Ubuntu apt's 0.9.x is too old for LazyVim) ────────────
if [[ ! -x "$HOME/.local/bin/nvim" ]]; then
  echo "==> neovim"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/nvim.tgz" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  rm -rf "$HOME/.local/nvim-linux-x86_64"
  tar -C "$HOME/.local" -xzf "$tmp/nvim.tgz"
  ln -sfn "$HOME/.local/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
fi

# ── 6. bitwarden cli (standalone binary; shell secrets via the `bwu` helper) ──
if [[ ! -x "$HOME/.local/bin/bw" ]] && ! command -v bw >/dev/null 2>&1; then
  echo "==> bitwarden-cli"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/bw.zip" "https://vault.bitwarden.com/download/?app=cli&platform=linux"
  unzip -oq "$tmp/bw.zip" -d "$tmp"
  install -m 0755 "$tmp/bw" "$HOME/.local/bin/bw"
  rm -rf "$tmp"
fi

# ── 7. command shims (Debian renames bat/fd; `editor` → nvim) ─────────────────
command -v batcat >/dev/null 2>&1 && ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
command -v fdfind >/dev/null 2>&1 && ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
[[ -e "$HOME/.local/bin/nvim" ]] && ln -sfn "$HOME/.local/bin/nvim" "$HOME/.local/bin/editor"

# ── 8. stow the config packages ──────────────────────────────────────────────
#   This repo is multi-machine; PKGS defaults to the headless/shell essentials.
#   GUI packages (i3 hyprland alacritty dunst sxhkdrc leftwm regolith2_i3 …) and
#   editor configs (lazyvim mo-vim) are opt-in: pass them via PKGS.
PKGS="${PKGS:-zsh-personal starship tmux gitconfig wsl}"
echo "==> stow (from $STOW_DIR): $PKGS"
stow -d "$STOW_DIR" -t "$HOME" $PKGS

# ── 9. claude settings — machine-local, never stowed/tracked ──────────────────
#   Claude Code writes into settings.json (model, permissions), so a stowed
#   symlink would dirty the repo. Seed a real file from the template once.
if [[ " $PKGS " == *" claude "* ]]; then
  [[ -L "$HOME/.claude/settings.json" && ! -e "$HOME/.claude/settings.json" ]] && rm "$HOME/.claude/settings.json"
  if [[ ! -e "$HOME/.claude/settings.json" ]]; then
    mkdir -p "$HOME/.claude"
    cp "$STOW_DIR/claude/.claude/settings.template.json" "$HOME/.claude/settings.json"
    echo "==> seeded ~/.claude/settings.json from template"
  fi
fi

# ── done ─────────────────────────────────────────────────────────────────────
cat <<'NOTE'

OK installed. Manual / out-of-scope (intentional):
  - mise tools    : mise use -g node glab fzf ...   (installed ad hoc, not in bulk)
  - ~/.zshrc      : must source ~/.zshrc-personal (the oh-my-zsh ~/.zshrc already does)
  - secrets       : Bitwarden is the source of truth. Run `bw login` once, then `bwu`
                    each session to load tokens. `bwu` also re-syncs ~/.secrets.json
                    (0600) only if that file already exists (opt-in fallback for
                    non-interactive jobs). See the bwu helper in zsh-personal/.zshrc-fn.
  - git identity  : git config --global user.name / user.email
  - tmux plugins  : prefix + I
  - LazyVim       : auto-installs its plugins on first `nvim` launch
NOTE
