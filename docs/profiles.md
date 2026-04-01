# Machine Profiles

Profiles are deployment scripts that stow the right packages for each machine type.

## Available Profiles

| Profile | Machine | Packages |
|---------|---------|----------|
| `home.sh` | 4K desktop (Arch + Hyprland) | core, zsh, zsh-personal, starship, tmux, gitconfig, hyprland, mo-vim, udev |
| `laptop.sh` | Laptop (Arch + Hyprland) | core, zsh, zsh-personal, starship, tmux, gitconfig, hyprland, mo-vim, udev |
| `wsl.sh` | WSL (work) | core, wsl, zsh, zsh-personal, starship, tmux, gitconfig, mo-vim |

## Usage

```bash
# Deploy for your machine type
./profiles/home.sh
./profiles/laptop.sh
./profiles/wsl.sh
```

## Profile Differences

- **home** and **laptop** are identical package sets. Display scaling is handled automatically by the display auto-detection system in the hyprland package.
- **wsl** excludes `hyprland` and `udev` (no Wayland in WSL) and adds the `wsl` package with work-specific tooling.

## Adding a New Profile

Create a new script in `profiles/` following the same pattern:

```bash
#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
stow -v <packages...>
```
