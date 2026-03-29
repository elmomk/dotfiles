# Hyprland Setup Review - 2026-03-27

## Bugs

- [ ] Fix `prefferred` typo in `hyprland/.config/hypr/hyprland.conf:3` (should be `preferred`)
- [ ] Fix hardcoded `/home/salomo/` path in `hyprland/.config/systemd/user/cliphist-thumbs-cleanup.service` — use `/home/mo/` or `%h` systemd specifier
- [ ] Hyprlock background hardcoded to `backgrounds/1-kanagawa.jpg` in `hyprland/.config/hypr/hyprlock.conf` — won't follow theme switches

## Consistency / Cleanup

- [ ] All window rules commented out in `hyprland/.config/hypr/conf/windowrules.conf` — re-enable needed rules or remove dead config
- [ ] Hypridle commented out in `hyprland/.config/hypr/conf/startup.conf` — no automatic screen lock/dim/suspend
- [ ] Wlogout icons use absolute `/home/mo/.config/wlogout/icons/` paths in `hyprland/.config/wlogout/style.css`
- [ ] Swaync style hardcodes Catppuccin Macchiato colors instead of sourcing from theme system (`hyprland/.config/swaync/style.css`)

## Potential Improvements

- [ ] Animation durations are long (borders: 5.39s, windows: 4.79s) while workspace animations are 0s — consider shorter for snappier feel
- [ ] `install.sh` missing some used dependencies: `brightnessctl`, `wireplumber`, `wofi`, `brave-beta`, `fcitx5`, `blueman`, `nm-applet`, `firefox`, `thunderbird`
- [ ] Waybar directory has `*.bak` files — consider gitignoring them
- [ ] Both `walker` and `wofi` configured as app launchers — redundant unless intentional
