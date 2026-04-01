# Machine Profiles

Profiles are deployment scripts that stow the right packages for each machine type.

## Available Profiles

| Profile | Machine | Packages |
|---------|---------|----------|
| `home` | 4K desktop (Arch + Hyprland) | core, zsh, zsh-personal, starship, tmux, gitconfig, hyprland, mo-vim, udev |
| `laptop` | Laptop (Arch + Hyprland) | core, zsh, zsh-personal, starship, tmux, gitconfig, hyprland, mo-vim, udev |
| `wsl` | WSL (work) | core, wsl, zsh, zsh-personal, starship, tmux, gitconfig, mo-vim |

## Usage

```bash
./profiles/deploy.sh home
./profiles/deploy.sh laptop
./profiles/deploy.sh wsl
```

## Profile Differences

- **home** and **laptop** are identical package sets. Display scaling is handled automatically by the display auto-detection system in the hyprland package.
- **wsl** excludes `hyprland` and `udev` (no Wayland in WSL) and adds the `wsl` package with work-specific tooling.

## Adding a New Profile

Add a new case to `profiles/deploy.sh`:

```bash
  newprofile)
    stow -v <packages...>
    ;;
```
