# Caelestia Shell — Architecture Deep Dive

A comprehensive tutorial covering the QuickShell-based desktop shell that replaces waybar, swaync, walker, and wlogout with a single, unified QML application.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Config System](#config-system)
4. [Theming](#theming)
5. [Animation System](#animation-system)
6. [Component Library](#component-library)
7. [Services](#services)
8. [Module System](#module-system)
9. [State Management](#state-management)
10. [IPC](#ipc)

---

## Overview

### What It Replaces

| Tool      | Replaced By                              |
|-----------|------------------------------------------|
| waybar    | `modules/bar/` — status bar with workspaces, tray, clock, status icons |
| swaync    | `modules/sidebar/` + `modules/notifications/` — notification center + popup notifications |
| walker    | `modules/launcher/` — app launcher with search, actions, wallpaper picker, clipboard, calculator |
| wlogout   | `modules/session/` — session menu (logout, shutdown, reboot, hibernate) |

In addition, the shell provides modules that have no standalone equivalent:
- **Dashboard** — system info, media, weather, calendar
- **OSD** — on-screen display for volume/brightness
- **Utilities** — screen recording, idle inhibit, VPN toggle, toasts
- **Background** — wallpaper display with desktop clock and audio visualiser
- **Lock** — screen lock with PAM authentication
- **Control Center** — full settings GUI (appearance, networking, bluetooth, audio)
- **Claude** — integrated AI chat panel

### Design Philosophy

- **Single WlrLayershell window per screen** — the `drawers` window covers the entire screen; all panels (bar, launcher, dashboard, session, OSD, etc.) are child Items within it, animated in/out as drawers from the screen edges.
- **Material 3 theming** — the entire colour palette follows Google's Material 3 spec, with dynamic colour extraction from wallpapers via `caelestia scheme`.
- **Configuration via JSON** — a single `shell.json` file (read/written through `FileView` + `JsonAdapter`) controls all settings; the control center provides a full GUI for editing it.
- **Consistent animation language** — all animations use a shared set of Material 3 motion curves and durations from `AppearanceConfig`.
- **Per-screen state** — `PersistentProperties` + `Visibilities` give each monitor its own drawer open/close state, surviving quickshell reloads.

---

## Architecture

### Component Hierarchy

```
shell.qml (ShellRoot)
|
+-- Background {}              modules/background/Background.qml
|   +-- Wallpaper per screen
|   +-- DesktopClock
|   +-- Visualiser (cava)
|
+-- Drawers {}                 modules/drawers/Drawers.qml
|   |                          (Variants: one Scope per screen)
|   |
|   +-- StyledWindow "drawers" (WlrLayershell, full screen)
|   |   |
|   |   +-- PersistentProperties (visibilities: bar, osd, session, ...)
|   |   +-- HyprlandFocusGrab
|   |   +-- Border {}          (screen-edge coloured border)
|   |   +-- Backgrounds {}     (Shape with ShapePath per panel)
|   |   |
|   |   +-- Interactions {}    (CustomMouseArea — hover/drag detection)
|   |   |   |
|   |   |   +-- Panels {}     (hosts all drawer content)
|   |   |   |   +-- Osd.Wrapper          (right, vertically centered)
|   |   |   |   +-- Notifications.Wrapper (top-right)
|   |   |   |   +-- Session.Wrapper      (right, vertically centered)
|   |   |   |   +-- Launcher.Wrapper     (bottom, horizontally centered)
|   |   |   |   +-- Dashboard.Wrapper    (top, horizontally centered)
|   |   |   |   +-- BarPopouts.Wrapper   (below bar, follows mouse)
|   |   |   |   +-- Utilities.Wrapper    (bottom-right)
|   |   |   |   +-- Toasts.Toasts        (bottom-right, above utilities)
|   |   |   |   +-- Sidebar.Wrapper      (right edge, between notifs and utils)
|   |   |   |   +-- Claude.Wrapper       (left edge, full height)
|   |   |   |
|   |   |   +-- BarWrapper {} (top edge)
|   |   |       +-- Bar {}   (RowLayout of configurable entries)
|   |
|   +-- Exclusions {}         (4x StyledWindow for WlrLayershell exclusion zones)
|
+-- AreaPicker {}              modules/areapicker/
+-- Lock {}                    modules/lock/
+-- Shortcuts {}               modules/Shortcuts.qml (global keybinds + IPC)
+-- BatteryMonitor {}          modules/BatteryMonitor.qml
+-- IdleMonitors {}            modules/IdleMonitors.qml
```

### Data Flow

```
User interaction (hover/drag/click/shortcut/IPC)
        |
        v
Visibilities.getForActive() --> PersistentProperties { bar, osd, session, ... }
        |
        v
Wrapper.states ("visible" when visibilities.X && Config.X.enabled)
        |
        v
Wrapper.transitions (Anim with expressive curves)
        |
        v
Backgrounds.ShapePath (draws rounded panel bg in sync)
```

All panels follow the same pattern: a boolean in `PersistentProperties` controls whether the panel is shown. The `Wrapper` component uses QML `states` and `transitions` to animate `implicitWidth` or `implicitHeight` between 0 and the content size. The `Backgrounds` shape renders the panel background colour as a `ShapePath`, whose dimensions follow the wrapper's animated size.

### The Drawers Window

The key insight is that `Drawers.qml` creates **one full-screen WlrLayershell window per monitor**. This window uses `mask: Region { ... intersection: Intersection.Xor }` to make itself click-through everywhere *except* where panels are visible. The mask dynamically tracks the panel child positions/sizes via `Variants` over `panels.children`.

The window's `WlrLayershell.keyboardFocus` is switched to `OnDemand` only when panels that need keyboard input (launcher, session, claude) are open.

---

## Config System

### Architecture: FileView + JsonAdapter + JsonObject

The config system lives in `config/Config.qml` (a singleton) and works like this:

```
shell.json on disk
      |
      v
FileView { path: "${Paths.config}/shell.json"; watchChanges: true }
      |
      v
JsonAdapter {
    property AppearanceConfig appearance: AppearanceConfig {}
    property BarConfig bar: BarConfig {}
    property LauncherConfig launcher: LauncherConfig {}
    ...
}
```

`JsonAdapter` is a QuickShell type that automatically maps JSON keys to QML properties. Each config section is a separate `JsonObject` subtype (e.g., `config/BarConfig.qml`, `config/AppearanceConfig.qml`). `JsonObject` types can be nested — for example, `BarConfig` contains component types like:

```qml
// config/BarConfig.qml
JsonObject {
    property bool persistent: true
    property bool showOnHover: true
    property int dragThreshold: 20
    property Sizes sizes: Sizes {}
    property list<var> entries: [ { id: "logo", enabled: true }, ... ]

    component Sizes: JsonObject {
        property real scale: 1
        property int innerWidth: 40 * scale
        ...
    }
}
```

The default values in these `JsonObject` properties serve as fallbacks when `shell.json` is missing or incomplete.

### Saving Config Changes

`Config.save()` debounces writes through a 500ms timer. It calls `serializeConfig()`, which explicitly builds the JSON structure from current property values, then writes it via `fileView.setText(JSON.stringify(...))`.

The `FileView.watchChanges` flag means the file is also monitored for external edits. A `recentlySaved` flag prevents reload loops when the shell itself saves.

### Convenience Alias: Appearance

`config/Appearance.qml` is a singleton that provides shorthand access:

```qml
// Instead of Config.appearance.rounding.normal
Appearance.rounding.normal
Appearance.font.size.larger
Appearance.anim.durations.normal
Appearance.anim.curves.standard
```

### How to Add a Config Option

1. Add the property to the relevant `JsonObject` in `config/FooConfig.qml`:
   ```qml
   property bool myNewOption: false
   ```
2. Add serialization in `Config.qml`'s `serializeFoo()` function:
   ```js
   myNewOption: foo.myNewOption
   ```
3. Add the alias in `Config.qml` if it is a new top-level section:
   ```qml
   property alias foo: adapter.foo
   ```
4. Access it as `Config.foo.myNewOption` anywhere in the codebase.

---

## Theming

### Material 3 Colour System

The colour service lives in `services/Colours.qml`. It loads a JSON colour scheme from `${Paths.state}/scheme.json` (produced by the external `caelestia scheme` tool, which extracts colours from the current wallpaper using Material 3 algorithms).

The `M3Palette` component stores ~60 Material 3 colour roles:

```qml
component M3Palette: QtObject {
    property color m3primary: "#ffb0ca"
    property color m3onPrimary: "#541d34"
    property color m3primaryContainer: "#6f334a"
    property color m3surface: "#191114"
    property color m3surfaceContainer: "#261d20"
    property color m3surfaceContainerHigh: "#31282a"
    property color m3error: "#ffb4ab"
    property color m3success: "#B5CCBA"
    // ... plus terminal colours (term0-term15)
}
```

Components access colours as:
```qml
color: Colours.palette.m3primary
color: Colours.palette.m3surfaceContainer
color: Colours.palette.m3onSurface
```

The `Colours.light` property indicates dark/light mode, and `Colours.setMode("dark")` or `Colours.setMode("light")` triggers a new scheme generation.

### Transparency Layers

When transparency is enabled (`Appearance.transparency.enabled`), backgrounds become semi-transparent. The system provides two functions:

**`Colours.layer(colour, layerLevel)`** — returns a colour adjusted for the transparency layer:
- Layer `0` — base surfaces (background, surface) — uses `Qt.alpha(c, transparency.base)`
- Layer `1+` — elevated surfaces — uses `alterColour()` which shifts luminance based on wallpaper brightness and light/dark mode

**`Colours.tPalette`** — a pre-computed `M3TPalette` where every colour has already been run through `layer()`. This is used for backgrounds that need transparency.

The `alterColour` function is sophisticated: it considers the wallpaper's luminance (from `ImageAnalyser`), the light/dark mode, and the layer depth to produce colours that look good over the actual wallpaper.

Example usage in components:
```qml
color: Colours.layer(Colours.palette.m3surfaceContainer, 2)  // elevated transparent bg
color: Colours.tPalette.m3surface                             // pre-computed transparent surface
```

### Wallpaper Colour Extraction

The `Wallpapers` service detects the current wallpaper from `${Paths.state}/wallpaper/path.txt`. When the scheme is "dynamic", changing the wallpaper triggers `caelestia wallpaper -f <path>`, which:
1. Sets the wallpaper via hyprpaper
2. Extracts Material 3 colours and writes `scheme.json`
3. `Colours.qml`'s `FileView` detects the change, reloads, and all bindings update

Wallpaper preview (in the launcher) uses `caelestia wallpaper -p <path>` to generate a preview palette without actually changing the wallpaper.

### Utility: on() Function

`Colours.on(c)` returns a contrasting text colour for any background colour:
```qml
Colours.on(Colours.palette.m3primaryContainer)  // returns light or dark text
```

---

## Animation System

### Curves (Material 3 Motion)

Defined in `config/AppearanceConfig.qml` as `AnimCurves`:

| Curve                      | Bezier Points                                        | Use Case |
|----------------------------|------------------------------------------------------|----------|
| `standard`                 | `[0.2, 0, 0, 1, 1, 1]`                              | Default for most property animations |
| `standardAccel`            | `[0.3, 0, 1, 1, 1, 1]`                              | Elements leaving the screen |
| `standardDecel`            | `[0, 0, 0, 1, 1, 1]`                                | Elements entering the screen |
| `emphasized`               | `[0.05, 0, 0.133, 0.06, 0.167, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]` | Primary drawer show/hide |
| `emphasizedAccel`          | `[0.3, 0, 0.8, 0.15, 1, 1]`                         | Emphasized exit |
| `emphasizedDecel`          | `[0.05, 0.7, 0.1, 1, 1, 1]`                         | Emphasized enter |
| `expressiveFastSpatial`    | `[0.42, 1.67, 0.21, 0.9, 1, 1]`                     | Fast spatial movement (panel hide) |
| `expressiveDefaultSpatial` | `[0.38, 1.21, 0.22, 1, 1, 1]`                       | Default spatial movement (panel show) |
| `expressiveEffects`        | `[0.34, 0.8, 0.34, 1, 1, 1]`                        | Visual effects |

### Durations

Defined in `AnimDurations`, all scaled by `durations.scale`:

| Name                       | Default (ms) | Use Case |
|----------------------------|-------------|----------|
| `small`                    | 200         | Micro-interactions (icon fill, opacity) |
| `normal`                   | 400         | Standard property transitions |
| `large`                    | 600         | Major panel movements |
| `extraLarge`               | 1000        | Full-screen transitions |
| `expressiveFastSpatial`    | 350         | Fast panel hide animations |
| `expressiveDefaultSpatial` | 500         | Panel show animations |
| `expressiveEffects`        | 200         | Visual effects |

### Anim and CAnim Components

`components/Anim.qml` — a `NumberAnimation` pre-configured with the standard curve and normal duration:

```qml
// components/Anim.qml
NumberAnimation {
    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}
```

`components/CAnim.qml` — identical but for `ColorAnimation`:

```qml
// components/CAnim.qml
ColorAnimation {
    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}
```

### Consistent Animation Patterns

**Drawer show/hide** — all Wrapper components follow this pattern:

```qml
// Show transition (panel appearing)
Transition {
    from: ""
    to: "visible"
    Anim {
        target: root
        property: "implicitWidth"  // or "implicitHeight"
        duration: Appearance.anim.durations.expressiveDefaultSpatial  // 500ms
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}

// Hide transition (panel disappearing)
Transition {
    from: "visible"
    to: ""
    Anim {
        target: root
        property: "implicitWidth"
        duration: Appearance.anim.durations.expressiveFastSpatial  // 350ms
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}
```

**Colour transitions** — handled automatically by `StyledRect` and `StyledText`:

```qml
// StyledRect.qml
Rectangle {
    Behavior on color { CAnim {} }
}
```

**Interactive feedback** — `StateLayer` provides Material 3 ripple + hover opacity:

```qml
StateLayer {
    color: Colours.palette.m3onSurface
    // Hover: Appearance.interaction.hoverOpacity (0.08)
    // Press: Appearance.interaction.pressedOpacity (0.12) + radial ripple
}
```

---

## Component Library

### Primitives

| Component | File | Description |
|-----------|------|-------------|
| `StyledRect` | `components/StyledRect.qml` | `Rectangle` with automatic `Behavior on color { CAnim {} }`. Default transparent. |
| `StyledClippingRect` | `components/StyledClippingRect.qml` | `ClippingRectangle` (from Quickshell.Widgets) with color animation. Used for clipping children to rounded bounds. |
| `StyledText` | `components/StyledText.qml` | `Text` with: default font (`Rubik`), default colour (`m3onSurface`), native rendering, colour animation. Has an optional text-change animation system (set `animate: true`). |
| `MaterialIcon` | `components/MaterialIcon.qml` | `StyledText` configured for Material Symbols Rounded font. Supports variable axes: `fill` (0-1), `grade` (-25 dark, 0 light), `opsz`, `wght`. |

### Containers

| Component | File | Description |
|-----------|------|-------------|
| `StyledWindow` | `components/containers/StyledWindow.qml` | `PanelWindow` with WlrLayershell namespace `caelestia-{name}` and transparent colour. |
| `StyledFlickable` | `components/containers/StyledFlickable.qml` | Flickable with styled scroll bar. |
| `StyledListView` | `components/containers/StyledListView.qml` | ListView with styled scroll bar. |

### Controls

| Component | File | Description |
|-----------|------|-------------|
| `StateLayer` | `components/StateLayer.qml` | Material 3 interaction layer: hover highlight, pressed ripple animation. Wraps a `MouseArea`. |
| `IconButton` | `components/controls/IconButton.qml` | Material 3 icon button with 3 types: `Filled`, `Tonal`, `Text`. Supports toggle mode with animated radius. |
| `TextButton` | `components/controls/TextButton.qml` | Material 3 text button with label. |
| `IconTextButton` | `components/controls/IconTextButton.qml` | Button with both icon and text label. |
| `SplitButton` | `components/controls/SplitButton.qml` | Button with separate main action and dropdown action. |
| `ToggleButton` | `components/controls/ToggleButton.qml` | Toggle with icon and label. |
| `StyledSwitch` | `components/controls/StyledSwitch.qml` | Material 3 switch with animated thumb, check/cross icon drawn via `Shape`+`ShapePath`. |
| `StyledSlider` | `components/controls/StyledSlider.qml` | Material 3 slider with rounded track and pill handle. |
| `FilledSlider` | `components/controls/FilledSlider.qml` | Slider variant with filled track appearance. |
| `StyledTextField` | `components/controls/StyledTextField.qml` | Styled text input field. |
| `StyledInputField` | `components/controls/StyledInputField.qml` | Input field with label. |
| `CustomSpinBox` | `components/controls/CustomSpinBox.qml` | Spin box with custom styling. |
| `StyledRadioButton` | `components/controls/StyledRadioButton.qml` | Material 3 radio button. |
| `StyledScrollBar` | `components/controls/StyledScrollBar.qml` | Custom scroll bar styling. |
| `Menu` / `MenuItem` | `components/controls/Menu.qml` | Context menu with Material 3 styling. |
| `Tooltip` | `components/controls/Tooltip.qml` | Hover tooltip. |
| `CollapsibleSection` | `components/controls/CollapsibleSection.qml` | Expandable section with animated chevron and content height. |
| `SwitchRow` | `components/controls/SwitchRow.qml` | Label + switch in a row layout. |
| `ToggleRow` | `components/controls/ToggleRow.qml` | Label + toggle in a row layout. |
| `SpinBoxRow` | `components/controls/SpinBoxRow.qml` | Label + spin box in a row layout. |
| `SplitButtonRow` | `components/controls/SplitButtonRow.qml` | Label + split button in a row layout. |
| `CustomMouseArea` | `components/controls/CustomMouseArea.qml` | MouseArea with wheel event forwarding. |

### Effects

| Component | File | Description |
|-----------|------|-------------|
| `Elevation` | `components/effects/Elevation.qml` | Material 3 elevation shadow. `level` property (0-5) maps to shadow depth. |
| `ColouredIcon` | `components/effects/ColouredIcon.qml` | Icon image with colour overlay. |
| `Colouriser` | `components/effects/Colouriser.qml` | Applies colour tint to child items. |
| `InnerBorder` | `components/effects/InnerBorder.qml` | Inner border effect for containers. |
| `OpacityMask` | `components/effects/OpacityMask.qml` | Masks children with an alpha source. |

### Images

| Component | File | Description |
|-----------|------|-------------|
| `CachingImage` | `components/images/CachingImage.qml` | Image with caching support. |
| `CachingIconImage` | `components/images/CachingIconImage.qml` | Icon image with caching. |

### Layout Helpers

| Component | File | Description |
|-----------|------|-------------|
| `SectionContainer` | `components/SectionContainer.qml` | Container for grouped settings. |
| `SectionHeader` | `components/SectionHeader.qml` | Section title header. |
| `PropertyRow` | `components/PropertyRow.qml` | Key-value property display row. |

### Misc

| Component | File | Description |
|-----------|------|-------------|
| `CustomShortcut` | `components/misc/CustomShortcut.qml` | `GlobalShortcut` with `appid: "caelestia"` pre-set. Hyprland binds like `bindlni ... global,caelestia:launcher` trigger these. |
| `Ref` | `components/misc/Ref.qml` | Reference wrapper for passing objects. |

### Usage Examples

**IconButton with toggle:**
```qml
IconButton {
    icon: "dark_mode"
    toggle: true
    checked: Colours.light
    type: IconButton.Tonal
    onClicked: Colours.setMode(Colours.light ? "dark" : "light")
}
```

**StyledText with text-change animation:**
```qml
StyledText {
    text: Time.minuteStr
    animate: true
    animateProp: "scale"
    animateFrom: 0
    animateTo: 1
}
```

**MaterialIcon with variable fill:**
```qml
MaterialIcon {
    text: Audio.muted ? "volume_off" : "volume_up"
    fill: 1
    color: Colours.palette.m3onSurface
}
```

---

## Services

All services are singletons in `services/`. They are auto-loaded by QuickShell's module system and accessed by type name.

### Colours (`services/Colours.qml`)

The theming engine. See [Theming](#theming) above.

**Key API:**
- `palette` — current `M3Palette` (or preview palette)
- `tPalette` — transparency-adjusted palette
- `light` — `bool`, current light/dark mode
- `scheme` — `string`, current scheme name (e.g., "dynamic")
- `layer(colour, layerLevel)` — apply transparency layer
- `on(colour)` — get contrasting text colour
- `setMode(mode)` — set "light" or "dark"
- `load(jsonString, isPreview)` — load a scheme from JSON
- `wallLuminance` — `real`, current wallpaper brightness (from `ImageAnalyser`)

### Audio (`services/Audio.qml`)

Wraps PipeWire via `Quickshell.Services.Pipewire`.

**Key API:**
- `sink` / `source` — default output/input `PwNode`
- `sinks` / `sources` / `streams` — lists of all nodes
- `volume` / `muted` — default sink volume/mute state
- `sourceVolume` / `sourceMuted` — default source
- `setVolume(v)` / `incrementVolume()` / `decrementVolume()`
- `setAudioSink(node)` / `setAudioSource(node)`
- `setStreamVolume(stream, v)` / `setStreamMuted(stream, muted)`
- `cava` — `CavaProvider` for audio visualisation
- `beatTracker` — beat detection

### Brightness (`services/Brightness.qml`)

Per-monitor brightness control supporting brightnessctl, DDC/CI (`ddcutil`), and Apple displays (`asdbctl`).

**Key API:**
- `monitors` — list of `Monitor` objects (one per screen)
- `getMonitorForScreen(screen)` — get monitor for a `ShellScreen`
- `getMonitor(query)` — query by "active", "model:X", "serial:X", "id:N", or name
- `increaseBrightness()` / `decreaseBrightness()`
- `Monitor.brightness` — `real` 0-1
- `Monitor.setBrightness(value)` — set with clamping and DDC rate limiting

### Hypr (`services/Hypr.qml`)

Hyprland compositor integration.

**Key API:**
- `activeToplevel` — currently focused window
- `focusedWorkspace` / `focusedMonitor` / `activeWsId`
- `toplevels` / `workspaces` / `monitors` — all compositor objects
- `keyboard` — main keyboard device
- `capsLock` / `numLock` / `kbLayout` / `kbLayoutFull`
- `dispatch(request)` — send Hyprland dispatch command
- `monitorFor(screen)` — get `HyprlandMonitor` for a `ShellScreen`
- `cycleSpecialWorkspace(direction)` — cycle through special workspaces
- `extras` — `HyprExtras` for batch IPC and option management

### Network (`services/Network.qml`)

WiFi/Ethernet management via NetworkManager/nmcli.

**Key API:**
- `networks` — list of `AccessPoint` objects
- `active` — currently connected AP
- `wifiEnabled` / `scanning`
- `ethernetDevices` / `activeEthernet`
- `connectToNetwork(ssid, password, bssid, callback)`
- `disconnectFromNetwork()` / `forgetNetwork(ssid)`
- `toggleWifi()` / `rescanWifi()`
- `hasSavedProfile(ssid)` — check if credentials are saved

### Notifs (`services/Notifs.qml`)

Notification server implementation (replaces swaync).

**Key API:**
- `list` — all `Notif` objects
- `notClosed` — notifications not yet dismissed
- `popups` — notifications currently showing as popups
- `dnd` — do-not-disturb mode (persisted)
- `Notif.summary` / `.body` / `.appIcon` / `.appName` / `.image`
- `Notif.lock(item)` / `.unlock(item)` — prevent dismissal while UI holds reference
- `Notif.close()` — dismiss

Notifications are persisted to `${Paths.state}/notifs.json` and survive restarts.

### Players (`services/Players.qml`)

MPRIS media player integration.

**Key API:**
- `list` — all `MprisPlayer` objects
- `active` — the currently active player (auto-selected or manual)
- `manualActive` — manually set active player (persisted)
- `getIdentity(player)` — get display name (with alias support)

### Weather (`services/Weather.qml`)

Weather data from Open-Meteo API with geocoding.

**Key API:**
- `city` / `temp` / `feelsLike` / `humidity` / `windSpeed`
- `icon` / `description`
- `sunrise` / `sunset`
- `forecast` — 7-day forecast
- `hourlyForecast` — hourly forecast

Auto-refreshes hourly. Location from config or IP geolocation.

### Time (`services/Time.qml`)

System clock wrapper.

**Key API:**
- `date` — current `Date`
- `hours` / `minutes` / `seconds`
- `timeStr` / `hourStr` / `minuteStr` / `amPmStr`
- `format(fmt)` — format current time

### SystemUsage (`services/SystemUsage.qml`)

System resource monitoring.

**Key API:**
- `cpuName` / `cpuPerc` / `cpuTemp`
- `gpuName` / `gpuPerc` / `gpuTemp` / `gpuType` (NVIDIA, GENERIC, NONE)
- `memUsed` / `memTotal` / `memPerc`
- `storagePerc` / `disks` — aggregated and per-disk storage
- `formatKib(kib)` — format KiB to human-readable
- `refCount` — reference counting; polling only runs when `refCount > 0`

### NetworkUsage (`services/NetworkUsage.qml`)

Network bandwidth monitoring from `/proc/net/dev`.

**Key API:**
- `downloadSpeed` / `uploadSpeed` — bytes/sec
- `downloadTotal` / `uploadTotal` — session totals
- `downloadHistory` / `uploadHistory` — sparkline data (last 30 readings)
- `formatBytes(bytes)` / `formatBytesTotal(bytes)`
- `refCount` — reference counting like SystemUsage

### Wallpapers (`services/Wallpapers.qml`)

Wallpaper management with search (extends `Searcher`).

**Key API:**
- `current` — current wallpaper path (or preview)
- `actualCurrent` — actual current wallpaper
- `setWallpaper(path)` — change wallpaper
- `preview(path)` / `stopPreview()` — wallpaper + colour preview
- `query(search)` — fuzzy search wallpapers (inherited from `Searcher`)

### Recorder (`services/Recorder.qml`)

Screen recording via gpu-screen-recorder.

**Key API:**
- `running` / `paused` / `elapsed` — recording state (all persisted)
- `start(extraArgs)` / `stop()` / `togglePause()`

### GameMode (`services/GameMode.qml`)

Game mode that disables Hyprland eye candy.

**Key API:**
- `enabled` — persisted toggle
- When enabled: disables animations, blur, shadows, gaps, rounding; enables tearing

### IdleInhibitor (`services/IdleInhibitor.qml`)

Prevents idle/sleep.

**Key API:**
- `enabled` — persisted toggle
- `enabledSince` — timestamp when enabled
- Uses Wayland `IdleInhibitor` protocol

### VPN (`services/VPN.qml`)

VPN connection management supporting WireGuard, Cloudflare WARP, NetBird, Tailscale, and custom providers.

**Key API:**
- `connected` / `connecting`
- `connect()` / `disconnect()` / `toggle()`
- `providerName` / `currentConfig`

### Nmcli (`services/Nmcli.qml`)

Low-level NetworkManager CLI wrapper used by `Network`.

### Fcitx (`services/Fcitx.qml`)

Fcitx5 input method framework integration.

### ClaudeSessions (`services/ClaudeSessions.qml`)

Claude AI session management for the integrated chat panel.

---

## Module System

### The Wrapper -> Content Pattern

Every drawer module follows a two-file pattern:

**`Wrapper.qml`** — handles visibility animation and lazy loading:

```qml
Item {
    id: root
    required property PersistentProperties visibilities

    visible: width > 0       // or height > 0
    implicitWidth: 0          // starts hidden

    states: State {
        name: "visible"
        when: root.visibilities.session && Config.session.enabled
        PropertyChanges { root.implicitWidth: content.implicitWidth }
    }

    transitions: [
        Transition { from: ""; to: "visible"
            Anim {
                property: "implicitWidth"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition { from: "visible"; to: ""
            Anim {
                property: "implicitWidth"
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Loader {
        id: content
        // Only active when visible or animating out
        Component.onCompleted: active = Qt.binding(
            () => (root.visibilities.session && Config.session.enabled) || root.visible
        )
        sourceComponent: Content { ... }
    }
}
```

Key aspects:
- `implicitWidth` (or `implicitHeight`) animates from 0 to content size
- `visible: width > 0` means the Item takes no space when hidden
- `Loader.active` uses a binding that keeps content alive during the hide animation
- Show uses `expressiveDefaultSpatial` (500ms, bouncy); hide uses `expressiveFastSpatial` (350ms) + `emphasized`

**`Content.qml`** — the actual panel UI, unaware of animation.

**`Background.qml`** — a `ShapePath` that draws the rounded rectangle background. Connected to the Wrapper's dimensions so it animates in sync. All backgrounds are children of the `Backgrounds` shape in the drawers window.

### Panel Integration with Drawers

Each panel is instantiated inside `Panels.qml` with specific anchoring:

| Module | Position | Anchoring |
|--------|----------|-----------|
| Bar | Top | `anchors.left/right: parent; anchors.top: parent` |
| Dashboard | Top center | `anchors.horizontalCenter: parent; anchors.top: parent` |
| Launcher | Bottom center | `anchors.horizontalCenter: parent; anchors.bottom: parent` |
| Session | Right center | `anchors.verticalCenter: parent; anchors.right: parent` |
| OSD | Right center | `anchors.verticalCenter: parent; anchors.right: parent` (with rightMargin for session/sidebar) |
| Sidebar | Right | `anchors.top: notifications.bottom; anchors.bottom: utilities.top; anchors.right: parent` |
| Notifications | Top right | `anchors.top: parent; anchors.right: parent` |
| Utilities | Bottom right | `anchors.bottom: parent; anchors.right: parent` |
| Popouts | Below bar | Dynamic `x` based on `currentCenter`, `y` based on detached state |
| Claude | Left | `anchors.top/bottom/left: parent` |

Panels that occupy the same edge coordinate with each other using margins. For example, OSD has `anchors.rightMargin: session.width + sidebar.width` so it shifts left when session or sidebar opens.

### The Bar Module

The bar is special — it's not a drawer in `Panels` but a sibling. It uses a configurable `entries` list from `Config.bar.entries`:

```json
[
  { "id": "logo", "enabled": true },
  { "id": "workspaces", "enabled": true },
  { "id": "spacer", "enabled": true },
  { "id": "activeWindow", "enabled": true },
  { "id": "spacer", "enabled": true },
  { "id": "tray", "enabled": true },
  { "id": "clock", "enabled": true },
  { "id": "statusIcons", "enabled": true },
  { "id": "power", "enabled": true }
]
```

`Bar.qml` uses a `Repeater` with `DelegateChooser` to render each entry. Spacer entries get `Layout.fillWidth: true`. The bar supports:
- Scroll actions (workspace switching, volume, brightness) based on mouse position
- Popout panels triggered by hovering over bar components (status icons, tray, active window, clock)
- Show on hover mode with drag-to-reveal

### Popouts

Bar popouts are a special case — they appear below the bar, positioned to follow the hovered bar component. The `BarPopouts.Wrapper` manages:
- `currentName` — which popout to show (e.g., "audio", "battery", "network", `"traymenu3"`)
- `currentCenter` — x-coordinate binding from the bar component
- `isDetached` — for full-screen modes (window info, control center)
- `hasCurrent` — controls visibility

The `Content.qml` inside popouts uses a similar `Comp` (Loader) pattern to lazily load each popout type.

---

## State Management

### PersistentProperties

`PersistentProperties` is a QuickShell built-in that persists QML property values across quickshell reloads (e.g., when configuration changes trigger a reload). Properties declared inside `PersistentProperties` survive the reload.

Used throughout the shell:

```qml
// Per-screen drawer visibility (in Drawers.qml)
PersistentProperties {
    id: visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar
    property bool claude
    Component.onCompleted: Visibilities.load(scope.modelData, this)
}

// Notification DND state
PersistentProperties {
    property bool dnd
    reloadableId: "notifs"
}

// Recording state
PersistentProperties {
    property bool running: false
    property bool paused: false
    property real elapsed: 0
    reloadableId: "recorder"
}
```

The `reloadableId` is needed when there are multiple `PersistentProperties` of the same type — it disambiguates them across reloads.

### Visibilities Service

`services/Visibilities.qml` is the central registry for per-screen visibility state:

```qml
Singleton {
    property var screens: new Map()   // Map<HyprlandMonitor, PersistentProperties>
    property var bars: new Map()      // Map<ShellScreen, BarWrapper>

    function load(screen, visibilities): void {
        screens.set(Hypr.monitorFor(screen), visibilities);
    }

    function getForActive(): PersistentProperties {
        return screens.get(Hypr.focusedMonitor);
    }
}
```

This lets any code (shortcuts, IPC handlers) toggle drawers on the focused monitor:

```qml
// In Shortcuts.qml
CustomShortcut {
    name: "launcher"
    onReleased: {
        const visibilities = Visibilities.getForActive();
        visibilities.launcher = !visibilities.launcher;
    }
}
```

### Focus Grab

When panels that need keyboard focus are open (launcher, session, sidebar, claude), a `HyprlandFocusGrab` activates. When the user clicks outside the grabbed window, `onCleared` fires and resets all visibility flags:

```qml
HyprlandFocusGrab {
    active: visibilities.launcher || visibilities.session || ...
    windows: [win]
    onCleared: {
        visibilities.launcher = false;
        visibilities.session = false;
        // ...
    }
}
```

### Fullscreen Awareness

When a window is fullscreen on the active workspace, drawer toggling is suppressed:

```qml
readonly property bool hasFullscreen: Hypr.monitorFor(screen)
    ?.activeWorkspace?.toplevels.values
    .some(t => t.lastIpcObject.fullscreen === 2) ?? false

onHasFullscreenChanged: {
    visibilities.launcher = false;
    visibilities.session = false;
    visibilities.dashboard = false;
    visibilities.claude = false;
}
```

---

## IPC

QuickShell provides an IPC mechanism through `IpcHandler`. The shell registers multiple IPC targets that can be called from the command line:

```sh
quickshell ipc call <target> <function> [args...]
```

### Registered IPC Targets

**`drawers`** — toggle any drawer:
```sh
quickshell ipc call drawers toggle launcher
quickshell ipc call drawers toggle sidebar
quickshell ipc call drawers list   # lists available drawer names
```

**`controlCenter`**:
```sh
quickshell ipc call controlCenter open
```

**`clipboard`**:
```sh
quickshell ipc call clipboard open   # opens launcher (for clipboard mode)
```

**`toaster`** — show toast notifications:
```sh
quickshell ipc call toaster info "Title" "Message" "icon_name"
quickshell ipc call toaster success "Title" "Message" "icon_name"
quickshell ipc call toaster warn "Title" "Message" "icon_name"
quickshell ipc call toaster error "Title" "Message" "icon_name"
```

**`wallpaper`**:
```sh
quickshell ipc call wallpaper get          # current wallpaper path
quickshell ipc call wallpaper set /path/to/image.jpg
quickshell ipc call wallpaper list         # all wallpapers
```

**`brightness`**:
```sh
quickshell ipc call brightness get                    # active monitor
quickshell ipc call brightness getFor "model:LG..."   # specific monitor
quickshell ipc call brightness set "0.5"              # absolute
quickshell ipc call brightness set "+0.1"             # relative increase
quickshell ipc call brightness set "10%-"             # relative decrease
quickshell ipc call brightness setFor "active" "80%"  # percentage
```

**`notifs`**:
```sh
quickshell ipc call notifs clear
quickshell ipc call notifs toggleDnd
quickshell ipc call notifs isDndEnabled
```

**`mpris`**:
```sh
quickshell ipc call mpris playPause
quickshell ipc call mpris next
quickshell ipc call mpris previous
quickshell ipc call mpris list
quickshell ipc call mpris getActive trackTitle
```

**`gameMode`**:
```sh
quickshell ipc call gameMode toggle
quickshell ipc call gameMode isEnabled
```

**`idleInhibitor`**:
```sh
quickshell ipc call idleInhibitor toggle
quickshell ipc call idleInhibitor isEnabled
```

**`hypr`**:
```sh
quickshell ipc call hypr refreshDevices
quickshell ipc call hypr cycleSpecialWorkspace next
quickshell ipc call hypr listSpecialWorkspaces
```

### Global Shortcuts

In addition to IPC, the shell registers Hyprland global shortcuts via `CustomShortcut` (which wraps `GlobalShortcut { appid: "caelestia" }`). These are bound in the Hyprland config like:

```
bind = SUPER, D, global, caelestia:launcher
bind = SUPER, Period, global, caelestia:session
bind = SUPER, A, global, caelestia:dashboard
```

Available shortcut names:
- `launcher`, `session`, `dashboard`, `sidebar`, `utilities`, `claude`
- `showall` — toggle launcher + dashboard + OSD + utilities together
- `controlCenter`
- `launcherInterrupt` — used by SUPER key to prevent accidental launcher toggle
- `brightnessUp`, `brightnessDown`
- `mediaToggle`, `mediaPrev`, `mediaNext`, `mediaStop`
- `clearNotifs`
- `refreshDevices`

---

## Utility Modules

### Paths (`utils/Paths.qml`)

Singleton providing all filesystem paths:

```qml
Paths.home          // $HOME
Paths.data          // ~/.local/share/caelestia
Paths.state         // ~/.local/state/caelestia
Paths.cache         // ~/.cache/caelestia
Paths.config        // ~/.config/caelestia
Paths.wallsdir      // wallpaper directory (configurable)
Paths.recsdir       // recordings directory
Paths.imagecache    // image cache
```

### Strings (`utils/Strings.qml`)

```qml
Strings.testRegexList(filterList, target)
// Tests target against a list of strings/regexes. Strings starting with ^ and
// ending with $ are treated as regexes, others as exact matches.
```

### Searcher (`utils/Searcher.qml`)

Base class for fuzzy/fzf search. Used by `Wallpapers`, launcher `Apps`, `Actions`, etc.:

```qml
Searcher {
    list: someList
    key: "name"
    useFuzzy: true   // true = fuzzysort, false = fzf
    function query(search): list<var>  // returns filtered+sorted results
}
```

### Icons (`utils/Icons.qml`)

Weather code to Material icon mapping.

### Images (`utils/Images.qml`)

Valid image extension list for file dialogs.

### SysInfo (`utils/SysInfo.qml`)

System information utilities.

---

## File Layout Summary

```
quickshell/
  shell.qml              Entry point (ShellRoot)
  config/
    Config.qml            Singleton — FileView + JsonAdapter
    Appearance.qml        Singleton — shorthand for Config.appearance
    AppearanceConfig.qml  Rounding, spacing, padding, fonts, animations, transparency
    BarConfig.qml          Bar entries, sizes, popout toggles
    LauncherConfig.qml     Max shown, fuzzy search, vim keybinds
    ...Config.qml          One per module
  services/
    Colours.qml           Material 3 palette + transparency
    Audio.qml             PipeWire audio
    Brightness.qml        Per-monitor brightness
    Hypr.qml              Hyprland compositor
    Network.qml           WiFi/Ethernet via nmcli
    Notifs.qml            Notification server
    Players.qml           MPRIS media
    Weather.qml           Open-Meteo weather
    Time.qml              System clock
    SystemUsage.qml       CPU/GPU/RAM/disk
    NetworkUsage.qml      Bandwidth monitoring
    Wallpapers.qml        Wallpaper management
    Recorder.qml          Screen recording
    GameMode.qml          Game mode
    IdleInhibitor.qml     Idle prevention
    Visibilities.qml      Per-screen drawer state registry
    VPN.qml               VPN management
    Nmcli.qml             NetworkManager CLI wrapper
    Fcitx.qml             Input method
    ClaudeSessions.qml    Claude AI sessions
  components/
    Anim.qml / CAnim.qml  Preconfigured NumberAnimation / ColorAnimation
    StyledRect.qml         Rectangle + color animation
    StyledText.qml         Text + font defaults + color animation
    MaterialIcon.qml       Material Symbols font icon
    StateLayer.qml         Hover/press/ripple interaction
    StyledClippingRect.qml Clipping rect with color animation
    controls/              IconButton, StyledSwitch, StyledSlider, etc.
    containers/            StyledWindow, StyledFlickable, StyledListView
    effects/               Elevation, ColouredIcon, Colouriser, InnerBorder
    images/                CachingImage, CachingIconImage
    misc/                  CustomShortcut, Ref
    filedialog/            File picker components
    widgets/               ExtraIndicator
  modules/
    Shortcuts.qml          Global keybinds + IPC handlers
    BatteryMonitor.qml     Low battery warnings
    IdleMonitors.qml       Idle timeout management
    drawers/
      Drawers.qml          Per-screen full-screen window
      Panels.qml           All drawer Wrappers
      Backgrounds.qml      All drawer ShapePaths
      Interactions.qml     Mouse hover/drag detection
      Border.qml           Screen-edge border
      Exclusions.qml       WlrLayershell exclusion zones
    bar/                   Status bar (BarWrapper, Bar, components/, popouts/)
    launcher/              App launcher (Wrapper, Content, AppList, services/)
    dashboard/             System dashboard (Wrapper, Content, tabs)
    session/               Session menu (Wrapper, Content)
    notifications/         Popup notifications (Wrapper, Content)
    sidebar/               Notification center (Wrapper, Content)
    osd/                   On-screen display (Wrapper, Content)
    utilities/             Recording, idle inhibit, toasts (Wrapper, Content)
    background/            Wallpaper, desktop clock, visualiser
    lock/                  Screen lock with PAM
    controlcenter/         Full settings GUI
    claude/                Claude AI chat panel
    windowinfo/            Window inspector
    areapicker/            Screen area selection
  utils/
    Paths.qml              Filesystem path constants
    Strings.qml            String/regex utilities
    Searcher.qml           Fuzzy/fzf search base
    Icons.qml              Weather icon mapping
    Images.qml             Image extension list
    SysInfo.qml            System info
    NetworkConnection.qml  Network connection helper
    scripts/               fzf.js, fuzzysort.js
  docs/
    ARCHITECTURE.md        This file
```
