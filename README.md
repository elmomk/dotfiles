# My dotfiles

This repository contains my configuration files for Linux (Arch + Hyprland).

## Screenshots

### Desktop with Horizontal Bar
![Bar](assets/screenshots/bar.png)

### Dashboard (Weather, Calendar, Media, Performance)
![Dashboard](assets/screenshots/dashboard.png)

### App Launcher
![Launcher](assets/screenshots/launcher.png)

### Claude Code Scratchpad
![Claude Code](assets/screenshots/claude.png)

### Notification Sidebar
![Sidebar](assets/screenshots/sidebar.png)

### Session Menu
![Session](assets/screenshots/session.png)

## Packages

| Package | Description |
|---------|-------------|
| `hyprland` | Hyprland WM config, QuickShell desktop shell, display auto-detection, hypridle, hyprlock |
| `alacritty` | Terminal emulator |
| `fish` | Fish shell config |
| `tmux` | Terminal multiplexer |
| `nvim` | Neovim editor |
| `git` | Git configuration |
| `udev` | Custom udev rules |

## QuickShell Desktop Shell

A unified Material 3 desktop shell built on [Caelestia](https://github.com/caelestia-shell/shell), customized with a horizontal top bar layout and 4K scaling. Replaces waybar, swaync, walker, and wlogout.

### Features

- **Horizontal Bar**: Workspaces (1-10), active window title, centered clock, status icons (audio, network, bluetooth, battery), power button
- **Launcher**: App search with fuzzy matching, calculator, clipboard history, color schemes, wallpaper picker
- **Dashboard**: Weather (7-day forecast), calendar, media controls, system performance (CPU/GPU/RAM/storage/network)
- **Sidebar**: Notification center, screen recording, quick toggles
- **OSD**: Volume/brightness overlay with hover reveal
- **Session**: Power menu (logout, shutdown, reboot, hibernate, lock, suspend)
- **Claude Code**: Hyprland scratchpad with foot terminal running Claude Code, slides from the left
- **Control Center**: Full settings UI for appearance, audio, networking, bluetooth

### Keybinds

| Key | Action |
|-----|--------|
| `Super + Space` | App Launcher |
| `Super + D` | Dashboard |
| `Super + C` | Claude Code (scratchpad) |
| `Super + N` | Notification Sidebar |
| `Super + M` | Session Menu |
| `Super + Shift + A` | Utilities |
| `Super + Shift + ,` | Control Center |

## Display Auto-Detection

Monitors are auto-detected at startup and on hotplug. A profile system maps monitor resolutions to Hyprland config and QuickShell appearance scales — no manual reconfiguration needed when switching between displays.

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

To delete the symbolic links.

```bash
cd $HOME/.dotfiles
stow -D <package name>
```
