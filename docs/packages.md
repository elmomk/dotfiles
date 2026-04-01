# Packages

Each top-level directory is a GNU Stow package. Running `stow <package>` symlinks its contents into `$HOME`.

## Active Packages

| Package | Description |
|---------|-------------|
| `core` | Shared scripts and utilities (tmux helpers, clipboard, system tools) |
| `wsl` | WSL work environment: AWS/GCP/k8s scripts, mise toolchain, systemd wsl-monitor |
| `zsh` | Zsh config with zinit plugin manager |
| `zsh-personal` | Personal zsh overrides and functions |
| `starship` | Starship prompt config |
| `tmux` | Tmux config |
| `gitconfig` | Git config with delta, conditional work includes |
| `hyprland` | Hyprland WM, QuickShell desktop shell, display auto-detection, hypridle, hyprlock |
| `mo-vim` | Neovim config |
| `udev` | Custom udev rules |
| `alacritty` | Alacritty terminal config |

## Archived Packages

Stale window manager and shell configs live in `archive/`. They are kept for reference but are not deployed by any profile.

## Package Structure

Each package mirrors the home directory layout:

```
<package>/
  .config/        -> ~/.config/
  bin/             -> ~/bin/
  .some-dotfile    -> ~/.some-dotfile
```
