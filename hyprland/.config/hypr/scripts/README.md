# Display Auto-Detection & Profile System

Automatically detects connected monitors, generates Hyprland monitor config, and adjusts QuickShell appearance scales — at startup and on hotplug.

## Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Hyprland start  │────▶│ display-detect.sh │────▶│  monitors.conf  │
└─────────────────┘     │                  │     └────────┬────────┘
                        │  hyprctl monitors│              │
                        │  match profile   │     hyprctl reload
                        │  update scales   │              │
                        └──────────────────┘     ┌────────▼────────┐
                                │                │    Hyprland      │
                                │                │  applies config  │
                                ▼                └─────────────────┘
                        ┌──────────────────┐
                        │   shell.json     │──▶ QS FileView reloads
                        │  (scale updates) │    appearance scales
                        └──────────────────┘

┌─────────────────────┐     monitor added/removed
│ display-monitor.sh  │────────────────────────▶ re-runs detect
│ (socat socket2)     │
└─────────────────────┘
```

## Files

| File | Purpose |
|------|---------|
| `display-profiles.json` | Profile definitions — match rules, monitor templates, QS scales |
| `display-detect.sh` | Core detection: detect → match → generate config → update scales → reload |
| `display-monitor.sh` | Hotplug listener via Hyprland's socket2 |
| `../conf/monitors.conf` | Generated monitor config (fallback: `preferred, auto, auto`) |

## Startup Flow

1. Hyprland starts and loads `conf/monitors.conf` (initially the fallback)
2. `exec-once` runs `display-detect.sh`
3. Script queries `hyprctl monitors -j` for connected monitors
4. Highest-resolution monitor is treated as primary
5. Primary width is matched against profiles in `display-profiles.json` (first match wins)
6. `monitors.conf` is regenerated from the matched profile's template
7. `~/.config/caelestia/shell.json` scales are updated (rounding, spacing, padding, font size)
8. `hyprctl reload` applies the new monitor config
9. QuickShell detects `shell.json` change via FileView and reloads appearance
10. `display-monitor.sh` starts listening for hotplug — re-runs detection on connect/disconnect

Brief flicker (~1s) on first login is expected as monitors reconfigure.

## Profiles

Profiles are defined in `display-profiles.json`. First match wins.

| Profile | Match Condition | Scale | Use Case |
|---------|----------------|-------|----------|
| `workstation-4k` | width ≥ 3840 | 2x | 4K external display |
| `laptop-1080p` | width ≤ 1920 | 1x | Laptop screen only |
| `default` | (any) | 1.5x | Fallback for unknown resolutions |

### Match Rules

Each profile has a `match` object with optional fields:

- `min_width` — primary monitor width must be ≥ this value
- `max_width` — primary monitor width must be ≤ this value

An empty `match` object (`{}`) always matches (used for the default fallback).

### Monitor Template

The `monitor_template` string generates Hyprland `monitor=` lines. Placeholders:

- `{name}` — output name (e.g., `DP-1`, `eDP-1`)
- `{width}` — pixel width
- `{height}` — pixel height
- `{rate}` — refresh rate (Hz, integer)

### QS Scales

The `qs_scales` object maps to `~/.config/caelestia/shell.json`:

| Key | shell.json Path |
|-----|-----------------|
| `rounding` | `.appearance.rounding.scale` |
| `spacing` | `.appearance.spacing.scale` |
| `padding` | `.appearance.padding.scale` |
| `font_size` | `.appearance.font.size.scale` |

## Adding a New Profile

Edit `display-profiles.json` and add an entry **before** the `default` profile:

```json
{
  "name": "ultrawide-1440",
  "match": { "min_width": 3440, "max_width": 3839 },
  "monitor_template": "{name}, {width}x{height}@{rate}, auto, 1",
  "qs_scales": { "rounding": 1.5, "spacing": 1.5, "padding": 1.5, "font_size": 1.5 }
}
```

Then re-run `display-detect.sh` or reconnect a monitor to apply.

## Stow Safety

The detection script checks if `monitors.conf` is a symlink (created by `stow`). If so, it removes the symlink and writes a regular file, so runtime changes don't propagate back into the dotfiles repo. The git-tracked `conf/monitors.conf` remains the fallback template.

## Skip-if-unchanged

Both `monitors.conf` and `shell.json` are checksummed before writing. If nothing changed (same monitor setup as before), the script exits without triggering a reload — no unnecessary flicker.

## Dependencies

- `jq` — JSON parsing
- `bash` — script runtime
- `socat` — socket2 hotplug listener (display-monitor.sh only)
- `hyprctl` — primary monitor detection and reload (fallback: `wlr-randr`)

## Troubleshooting

**Script doesn't run at startup**: Check `conf/startup.conf` has the `exec-once` lines. Verify scripts are executable (`chmod +x`).

**Wrong profile selected**: Run `display-detect.sh` manually — it prints the detected primary width and matched profile name. Check your profile match rules in `display-profiles.json`.

**monitors.conf not updating**: The script skips writes if content is unchanged. Delete `~/.config/hypr/conf/monitors.conf` and re-run to force regeneration.

**Hotplug not working**: Verify `socat` is installed. Check that `$HYPRLAND_INSTANCE_SIGNATURE` is set (it should be in a Hyprland session). Check `display-monitor.sh` is running: `pgrep -f display-monitor`.
