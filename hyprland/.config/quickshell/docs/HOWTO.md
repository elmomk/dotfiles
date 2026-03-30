# QuickShell HOWTO Guide

Practical step-by-step recipes for extending and customizing the Caelestia QuickShell desktop shell.

All paths are relative to `~/.config/quickshell/` unless stated otherwise.

---

## Table of Contents

1. [How to Add a New Bar Entry](#1-how-to-add-a-new-bar-entry)
2. [How to Add a New Panel/Drawer](#2-how-to-add-a-new-paneldrawer)
3. [How to Create a New Popout](#3-how-to-create-a-new-popout)
4. [How to Add a New Service](#4-how-to-add-a-new-service)
5. [How to Modify the Color Scheme](#5-how-to-modify-the-color-scheme)
6. [How to Add a New Launcher Item Type](#6-how-to-add-a-new-launcher-item-type)
7. [How to Add a New Notification Action](#7-how-to-add-a-new-notification-action)
8. [How to Customize Animations](#8-how-to-customize-animations)
9. [How to Add a New Config Option](#9-how-to-add-a-new-config-option)
10. [How to Add Keyboard Shortcuts](#10-how-to-add-keyboard-shortcuts)
11. [How to Debug QuickShell](#11-how-to-debug-quickshell)
12. [How to Add a New Sidebar Widget](#12-how-to-add-a-new-sidebar-widget)

---

## 1. How to Add a New Bar Entry

The bar is driven by a configurable `entries` list in `config/BarConfig.qml`. Each entry is rendered by a `DelegateChooser` in `modules/bar/Bar.qml`.

### Step 1: Register the entry ID in the config

In `config/BarConfig.qml`, add your entry to the default `entries` list:

```qml
property list<var> entries: [
    // ... existing entries ...
    {
        id: "myWidget",
        enabled: true
    }
]
```

### Step 2: Create the bar component

Create `modules/bar/components/MyWidget.qml`:

```qml
import qs.components
import qs.services
import qs.config
import QtQuick

StyledRect {
    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full
    implicitWidth: label.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: Config.bar.sizes.innerWidth

    StyledText {
        id: label
        anchors.centerIn: parent
        text: "Hello"
        color: Colours.palette.m3secondary
    }
}
```

### Step 3: Add a DelegateChoice in Bar.qml

In `modules/bar/Bar.qml`, add a new `DelegateChoice` inside the `DelegateChooser`:

```qml
DelegateChoice {
    roleValue: "myWidget"
    delegate: WrappedLoader {
        sourceComponent: MyWidget {}
    }
}
```

The `WrappedLoader` component (defined at the bottom of Bar.qml) handles visibility via the `enabled` property from the entries config. It reads `enabled` and `id` from the model automatically.

### Step 4: Position it

The order in the `entries` array controls left-to-right position. Use `{ id: "spacer", enabled: true }` to push items apart.

---

## 2. How to Add a New Panel/Drawer

Panels are overlay UI that slide in from screen edges. Examples: sidebar (right), launcher (bottom), dashboard (top), session (right), claude (left).

### Step 1: Create the module directory

Create `modules/mypanel/` with three files following the established pattern:

**modules/mypanel/Wrapper.qml** -- Controls visibility and animation:

```qml
import qs.components
import qs.config
import QtQuick

Item {
    id: root

    required property var visibilities

    visible: width > 0
    implicitWidth: 0

    states: State {
        name: "visible"
        when: root.visibilities.mypanel && Config.mypanel.enabled

        PropertyChanges {
            root.implicitWidth: Config.mypanel.sizes.width
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Loader {
        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        active: (root.visibilities.mypanel && Config.mypanel.enabled) || root.visible

        sourceComponent: Content {
            // your content here
        }
    }
}
```

**modules/mypanel/Content.qml** -- The actual panel content.

**modules/mypanel/Background.qml** -- A `ShapePath` that draws the panel's background shape. Follow the pattern in `modules/sidebar/Background.qml` or `modules/launcher/Background.qml`.

### Step 2: Register the visibility flag

In `modules/drawers/Drawers.qml`, the `PersistentProperties` block defines all visibility flags:

```qml
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
    property bool mypanel      // <-- add this
    // ...
}
```

### Step 3: Add to Panels.qml

In `modules/drawers/Panels.qml`, import your module and instantiate the Wrapper:

```qml
import qs.modules.mypanel as MyPanel

// Inside the Item:
MyPanel.Wrapper {
    id: mypanel

    visibilities: root.visibilities

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left   // or whichever edge
}
```

Also export it as a readonly property:

```qml
readonly property alias mypanel: mypanel
```

### Step 4: Add the Background shape

In `modules/drawers/Backgrounds.qml`, add:

```qml
MyPanel.Background {
    wrapper: root.panels.mypanel
    startX: 0
    startY: 0
}
```

### Step 5: Add a config section

See [How to Add a New Config Option](#9-how-to-add-a-new-config-option).

### Step 6: Wire up focus grab if needed

In `modules/drawers/Drawers.qml`, if your panel needs keyboard focus, add it to the `HyprlandFocusGrab.active` binding and `onCleared` handler, and to `WlrLayershell.keyboardFocus`.

---

## 3. How to Create a New Popout

Popouts appear below the bar when hovering over status icons. They are defined in `modules/bar/popouts/`.

### Step 1: Create the popout content

Create `modules/bar/popouts/MyPopout.qml`:

```qml
import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Appearance.spacing.normal
    implicitWidth: Config.bar.sizes.networkWidth  // or define your own size

    StyledText {
        text: "My Popout Title"
        color: Colours.palette.m3primary
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: "Some content here"
        color: Colours.palette.m3onSurface
    }
}
```

### Step 2: Register it in Content.qml

In `modules/bar/popouts/Content.qml`, add a `Popout` entry inside the `content` Item:

```qml
Popout {
    name: "mypopout"
    sourceComponent: MyPopout {}
}
```

The `Popout` component (defined at the bottom of Content.qml as an inline component) is a `Loader` that automatically handles show/hide animations based on `root.wrapper.currentName === name`.

### Step 3: Trigger it from a status icon

To trigger the popout from a status icon in `modules/bar/components/StatusIcons.qml`, add a `WrappedLoader`:

```qml
WrappedLoader {
    name: "mypopout"     // must match the Popout name in Content.qml
    active: true         // or bind to a config toggle

    sourceComponent: MaterialIcon {
        animate: true
        text: "my_icon_name"
        color: root.colour
    }
}
```

The `name` property on `WrappedLoader` is what gets set as `popouts.currentName` when the icon is hovered (handled in `Bar.qml`'s `checkPopout` function).

### Step 4: Optionally add a config toggle

In `config/BarConfig.qml`, add to the `Popouts` component:

```qml
component Popouts: JsonObject {
    // ...existing...
    property bool mypopout: true
}
```

And guard the icon's `active` property: `active: Config.bar.popouts.mypopout`

---

## 4. How to Add a New Service

Services are singletons in `services/` that provide shared state and functionality.

### Step 1: Create the service

Create `services/MyService.qml`:

```qml
pragma Singleton

import qs.config
import Quickshell
import QtQuick

Singleton {
    id: root

    property string someState: "initial"
    property int counter: 0

    function doSomething(): void {
        counter++;
    }

    // Optional: watch a file for state changes
    FileView {
        path: `${Paths.state}/myservice.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const data = JSON.parse(text());
            root.someState = data.state;
        }
    }

    // Optional: timer for periodic updates
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.doSomething()
    }
}
```

### Step 2: Use it anywhere

Since services use `pragma Singleton` and are in the `qs.services` module, they are automatically available by filename throughout the codebase. Access it as `MyService.someState` or `MyService.doSomething()` from any QML file that imports `qs.services`.

### Existing services reference

| Service | File | Purpose |
|---------|------|---------|
| `Audio` | `services/Audio.qml` | PipeWire volume, sinks, sources, streams, cava |
| `Brightness` | `services/Brightness.qml` | Screen brightness |
| `Colours` | `services/Colours.qml` | M3 color palette, scheme loading, transparency |
| `Notifs` | `services/Notifs.qml` | Notification server, DnD, persistence |
| `Visibilities` | `services/Visibilities.qml` | Per-screen panel visibility state |
| `Weather` | `services/Weather.qml` | Weather data |
| `Players` | `services/Players.qml` | MPRIS media players |
| `Network` | `services/Network.qml` | Network state |
| `Wallpapers` | `services/Wallpapers.qml` | Wallpaper management |
| `Recorder` | `services/Recorder.qml` | Screen recording |
| `IdleInhibitor` | `services/IdleInhibitor.qml` | Idle inhibition |
| `GameMode` | `services/GameMode.qml` | GameMode detection |
| `ClaudeSessions` | `services/ClaudeSessions.qml` | Claude Code session tracking |
| `Fcitx` | `services/Fcitx.qml` | Fcitx5 input method |

---

## 5. How to Modify the Color Scheme

Colors are managed by `services/Colours.qml` which exposes an M3 (Material 3) palette.

### Using colors in components

Always use `Colours.palette.m3*` for raw colors or `Colours.tPalette.m3*` for transparency-aware colors:

```qml
import qs.services

StyledRect {
    color: Colours.tPalette.m3surfaceContainer    // transparency-aware
}

StyledText {
    color: Colours.palette.m3primary              // raw palette color
}
```

### Key color tokens

| Token | Usage |
|-------|-------|
| `m3primary` | Primary accent |
| `m3onPrimary` | Text/icon on primary |
| `m3secondary` | Secondary accent |
| `m3surface` | Base surface |
| `m3surfaceContainer` | Elevated surface |
| `m3surfaceContainerHigh` | Higher elevated surface |
| `m3onSurface` | Text on surfaces |
| `m3onSurfaceVariant` | Secondary text on surfaces |
| `m3outline` | Borders and dividers |
| `m3error` / `m3success` | Semantic colors |
| `m3tertiary` | Tertiary accent |

### Applying transparency layers

Use `Colours.layer(color, layerLevel)` for transparency support:

```qml
color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
```

- Layer `0` = base transparency
- Layer `1` or higher = progressively adjusted for readability

### Switching light/dark mode

Programmatically:

```qml
Colours.setMode("light")   // or "dark"
```

This calls `caelestia scheme set --notify -m <mode>`.

### Changing the scheme

From the launcher, type `>scheme ` to browse and apply schemes. The scheme is loaded from `$XDG_STATE_HOME/scheme.json` by `Colours.load()`.

---

## 6. How to Add a New Launcher Item Type

The launcher uses a state machine in `modules/launcher/AppList.qml` to switch between different item types based on search prefix.

### Step 1: Create the service (search provider)

Create `modules/launcher/services/MySearch.qml`:

```qml
pragma Singleton

import ".."
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(Config.launcher.actionPrefix.length + "mysearch ".length);
    }

    list: myItems.instances
    useFuzzy: false

    Variants {
        id: myItems
        model: [
            { name: "Item 1", desc: "Description 1", icon: "star" },
            { name: "Item 2", desc: "Description 2", icon: "favorite" }
        ]

        MyItem {}
    }

    component MyItem: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string desc: modelData.desc
        readonly property string icon: modelData.icon

        function onClicked(list: AppList): void {
            list.visibilities.launcher = false;
            // Do something with this item
        }
    }
}
```

The `Searcher` base component (from `utils/Searcher.qml`) handles filtering and fuzzy matching.

### Step 2: Create the item delegate

Create `modules/launcher/items/MySearchItem.qml`. Follow the pattern of `items/ActionItem.qml`:

```qml
import "../services"
import qs.components
import qs.services
import qs.config
import QtQuick

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Config.launcher.sizes.itemHeight
    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        id: stateLayer
        radius: Appearance.rounding.normal

        function onClicked(): void {
            root.modelData?.onClicked(root.list);
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: Appearance.padding.smaller
        anchors.leftMargin: Appearance.padding.larger
        anchors.rightMargin: Appearance.padding.larger

        MaterialIcon {
            id: icon
            text: root.modelData?.icon ?? ""
            font.pointSize: Appearance.font.size.extraLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Appearance.spacing.normal
            anchors.verticalCenter: icon.verticalCenter
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name
                text: root.modelData?.name ?? ""
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                id: desc
                text: root.modelData?.desc ?? ""
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
                anchors.top: name.bottom
            }
        }
    }
}
```

### Step 3: Register the state in AppList.qml

In `modules/launcher/AppList.qml`, add a new state and its delegate:

```qml
// In the states array:
State {
    name: "mysearch"

    PropertyChanges {
        model.values: MySearch.query(search.text)
        root.delegate: mySearchItem
    }
}

// Add the component at the bottom:
Component {
    id: mySearchItem

    MySearchItem {
        list: root
    }
}
```

### Step 4: Add the state transition trigger

In the `state` binding at the top of `AppList.qml`, add your prefix:

```qml
state: {
    const text = search.text;
    const prefix = Config.launcher.actionPrefix;
    if (text.startsWith(prefix)) {
        for (const action of ["calc", "scheme", "variant", "clip", "claude", "mysearch"])
            if (text.startsWith(`${prefix}${action} `))
                return action;
        return "actions";
    }
    return "apps";
}
```

### Step 5: Add an action entry to make it discoverable

In `config/LauncherConfig.qml`, add to the `actions` list:

```qml
{
    name: "My Search",
    icon: "search",
    description: "Search my custom items",
    command: ["autocomplete", "mysearch"],
    enabled: true,
    dangerous: false
}
```

This lets users type `>` to see the action, then select it to autocomplete to `>mysearch `.

---

## 7. How to Add a New Notification Action

Notification actions are rendered in `modules/sidebar/NotifActionList.qml`.

### How it works

The action list model always includes a close button and copy button, with the notification's own actions in between:

```qml
Repeater {
    model: [
        { isClose: true },
        ...root.notif.actions,
        { isCopy: true }
    ]
    // ...
}
```

### Adding a custom built-in action

To add a new always-present action (like close and copy), extend the model array:

```qml
model: [
    { isClose: true },
    ...root.notif.actions,
    { isCopy: true },
    { isMyAction: true }       // <-- add here
]
```

Then handle it in the `StateLayer`'s `onClicked`:

```qml
function onClicked(): void {
    if (action.modelData.isClose) {
        root.notif.close();
    } else if (action.modelData.isCopy) {
        Quickshell.clipboardText = root.notif.body;
        actionInner.item.text = "inventory";
        copyTimer.start();
    } else if (action.modelData.isMyAction) {
        // Your custom action logic
        console.log("Custom action on:", root.notif.summary);
    } else if (action.modelData.invoke) {
        action.modelData.invoke();
    } else if (!root.notif.resident) {
        root.notif.close();
    }
}
```

And add an icon for it in the `sourceComponent` selector:

```qml
sourceComponent: action.modelData.isClose || action.modelData.isCopy || action.modelData.isMyAction
    ? iconBtn : root.notif.hasActionIcons ? iconComp : textComp
```

### Understanding notification data

Each notification (`Notifs.Notif` in `services/Notifs.qml`) has:

- `summary` -- notification title
- `body` -- notification body text
- `appName` -- sending application name
- `appIcon` -- application icon
- `image` -- notification image path
- `actions` -- list of `{ identifier, text, invoke() }` objects
- `urgency` -- `NotificationUrgency.Low/Normal/Critical`
- `resident` -- whether to keep after action invoked

---

## 8. How to Customize Animations

### Animation components

There are two animation primitives in `components/`:

- **`Anim`** (`components/Anim.qml`) -- `NumberAnimation` with default duration and curve
- **`CAnim`** (`components/CAnim.qml`) -- `ColorAnimation` with default duration and curve

Both default to:
```qml
duration: Appearance.anim.durations.normal    // 400ms at scale 1.0
easing.type: Easing.BezierSpline
easing.bezierCurve: Appearance.anim.curves.standard
```

### Adjusting global animation speed

Change `appearance.anim.durations.scale` in `shell.json`:

```json
{
  "appearance": {
    "anim": {
      "durations": {
        "scale": 1.5
      }
    }
  }
}
```

All durations multiply by this scale: `small` (200), `normal` (400), `large` (600), `extraLarge` (1000).

Setting scale to `0` effectively disables animations.

### Available curves (from AppearanceConfig.qml)

```
Appearance.anim.curves.emphasized
Appearance.anim.curves.emphasizedAccel
Appearance.anim.curves.emphasizedDecel
Appearance.anim.curves.standard
Appearance.anim.curves.standardAccel
Appearance.anim.curves.standardDecel
Appearance.anim.curves.expressiveFastSpatial
Appearance.anim.curves.expressiveDefaultSpatial
Appearance.anim.curves.expressiveEffects
```

### Available durations

```
Appearance.anim.durations.small                  // 200ms * scale
Appearance.anim.durations.normal                 // 400ms * scale
Appearance.anim.durations.large                  // 600ms * scale
Appearance.anim.durations.extraLarge             // 1000ms * scale
Appearance.anim.durations.expressiveFastSpatial  // 350ms * scale
Appearance.anim.durations.expressiveDefaultSpatial // 500ms * scale
Appearance.anim.durations.expressiveEffects      // 200ms * scale
```

### Using animations in your components

Simple property animation:

```qml
Behavior on opacity {
    Anim {}    // uses defaults: 400ms, standard curve
}
```

Custom duration and curve:

```qml
Behavior on implicitWidth {
    Anim {
        duration: Appearance.anim.durations.expressiveDefaultSpatial
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
```

Color transitions:

```qml
Behavior on color {
    CAnim {}
}
```

Hover scale (common pattern):

```qml
scale: hovered ? Appearance.interaction.hoverScale : 1.0

Behavior on scale {
    Anim {
        duration: Appearance.anim.durations.small
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
```

### Panel show/hide pattern

Panels use `states` and `transitions` for slide-in/slide-out. For example, sidebar uses `implicitWidth` animation:

```qml
states: State {
    name: "visible"
    when: root.visibilities.sidebar && Config.sidebar.enabled

    PropertyChanges {
        root.implicitWidth: Config.sidebar.sizes.width
    }
}

transitions: [
    Transition {
        from: ""
        to: "visible"
        Anim {
            target: root; property: "implicitWidth"
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    },
    Transition {
        from: "visible"
        to: ""
        Anim {
            target: root; property: "implicitWidth"
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }
]
```

---

## 9. How to Add a New Config Option

Config is stored in `shell.json`, loaded via `FileView` + `JsonAdapter` in `config/Config.qml`.

### Step 1: Create or extend a config component

To add a new config section, create `config/MyPanelConfig.qml`:

```qml
import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int dragThreshold: 50
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property real scale: 1
        property int width: 400 * scale
    }
}
```

To add a property to an existing section, just add it to the relevant `JsonObject`.

### Step 2: Register in Config.qml

In `config/Config.qml`, add the property alias and the adapter property:

```qml
// At the top (aliases):
property alias mypanel: adapter.mypanel

// Inside the JsonAdapter:
property MyPanelConfig mypanel: MyPanelConfig {}
```

### Step 3: Add serialization

Still in `config/Config.qml`, add a serializer function and call it from `serializeConfig()`:

```qml
function serializeMyPanel(): var {
    return {
        enabled: mypanel.enabled,
        dragThreshold: mypanel.dragThreshold,
        sizes: {
            scale: mypanel.sizes.scale,
            width: mypanel.sizes.width
        }
    };
}

// In serializeConfig():
function serializeConfig(): var {
    return {
        // ...existing...
        mypanel: serializeMyPanel()
    };
}
```

### Step 4: Use it

Access from any QML file:

```qml
import qs.config

// Direct:
Config.mypanel.enabled
Config.mypanel.sizes.width

// Save after changing:
Config.mypanel.enabled = false
Config.save()
```

### Step 5: Configure in shell.json

```json
{
  "mypanel": {
    "enabled": true,
    "dragThreshold": 50,
    "sizes": {
      "scale": 1,
      "width": 400
    }
  }
}
```

---

## 10. How to Add Keyboard Shortcuts

Shortcuts use Hyprland's `GlobalShortcut` protocol via the `CustomShortcut` component.

### In QuickShell (the handler)

Shortcuts are defined in `modules/Shortcuts.qml`:

```qml
import qs.components.misc

CustomShortcut {
    name: "myshortcut"
    description: "Do my custom thing"
    onPressed: {
        const visibilities = Visibilities.getForActive();
        visibilities.mypanel = !visibilities.mypanel;
    }
}
```

`CustomShortcut` (`components/misc/CustomShortcut.qml`) extends `GlobalShortcut` with `appid: "caelestia"`.

### In Hyprland (the keybind)

In `~/.config/hypr/conf/keybinds.conf`, bind the key:

```
bind = $mainMod, X, global, caelestia:myshortcut
```

The format is `global, <appid>:<name>`.

### Existing shortcuts

| Name | Hyprland bind | Action |
|------|--------------|--------|
| `launcher` | `$mainMod, space` via IPC | Toggle launcher |
| `session` | `$mainMod, M` via IPC | Toggle session menu |
| `sidebar` | `$mainMod, n` via IPC | Toggle sidebar |
| `claude` | `$mainMod, c` via IPC | Toggle Claude panel |
| `dashboard` | global shortcut | Toggle dashboard |
| `utilities` | global shortcut | Toggle utilities |
| `showall` | global shortcut | Toggle all panels |
| `controlCenter` | global shortcut | Open control center |
| `clearNotifs` | global shortcut | Clear all notifications |

Note: Some shortcuts use IPC (`qs ipc call drawers toggle <name>`) instead of global shortcuts. Both approaches work.

### Using IPC instead

In `modules/Shortcuts.qml`, IPC handlers are defined:

```qml
IpcHandler {
    target: "drawers"

    function toggle(drawer: string): void {
        const visibilities = Visibilities.getForActive();
        visibilities[drawer] = !visibilities[drawer];
    }

    function list(): string {
        const visibilities = Visibilities.getForActive();
        return Object.keys(visibilities).filter(k => typeof visibilities[k] === "boolean").join("\n");
    }
}
```

From Hyprland config:

```
bind = $mainMod, X, exec, qs ipc call drawers toggle mypanel
```

### Toaster IPC

Send toast notifications from scripts:

```bash
qs ipc call toaster info "Title" "Message" "icon_name"
qs ipc call toaster warn "Warning" "Something happened" "warning"
qs ipc call toaster error "Error" "Something broke" "error"
```

---

## 11. How to Debug QuickShell

### Viewing logs

QuickShell logs to stdout/stderr. If running as a systemd service:

```bash
journalctl --user -u quickshell -f
```

Or run directly:

```bash
qs
```

### QML console.log

Add debug output anywhere in QML:

```qml
console.log("my value:", someProperty)
console.warn("something unexpected")
console.error("something broke")
```

### Reloading

QuickShell supports hot reload. The config file (`shell.json`) is watched via `FileView` with `watchChanges: true` -- any external edit triggers automatic reload.

For a full shell reload:

```bash
qs          # restart quickshell
```

### IPC debugging

List available drawers:

```bash
qs ipc call drawers list
```

Toggle specific drawer:

```bash
qs ipc call drawers toggle launcher
```

Check DnD status:

```bash
qs ipc call notifs isDndEnabled
```

### Config debugging

The config system emits toasts on load/save. If you see "Failed to load config" or "Failed to serialize config" toasts, check the JSON syntax in `~/.config/quickshell/shell.json`.

To verify config is loading correctly:

```qml
Component.onCompleted: {
    console.log("Config loaded, bar entries:", JSON.stringify(Config.bar.entries))
}
```

### Common issues

- **Panel not showing**: Check `Config.xxx.enabled` is true, visibility flag is set, and the panel is wired in `Panels.qml`
- **Colors wrong**: Check `Colours.palette` vs `Colours.tPalette` -- use `tPalette` for transparency-aware colors
- **Animations not working**: Check `Appearance.anim.durations.scale` is not 0
- **Keybind not working**: Verify the `CustomShortcut.name` matches the Hyprland `global, caelestia:<name>` exactly

### Environment variables

Set in `shell.qml` pragmas:

```
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
```

---

## 12. How to Add a New Sidebar Widget

The sidebar (`modules/sidebar/`) displays notification history. To add a widget above or below the notification list:

### Step 1: Edit Content.qml

In `modules/sidebar/Content.qml`, the layout is a `ColumnLayout`. Add your widget:

```qml
ColumnLayout {
    id: layout

    anchors.fill: parent
    spacing: Appearance.spacing.normal

    // Add a widget above notifications
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: myWidget.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainerLow

        MyWidget {
            id: myWidget
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
        }
    }

    // Existing notification dock
    StyledRect {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainerLow

        NotifDock {
            props: root.props
            visibilities: root.visibilities
        }
    }

    // Divider
    StyledRect {
        Layout.topMargin: Appearance.padding.large - layout.spacing
        Layout.fillWidth: true
        implicitHeight: 1
        color: Colours.tPalette.m3outlineVariant
    }
}
```

### Step 2: Create your widget

Create `modules/sidebar/MyWidget.qml`:

```qml
import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Appearance.spacing.small

    StyledText {
        text: "My Widget"
        color: Colours.palette.m3primary
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: "Widget content goes here"
        color: Colours.palette.m3onSurface
        font.pointSize: Appearance.font.size.normal
    }
}
```

### Sidebar sizing

The sidebar width is controlled by `Config.sidebar.sizes.width` (default: 430). Content gets `width - padding * 2` of usable space. Keep widgets within this width.

### Accessing sidebar props

The sidebar has a `Props` object (`modules/sidebar/Props.qml`) shared between widgets. If you need shared state between sidebar widgets, add properties there and access via `root.props`.
