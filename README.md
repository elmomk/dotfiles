# My dotfiles

This repository contains my configuration files for Linux (Arch + Hyprland).

## Packages

| Package | Description |
|---------|-------------|
| `hyprland` | Hyprland WM config, QuickShell desktop shell (bar, launcher, dashboard, notifications, OSD, sidebar, session, Claude panel), display auto-detection, hypridle, hyprlock |
| `alacritty` | Terminal emulator |
| `fish` | Fish shell config |
| `tmux` | Terminal multiplexer |
| `nvim` | Neovim editor |
| `git` | Git configuration |
| `udev` | Custom udev rules |

## QuickShell Desktop Shell

A unified Material 3 desktop shell replacing waybar, swaync, walker, and wlogout. Features:

- **Bar**: Workspaces, active window, system tray, clock, status icons (audio, network, bluetooth, battery, fcitx, Claude)
- **Launcher**: App search, calculator, clipboard history, color schemes, wallpapers, Claude quick-ask
- **Dashboard**: Calendar, media controls, weather, system resources
- **Sidebar**: Notification center
- **OSD**: Volume/brightness overlay
- **Session**: Power menu (shutdown, reboot, hibernate, lock)
- **Claude Panel**: Integrated Claude Code chat
- **Control Center**: Full settings UI for appearance, audio, networking, bluetooth

## Display Auto-Detection

Monitors are auto-detected at startup and on hotplug. A profile system (`hyprland/.config/hypr/scripts/display-profiles.json`) maps monitor resolutions to Hyprland config and QuickShell appearance scales — no manual reconfiguration needed when switching between displays. See [scripts/README.md](hyprland/.config/hypr/scripts/README.md) for details.

## Requirements

- git (to clone this repository)
- stow (to deploy the configuration files)
- $HOME/.config directory used as XDG_HOME_CONFIG

## How to use

Clone this repository into your home directory.

Go into `$HOME/.dotfiles` and use `stow` to deploy the config files you want to.

```bash
cd $HOME/.dotfiles
stow <package name>
```

This will create required symbolic links so that your configuration files are taken into account the next time you start your tools.

To delete the symbolic links.

```bash
cd $HOME/.dotfiles
stow -D <package name>
```
