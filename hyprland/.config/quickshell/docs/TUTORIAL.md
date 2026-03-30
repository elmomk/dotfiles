# QuickShell Tutorial: Building a Desktop Shell from Scratch

A progressive, hands-on guide for building Wayland desktop shells with QuickShell.
You should know Linux basics and have some programming experience, but no prior QML
or QuickShell knowledge is assumed.

---

## Table of Contents

- [Part 1: Foundations](#part-1-foundations)
- [Part 2: Core Concepts](#part-2-core-concepts)
- [Part 3: Building a Basic Bar](#part-3-building-a-basic-bar)
- [Part 4: Interactivity](#part-4-interactivity)
- [Part 5: Advanced Patterns](#part-5-advanced-patterns)
- [Part 6: Services and System Integration](#part-6-services-and-system-integration)
- [Part 7: Polish and Production](#part-7-polish-and-production)

---

## Part 1: Foundations

### What is QuickShell?

QuickShell is a toolkit for building Wayland desktop shells using QML, the Qt
declarative UI language. A "desktop shell" means all the UI elements that sit
around your windows: the status bar, notification popups, app launcher, OSD
overlays, session menus, lock screens, and more.

Where tools like waybar give you a preconfigured bar with limited customization,
QuickShell gives you a blank canvas and a full programming language. You write
your shell as a QML program that QuickShell hosts on the Wayland compositor's
layer shell protocol.

Think of it as the difference between configuring a bar and *building* one.

### Why QuickShell over alternatives?

| Feature | waybar | eww | ags | QuickShell |
|---|---|---|---|---|
| Language | JSON/CSS | Yuck/SCSS | TypeScript | QML/JavaScript |
| GPU accelerated | No | No | Yes (GTK) | Yes (Qt Scene Graph) |
| Type system | None | Weak | TypeScript | QML + typed JS |
| Hot reload | Restart | Restart | Partial | Full live reload |
| Animations | CSS transitions | Limited | GTK transitions | Full animation system |
| Multi-monitor | Config per output | Manual | Manual | Built-in Variants model |
| Compositor IPC | None | None | None | Built-in IPC system |
| System services | Modules | Scripts | Libraries | Native Pipewire, UPower, MPRIS, Bluetooth, Notifications |

The key advantages:

- **Native system integration**: QuickShell has built-in bindings for PipeWire
  (audio), UPower (battery), MPRIS (media), Bluetooth, and the notification
  protocol. No shell scripts or polling needed.
- **Real animations**: Qt's animation framework gives you hardware-accelerated
  animations with easing curves, state machines, and transitions.
- **Declarative + reactive**: Properties automatically update when their
  dependencies change. Change one value and everything that depends on it
  recomputes.
- **Multi-monitor as a first-class concept**: The `Variants` type creates
  per-screen instances of your shell automatically.

### Prerequisites and Installation

**Requirements:**
- A Wayland compositor (Hyprland, Sway, etc.)
- Qt 6.x
- QuickShell

**Installation on Arch Linux:**

```bash
# From the AUR
paru -S quickshell-git
# or
yay -S quickshell-git
```

**First run:**

```bash
# QuickShell looks for ~/.config/quickshell/shell.qml by default
mkdir -p ~/.config/quickshell
```

### QML Crash Course

QML is a declarative language for building UIs. If you know JSON, HTML, or CSS,
it will feel somewhat familiar. Here are the core concepts you need.

#### Objects and Properties

Every QML element is an object with properties. Properties are typed and can be
bound to expressions:

```qml
import QtQuick

Rectangle {
    width: 200
    height: 100
    color: "steelblue"
    radius: 10
}
```

This creates a 200x100 blue rounded rectangle. `width`, `height`, `color`, and
`radius` are all properties of the `Rectangle` type.

#### Property Bindings

The killer feature of QML is reactive bindings. When you assign an expression
to a property, it automatically re-evaluates whenever any dependency changes:

```qml
Rectangle {
    width: parent.width / 2    // Always half of parent's width
    height: width * 0.5        // Always half of this rectangle's width
    color: mouseArea.pressed ? "red" : "blue"  // Changes on click
}
```

No event listeners, no manual updates. Change `parent.width` and both `width`
and `height` update automatically.

#### Custom Properties

You can define your own properties on any object:

```qml
Rectangle {
    property string label: "Hello"
    property int count: 0
    property bool active: false
    property real opacity_value: 0.8
    property color accent: "#ff5555"
    property list<string> items: ["one", "two", "three"]
}
```

Use `readonly property` for values that should not be reassigned from outside:

```qml
Rectangle {
    readonly property int doubleWidth: width * 2
}
```

#### Signals and Handlers

Objects emit signals, and you handle them with `onSignalName` handlers:

```qml
MouseArea {
    onClicked: console.log("Clicked!")
    onPressed: console.log("Mouse down")
    onReleased: console.log("Mouse up")
}

Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: console.log("Tick")
}
```

You can define custom signals:

```qml
Item {
    signal activated(string name)

    // Emit it from JavaScript:
    Component.onCompleted: activated("test")

    // Handle it:
    onActivated: name => console.log("Activated:", name)
}
```

#### Anchors

Anchors are the primary layout mechanism. They connect edges of items to edges
of other items:

```qml
Item {
    anchors.fill: parent                    // Fill entire parent
    anchors.centerIn: parent                // Center in parent
    anchors.left: parent.left               // Snap left edge
    anchors.right: parent.right             // Snap right edge
    anchors.margins: 10                     // 10px margin on all sides
    anchors.leftMargin: 20                  // Override left margin
    anchors.verticalCenter: parent.verticalCenter  // Center vertically
}
```

#### Layouts

For arranging multiple items in rows or columns:

```qml
import QtQuick.Layouts

RowLayout {
    spacing: 8

    Rectangle { width: 50; height: 50; color: "red" }
    Rectangle { width: 50; height: 50; color: "green" }
    Rectangle { Layout.fillWidth: true; height: 50; color: "blue" }
}

ColumnLayout {
    spacing: 8

    Text { text: "Line 1" }
    Text { text: "Line 2" }
    Text { text: "Line 3" }
}
```

#### Components and Loaders

A `component` defines a reusable inline type. A `Loader` instantiates it
on demand:

```qml
Item {
    // Define a reusable component inline
    component MyButton: Rectangle {
        property string label: ""
        width: 100; height: 40
        color: "gray"
        radius: 5

        Text {
            anchors.centerIn: parent
            text: parent.label
        }
    }

    // Use it multiple times
    MyButton { label: "OK"; x: 0 }
    MyButton { label: "Cancel"; x: 120 }

    // Or load conditionally
    Loader {
        active: someCondition
        sourceComponent: MyButton { label: "Dynamic" }
    }
}
```

#### JavaScript in QML

QML embeds JavaScript. You can write functions, use standard JS APIs, and
mix JS freely with QML:

```qml
Item {
    property int count: 0

    function increment(): void {
        count += 1;
        console.log(`Count is now ${count}`);
    }

    function formatTime(date: date): string {
        return Qt.formatDateTime(date, "HH:mm:ss");
    }

    MouseArea {
        anchors.fill: parent
        onClicked: parent.increment()
    }
}
```

### Your First QuickShell Window

Create `~/.config/quickshell/shell.qml`:

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    PanelWindow {
        anchors.top: true
        anchors.left: true
        anchors.right: true

        implicitHeight: 40
        color: "#1a1a2e"

        Text {
            anchors.centerIn: parent
            text: "Hello, QuickShell!"
            color: "#e0e0e0"
            font.pointSize: 14
        }
    }
}
```

Run it:

```bash
quickshell
# Or, to specify a config path:
quickshell -p ~/.config/quickshell
```

You should see a bar at the top of your screen with "Hello, QuickShell!" in the
center. The bar sits on the Wayland layer shell, which means it stays above
your windows and reserves screen space (an "exclusive zone") so windows do not
overlap it.

Press Ctrl+C in the terminal to stop QuickShell.

---

## Part 2: Core Concepts

### ShellRoot

Every QuickShell config starts with `ShellRoot`. It is the root object that
contains all your shell windows and global components. There is exactly one
per shell instance:

```qml
import Quickshell

ShellRoot {
    // All your windows, singletons, and global state go here
}
```

### PanelWindow and the Layer Shell

`PanelWindow` creates a Wayland layer shell surface. This is the fundamental
window type for desktop shell elements:

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    PanelWindow {
        // Which edges to anchor to (true = stick to that edge)
        anchors.top: true
        anchors.left: true
        anchors.right: true

        // Height of the bar
        implicitHeight: 48

        // Exclusive zone: how much space to reserve
        // (prevents windows from overlapping the bar)
        exclusiveZone: 48

        // Layer shell namespace (for compositor rules)
        WlrLayershell.namespace: "my-bar"

        // Background color
        color: "#1e1e2e"

        // Keyboard focus behavior
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // Layer: Background, Bottom, Top, or Overlay
        // WlrLayershell.layer: WlrLayer.Top

        Text {
            anchors.centerIn: parent
            text: "My Bar"
            color: "white"
        }
    }
}
```

The anchors here are *layer shell anchors*, not the QML layout anchors from
Part 1. When you anchor to opposite edges (left + right), the window stretches
to fill that dimension. When you anchor to a single edge, the window's
`implicitWidth`/`implicitHeight` determines its size on that axis.

**Exclusive zones** tell the compositor to keep a region clear. A bar anchored
to the top with `exclusiveZone: 48` causes all windows to start 48 pixels from
the top.

### Variants, Scope, and ShellScreen: Multi-Monitor

QuickShell has a built-in model `Quickshell.screens` that lists all connected
monitors. The `Variants` type creates one instance of its child for each item
in a model. Combined with `Scope` (which holds per-instance state), this gives
you per-monitor shells:

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: scope
            required property ShellScreen modelData

            PanelWindow {
                screen: scope.modelData   // Assign this window to its screen
                anchors.top: true
                anchors.left: true
                anchors.right: true
                implicitHeight: 40
                color: "#1e1e2e"

                Text {
                    anchors.centerIn: parent
                    text: `Bar on ${scope.modelData.name}`
                    color: "white"
                }
            }
        }
    }
}
```

This creates one bar per monitor. If you plug in a second screen, a new bar
appears automatically. Unplug it and the bar disappears. No configuration
needed.

This pattern is used extensively in the Caelestia shell; see
`modules/drawers/Drawers.qml` for a real example with multi-monitor support,
per-screen visibility state, and layer shell configuration.

### Window Types

QuickShell provides several window types:

- **PanelWindow**: Layer shell surface. Used for bars, overlays, popups, and
  anything that should not be managed as a normal window.
- **FloatingWindow**: A regular window managed by the compositor (can be moved,
  resized, focused).

In the Caelestia shell, `StyledWindow` (at `components/containers/StyledWindow.qml`)
wraps `PanelWindow` with a namespace and transparent background:

```qml
// components/containers/StyledWindow.qml
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property string name

    WlrLayershell.namespace: `myshell-${name}`
    color: "transparent"
}
```

### Singletons and the Service Pattern

QuickShell supports QML singletons: objects that exist once and are accessible
globally by name. This is the standard way to create shared services:

```qml
// services/Time.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property date date: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
```

Now any file in your project can use `Time.format("HH:mm")` or bind to
`Time.hours` and it will automatically update every second.

The Caelestia shell uses this pattern heavily. Key singletons include:
- `Config` -- reads and writes `shell.json` configuration
- `Appearance` -- shorthand access to theme values (rounding, spacing, fonts)
- `Colours` -- Material 3 color palette with transparency support
- `Time` -- system clock with formatted output
- `Audio` -- PipeWire sink/source control
- `Hypr` -- Hyprland workspace, monitor, and toplevel state
- `Visibilities` -- per-monitor panel visibility state
- `Notifs` -- notification server and notification list
- `Players` -- MPRIS media player control

### The Config Entry Point

The shell.qml file is the entry point. In the Caelestia shell, it looks like
this:

```qml
// shell.qml
import "modules"
import "modules/drawers"
import "modules/background"
import Quickshell

ShellRoot {
    Background {}
    Drawers {}

    Shortcuts {}
    BatteryMonitor {}
}
```

Everything is composed from modules. `Drawers` creates the per-monitor
layer shell windows that contain the bar, launcher, dashboard, sidebar, OSD,
notifications, and session menu. `Shortcuts` registers global keybindings.
`BatteryMonitor` watches battery levels and sends warnings.

---

## Part 3: Building a Basic Bar

Let us build a real status bar, step by step.

### Step 1: The Bar Window

```qml
// shell.qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: scope
            required property ShellScreen modelData

            PanelWindow {
                screen: scope.modelData
                anchors.top: true
                anchors.left: true
                anchors.right: true
                implicitHeight: 48
                exclusiveZone: 48
                color: "#1e1e2e"

                WlrLayershell.namespace: "my-bar"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "My Shell"
                        color: "#cba6f7"
                        font.pointSize: 13
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }  // Spacer

                    Text {
                        text: "Right side"
                        color: "#a6adc8"
                        font.pointSize: 11
                    }
                }
            }
        }
    }
}
```

### Step 2: Adding a Clock

Replace the "Right side" text with a real clock. QuickShell provides
`SystemClock`:

```qml
import Quickshell

// Inside your RowLayout:
Text {
    id: clock

    color: "#cba6f7"
    font.pointSize: 12
    font.family: "monospace"
    text: Qt.formatDateTime(systemClock.date, "HH:mm")

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }
}
```

`SystemClock` emits updates at the specified precision. Binding `text` to a
format expression means the clock updates automatically.

For a singleton approach (like the Caelestia shell does in `services/Time.qml`),
you would put the `SystemClock` in a singleton and reference `Time.format("HH:mm")`
from the bar.

### Step 3: Workspace Indicators (Hyprland)

If you use Hyprland, QuickShell has built-in Hyprland integration:

```qml
import Quickshell.Hyprland
import QtQuick.Layouts

// Inside your RowLayout, after the logo text:
RowLayout {
    spacing: 4

    Repeater {
        model: 5  // Show 5 workspace buttons

        Rectangle {
            required property int index

            readonly property int wsId: index + 1
            readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId
            readonly property bool isOccupied: Hyprland.workspaces.values.some(
                w => w.id === wsId && w.lastIpcObject.windows > 0
            )

            width: 28
            height: 28
            radius: 14
            color: isActive ? "#cba6f7" : isOccupied ? "#45475a" : "transparent"

            border.width: isOccupied && !isActive ? 1 : 0
            border.color: "#585b70"

            Text {
                anchors.centerIn: parent
                text: parent.wsId.toString()
                color: parent.isActive ? "#1e1e2e" : "#a6adc8"
                font.pointSize: 10
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${parent.wsId}`)
            }
        }
    }
}
```

The key API:
- `Hyprland.focusedWorkspace` -- currently focused workspace
- `Hyprland.workspaces` -- ObjectModel of all workspaces
- `Hyprland.dispatch(cmd)` -- send a Hyprland dispatcher command
- `Hyprland.focusedMonitor` -- the monitor with keyboard focus
- `Hyprland.monitorFor(screen)` -- get the HyprlandMonitor for a ShellScreen

In the Caelestia shell, the workspace component at
`modules/bar/components/workspaces/Workspaces.qml` handles per-monitor
workspaces, special workspaces, active indicators, and click-to-switch.

### Step 4: System Tray

QuickShell provides `SystemTray` for the freedesktop StatusNotifierItem
protocol:

```qml
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick.Layouts

RowLayout {
    spacing: 4

    Repeater {
        model: SystemTray.items

        Image {
            required property SystemTrayItem modelData

            source: modelData.icon
            width: 20
            height: 20
            fillMode: Image.PreserveAspectFit

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: event => {
                    if (event.button === Qt.RightButton)
                        modelData.activate();
                    else
                        modelData.secondaryActivate();
                }
            }
        }
    }
}
```

### Step 5: Styling

Here is a complete styled bar pulling everything together:

```qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: scope
            required property ShellScreen modelData

            PanelWindow {
                screen: scope.modelData
                anchors.top: true
                anchors.left: true
                anchors.right: true
                implicitHeight: 48
                exclusiveZone: 48
                color: "#1e1e2e"
                WlrLayershell.namespace: "my-bar"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    // Logo
                    Text {
                        text: "\uf313"  // Nerd Font Linux icon
                        color: "#cba6f7"
                        font.pointSize: 16
                        font.family: "CaskaydiaCove NF"
                    }

                    // Workspaces
                    Row {
                        spacing: 4
                        Repeater {
                            model: 5
                            Rectangle {
                                required property int index
                                readonly property int ws: index + 1
                                readonly property bool active: Hyprland.focusedWorkspace?.id === ws
                                width: active ? 24 : 8
                                height: 8
                                radius: 4
                                color: active ? "#cba6f7" : "#45475a"

                                Behavior on width {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch(`workspace ${parent.ws}`)
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Clock
                    Text {
                        color: "#cdd6f4"
                        font.pointSize: 12
                        font.family: "monospace"
                        text: Qt.formatDateTime(clk.date, "ddd MMM d  HH:mm")

                        SystemClock {
                            id: clk
                            precision: SystemClock.Minutes
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Battery (if present)
                    Text {
                        visible: false  // Enable on laptops
                        color: "#a6e3a1"
                        font.pointSize: 12
                        text: "BAT"
                    }
                }
            }
        }
    }
}
```

---

## Part 4: Interactivity

### MouseArea and Click Handlers

`MouseArea` is the primary way to handle mouse input:

```qml
Rectangle {
    width: 100; height: 40
    color: mouse.pressed ? "#45475a" : mouse.containsMouse ? "#313244" : "#1e1e2e"
    radius: 8

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: console.log("Clicked")
        onDoubleClicked: console.log("Double clicked")
        onWheel: event => {
            if (event.angleDelta.y > 0)
                console.log("Scroll up");
            else
                console.log("Scroll down");
        }
    }

    Text {
        anchors.centerIn: parent
        text: "Click Me"
        color: "white"
    }
}
```

`HoverHandler` provides a lighter-weight alternative when you only need hover
detection (used extensively in the Caelestia bar for icon scaling):

```qml
Item {
    HoverHandler {
        id: hover
    }

    scale: hover.hovered ? 1.15 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 150 }
    }
}
```

### Popups and Popouts

A popup appears when hovering over or clicking a bar item. The Caelestia shell
implements this with a "popouts" system where hovering over a bar item sets
the `currentName` of a shared `Wrapper` component, which then loads the
appropriate content.

Here is a simplified popup pattern:

```qml
Item {
    id: root

    property bool showPopup: false

    // Trigger area (e.g., a bar icon)
    Rectangle {
        id: trigger
        width: 32; height: 32
        color: "#313244"
        radius: 8

        Text {
            anchors.centerIn: parent
            text: "\uf017"
            color: "white"
            font.family: "CaskaydiaCove NF"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.showPopup = true
            onExited: root.showPopup = false
        }
    }

    // Popup content
    Rectangle {
        anchors.top: trigger.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: trigger.horizontalCenter

        width: 200
        height: contentColumn.implicitHeight + 20

        color: "#1e1e2e"
        radius: 12
        opacity: root.showPopup ? 1 : 0
        scale: root.showPopup ? 1 : 0.9
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 200 } }

        Column {
            id: contentColumn
            anchors.centerIn: parent
            spacing: 4

            Text { text: "Popup content"; color: "white" }
            Text { text: "More info here"; color: "#a6adc8" }
        }
    }
}
```

### Animations

Qt provides a rich animation system. The core types:

#### NumberAnimation

Animates numeric properties:

```qml
Rectangle {
    width: 100; height: 40
    color: "#cba6f7"
    radius: 8

    // Animate width changes over 300ms
    Behavior on width {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
}
```

#### ColorAnimation

Animates color transitions:

```qml
Rectangle {
    color: active ? "#cba6f7" : "#313244"

    Behavior on color {
        ColorAnimation { duration: 200 }
    }
}
```

#### Behavior

`Behavior` attaches an animation to a property. Whenever that property changes
(from any source), the animation plays:

```qml
Rectangle {
    x: targetX
    Behavior on x { NumberAnimation { duration: 400 } }

    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200 } }
}
```

#### States and Transitions

For coordinated multi-property animations, use `states` and `transitions`:

```qml
Rectangle {
    id: panel
    width: 0
    opacity: 0
    clip: true

    states: State {
        name: "visible"
        when: shouldShow

        PropertyChanges {
            panel.width: 300
            panel.opacity: 1
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 500
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    duration: 300
                }
            }
        },
        Transition {
            from: "visible"
            to: ""

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 300
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "opacity"
                    duration: 200
                }
            }
        }
    ]
}
```

The Caelestia shell uses this pattern heavily. Look at
`modules/bar/BarWrapper.qml` for a real example: the bar slides in from the
top when shown, using a state that changes `implicitHeight` and transitions
with Material Design easing curves.

#### SequentialAnimation and ParallelAnimation

Chain or parallelize animations:

```qml
SequentialAnimation {
    // First, fade out
    NumberAnimation { target: item; property: "opacity"; to: 0; duration: 150 }
    // Then change the property
    PropertyAction { target: item; property: "text" }
    // Then fade back in
    NumberAnimation { target: item; property: "opacity"; to: 1; duration: 150 }
}
```

This is how `StyledText` (at `components/StyledText.qml`) animates icon and
text changes: scale down, swap content, scale back up.

### Material Design Easing Curves

The Caelestia shell uses Material 3 easing curves defined as Bezier splines.
These are defined in `config/AppearanceConfig.qml`:

```qml
// Standard curve: general-purpose motion
property list<real> standard: [0.2, 0, 0, 1, 1, 1]

// Emphasized: dramatic, attention-drawing motion
property list<real> emphasized: [0.05, 0, 2/15, 0.06, 1/6, 0.4, 5/24, 0.82, 0.25, 1, 1, 1]

// Expressive spatial: playful, overshooting motion for panels
property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
```

Use them like this:

```qml
NumberAnimation {
    duration: 400
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]  // Standard curve
}
```

The Caelestia shell wraps this in a reusable `Anim` component
(`components/Anim.qml`) so every animation in the shell uses consistent timing:

```qml
// components/Anim.qml
import QtQuick

NumberAnimation {
    duration: Appearance.anim.durations.normal   // 400ms by default
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.curves.standard
}
```

Then throughout the codebase, instead of writing `NumberAnimation` with
parameters, you just write `Anim {}` or `Anim { duration: Appearance.anim.durations.small }`.

### Drag Interactions

The Caelestia shell supports drag-to-reveal panels. The logic lives in
`modules/drawers/Interactions.qml`. The basic pattern:

```qml
MouseArea {
    property point dragStart

    anchors.fill: parent
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)

    onPositionChanged: event => {
        if (!pressed) return;

        const dragY = event.y - dragStart.y;

        // Drag down to show, drag up to hide
        if (dragY > 20)
            showPanel = true;
        else if (dragY < -20)
            showPanel = false;
    }
}
```

---

## Part 5: Advanced Patterns

### IPC System

QuickShell has a built-in IPC (inter-process communication) system. You
register handlers in QML, then call them from the command line:

```qml
// In your shell:
IpcHandler {
    target: "mybar"

    function toggle(panel: string): void {
        if (panel === "launcher")
            showLauncher = !showLauncher;
    }

    function getVolume(): string {
        return Audio.volume.toString();
    }
}
```

Call from the command line:

```bash
# Call a void function
qs ipc call mybar toggle launcher

# Call a function that returns a value
qs ipc call mybar getVolume
```

The Caelestia shell registers IPC handlers for drawers, notifications, media,
clipboard, and toasts. See `modules/Shortcuts.qml` for examples:

```qml
IpcHandler {
    target: "drawers"

    function toggle(drawer: string): void {
        const visibilities = Visibilities.getForActive();
        visibilities[drawer] = !visibilities[drawer];
    }

    function list(): string {
        const visibilities = Visibilities.getForActive();
        return Object.keys(visibilities)
            .filter(k => typeof visibilities[k] === "boolean")
            .join("\n");
    }
}
```

This lets you bind keybindings in your compositor config:

```ini
# In hyprland.conf
bind = SUPER, D, exec, qs ipc call drawers toggle launcher
bind = SUPER, N, exec, qs ipc call notifs toggleDnd
```

### Process Integration

Run external commands and read their output:

```qml
import Quickshell.Io

Item {
    Process {
        id: proc
        command: ["hostname"]
        running: true

        stdout: SplitParser {
            onRead: data => hostLabel.text = data
        }
    }

    Text {
        id: hostLabel
        color: "white"
    }
}
```

For long-running processes that stream output (like `nmcli monitor`), the
process stays alive and `SplitParser` fires `onRead` for each line:

```qml
Process {
    running: true
    command: ["nmcli", "m"]

    stdout: SplitParser {
        onRead: {
            // Called for every line of nmcli monitor output
            refreshNetworks();
        }
    }
}
```

For one-shot commands, use `Quickshell.execDetached()`:

```qml
MouseArea {
    onClicked: Quickshell.execDetached(["notify-send", "Hello", "World"])
}
```

### PersistentProperties

`PersistentProperties` saves state across QuickShell reloads. When QuickShell
live-reloads your config, normal properties reset. Persistent properties
survive:

```qml
PersistentProperties {
    id: state

    property bool launcher: false
    property bool sidebar: false
    property bool dashboard: false
}
```

The Caelestia shell uses this for panel visibility (`modules/drawers/Drawers.qml`)
and notification DND state (`services/Notifs.qml`).

### Loader Pattern: Lazy Loading

Use `Loader` to defer creation of heavy components until they are needed:

```qml
Loader {
    // Only create the component when it should be visible
    active: shouldShow || visible  // Keep active during hide animation

    sourceComponent: HeavyDashboard {
        // ... complex content
    }
}
```

The Caelestia bar uses this pattern for every section. In `modules/bar/Bar.qml`,
each bar entry is wrapped in a `Loader` that only activates when `enabled`
is true:

```qml
component WrappedLoader: Loader {
    required property bool enabled
    visible: enabled
    active: enabled
}
```

This means disabled bar sections consume zero resources.

### FileView and JsonAdapter: Config Management

`FileView` reads and watches files. Combined with `JsonAdapter`, it provides
reactive configuration:

```qml
import Quickshell.Io

FileView {
    id: fileView
    path: "/path/to/config.json"
    watchChanges: true          // Re-read when file changes on disk

    onFileChanged: reload()     // Reload when file changes externally
    onLoaded: {
        // File contents available via text()
        const data = JSON.parse(text());
        console.log("Config loaded:", data.someSetting);
    }
    onLoadFailed: err => console.warn("Load failed:", err)
}
```

`JsonAdapter` maps JSON data onto QML properties automatically:

```qml
FileView {
    path: "config.json"
    watchChanges: true
    onFileChanged: reload()

    JsonAdapter {
        id: adapter
        property BarSettings bar: BarSettings {}
        property ThemeSettings theme: ThemeSettings {}
    }
}

// Elsewhere define the settings as JsonObject components:
component BarSettings: JsonObject {
    property bool persistent: true
    property int height: 48
    property list<string> excludedScreens: []
}
```

When `config.json` contains `{"bar": {"persistent": false, "height": 64}}`,
the QML properties update to match. Defaults from the QML definition are used
for any missing keys.

The Caelestia shell's config system (`config/Config.qml`) uses this pattern to
manage all settings in a single `shell.json` file with live reload and
save-back support.

### Custom Components and Reusability

Create reusable components by putting them in separate `.qml` files. The
filename becomes the type name:

```
components/
    IconButton.qml
    StatusPill.qml
```

```qml
// components/IconButton.qml
import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property color iconColor: "white"
    signal clicked()

    width: 32; height: 32
    radius: 16
    color: mouse.pressed ? "#45475a" : mouse.containsMouse ? "#313244" : "transparent"

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.family: "Material Symbols Rounded"
        font.pointSize: 16
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
```

Use it:

```qml
import "components"

Row {
    spacing: 4
    IconButton { icon: "settings"; onClicked: openSettings() }
    IconButton { icon: "power_settings_new"; onClicked: openSession() }
}
```

For inline reusable types (within a single file), use the `component` keyword:

```qml
Item {
    component Pill: Rectangle {
        property string label
        width: pillText.implicitWidth + 16
        height: 24
        radius: 12
        color: "#313244"

        Text {
            id: pillText
            anchors.centerIn: parent
            text: parent.label
            color: "white"
            font.pointSize: 10
        }
    }

    Row {
        spacing: 4
        Pill { label: "WiFi" }
        Pill { label: "BT" }
        Pill { label: "VPN" }
    }
}
```

---

## Part 6: Services and System Integration

### Audio (PipeWire)

QuickShell has native PipeWire integration:

```qml
import Quickshell.Services.Pipewire

Item {
    // Get the default audio sink
    readonly property PwNode sink: Pipewire.defaultAudioSink

    // Read volume (0.0 to 1.0+)
    readonly property real volume: sink?.audio?.volume ?? 0

    // Read mute state
    readonly property bool muted: !!sink?.audio?.muted

    // Set volume
    function setVolume(v: real): void {
        if (sink?.audio) {
            sink.audio.volume = Math.max(0, Math.min(1.5, v));
            sink.audio.muted = false;
        }
    }

    // Toggle mute
    function toggleMute(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // Track objects so properties update
    PwObjectTracker {
        objects: [sink]
    }

    Text {
        text: `Vol: ${Math.round(volume * 100)}%${muted ? " [MUTED]" : ""}`
        color: "white"
    }
}
```

The Caelestia shell's `services/Audio.qml` wraps this with helper functions for
increment/decrement, per-stream control, and source (microphone) management.

### Notifications

QuickShell implements the freedesktop notification protocol:

```qml
import Quickshell.Services.Notifications

Item {
    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            // Track the notification so it persists
            notif.tracked = true;

            console.log("New notification:", notif.summary);
            console.log("Body:", notif.body);
            console.log("App:", notif.appName);
            console.log("Icon:", notif.appIcon);

            // Access actions
            for (const action of notif.actions) {
                console.log("Action:", action.text);
                // action.invoke() to trigger it
            }

            // Dismiss after timeout
            // notif.dismiss()
        }
    }
}
```

The Caelestia shell's `services/Notifs.qml` builds on this with persistence
(saving notifications to disk), grouping, popup/sidebar display, DND mode,
and IPC control.

### Hyprland Integration

The full Hyprland API available in QuickShell:

```qml
import Quickshell.Hyprland

Item {
    // Workspaces
    readonly property var allWorkspaces: Hyprland.workspaces.values
    readonly property var focusedWs: Hyprland.focusedWorkspace
    readonly property int activeWsId: focusedWs?.id ?? 1

    // Monitors
    readonly property var focusedMon: Hyprland.focusedMonitor
    readonly property var allMonitors: Hyprland.monitors.values

    // Windows (toplevels)
    readonly property var allWindows: Hyprland.toplevels.values
    readonly property var activeWindow: Hyprland.activeToplevel

    // Dispatch commands
    function switchWorkspace(id: int): void {
        Hyprland.dispatch(`workspace ${id}`);
    }

    function moveToWorkspace(id: int): void {
        Hyprland.dispatch(`movetoworkspace ${id}`);
    }

    function toggleFullscreen(): void {
        Hyprland.dispatch("fullscreen 0");
    }

    // Listen to raw events
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "workspace")
                console.log("Workspace changed");
            else if (event.name === "activewindow")
                console.log("Active window changed");
        }
    }

    // Focus grab: capture all clicks outside your window
    HyprlandFocusGrab {
        active: showingPopup
        windows: [myWindow]
        onCleared: showingPopup = false  // User clicked outside
    }
}
```

The Caelestia shell's `services/Hypr.qml` wraps the raw Hyprland bindings with
keyboard layout tracking, special workspace cycling, caps/num lock detection,
and event-driven refresh of workspaces/monitors/toplevels.

### UPower (Battery)

```qml
import Quickshell.Services.UPower

Item {
    readonly property real batteryPercent: UPower.displayDevice.percentage
    readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
    readonly property bool onBattery: UPower.onBattery

    Text {
        text: `${Math.round(batteryPercent * 100)}%${charging ? " CHG" : ""}`
        color: batteryPercent < 0.2 ? "#f38ba8" : "#a6e3a1"
    }
}
```

### Bluetooth

```qml
import Quickshell.Bluetooth

Item {
    readonly property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)

    Text {
        text: {
            if (!btEnabled) return "BT Off";
            if (connectedDevices.length > 0)
                return `BT: ${connectedDevices.length} devices`;
            return "BT";
        }
        color: "white"
    }
}
```

### MPRIS (Media Players)

```qml
import Quickshell.Services.Mpris

Item {
    readonly property MprisPlayer player: Mpris.players.values[0] ?? null

    Column {
        Text {
            text: player?.trackTitle ?? "No media"
            color: "white"
        }
        Text {
            text: player?.trackArtist ?? ""
            color: "#a6adc8"
        }
    }

    Row {
        spacing: 8

        Text {
            text: "prev"
            color: "white"
            MouseArea {
                anchors.fill: parent
                onClicked: player?.previous()
            }
        }
        Text {
            text: player?.playbackState === MprisPlaybackState.Playing ? "pause" : "play"
            color: "white"
            MouseArea {
                anchors.fill: parent
                onClicked: player?.togglePlaying()
            }
        }
        Text {
            text: "next"
            color: "white"
            MouseArea {
                anchors.fill: parent
                onClicked: player?.next()
            }
        }
    }
}
```

### Desktop Entries and App Launching

QuickShell can read `.desktop` files for app launching:

```qml
import Quickshell
import Quickshell.Services.DesktopEntries

Item {
    // Get all desktop entries
    readonly property var apps: DesktopEntries.applications.values

    // Launch an app
    function launchApp(entry: DesktopEntry): void {
        entry.execute();
    }

    // Search apps
    function searchApps(query: string): list<DesktopEntry> {
        const q = query.toLowerCase();
        return apps.filter(a =>
            a.name.toLowerCase().includes(q) ||
            a.comment?.toLowerCase().includes(q)
        );
    }
}
```

---

## Part 7: Polish and Production

### Performance Tips

**Use Loader for conditional content.** Components inside an inactive `Loader`
consume no resources:

```qml
// Good: only created when needed
Loader {
    active: showBattery
    sourceComponent: BatteryWidget {}
}

// Bad: always created, just hidden
BatteryWidget {
    visible: showBattery  // Still exists in memory, still runs bindings
}
```

**Avoid binding loops.** A binding loop is when property A depends on B which
depends on A. QML will warn you in the console:

```
QML Rectangle: Binding loop detected for property "width"
```

Fix by breaking the cycle, usually with explicit values or one-way bindings.

**Use `readonly property` for computed values.** This signals to the engine
that the property will never be imperatively assigned:

```qml
readonly property int totalWidth: leftPanel.width + rightPanel.width + spacing
```

**Minimize JavaScript in bindings.** Complex JS in a binding re-runs every
time any dependency changes. Extract to a function or cache results:

```qml
// Avoid: runs reduce() on every workspace change
readonly property var occupied: Hyprland.workspaces.values.reduce(...)

// Better for very hot paths: cache the result
property var _occupiedCache: ({})
Connections {
    target: Hyprland
    function onWorkspacesChanged() {
        _occupiedCache = Hyprland.workspaces.values.reduce(...);
    }
}
```

### Theming: Building a Color System

The Caelestia shell uses Material 3 color tokens. Here is a simplified version
you can adapt:

```qml
// services/Theme.qml
pragma Singleton
import Quickshell

Singleton {
    // Surface colors (backgrounds)
    readonly property color surface: "#1e1e2e"
    readonly property color surfaceContainer: "#313244"
    readonly property color surfaceContainerHigh: "#45475a"

    // Content colors (text, icons)
    readonly property color onSurface: "#cdd6f4"
    readonly property color onSurfaceVariant: "#a6adc8"

    // Accent colors
    readonly property color primary: "#cba6f7"
    readonly property color onPrimary: "#1e1e2e"
    readonly property color secondary: "#f5c2e7"
    readonly property color tertiary: "#f38ba8"
    readonly property color error: "#f38ba8"
    readonly property color success: "#a6e3a1"

    // Spacing and rounding
    readonly property int radiusSmall: 8
    readonly property int radiusNormal: 12
    readonly property int radiusLarge: 20
    readonly property int radiusFull: 1000

    readonly property int spacingSmall: 4
    readonly property int spacingNormal: 8
    readonly property int spacingLarge: 16
}
```

Use it everywhere:

```qml
Rectangle {
    color: Theme.surfaceContainer
    radius: Theme.radiusNormal

    Text {
        text: "Hello"
        color: Theme.onSurface
    }
}
```

The full Caelestia approach generates the entire palette from a wallpaper-derived
color scheme using Material 3 color science (see `services/Colours.qml`).

### Transparency and Blur

For transparent panels with blur, set the window color to transparent and use
`MultiEffect`:

```qml
import QtQuick.Effects

PanelWindow {
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.12, 0.12, 0.18, 0.85)  // Semi-transparent
        radius: 12

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.5)
            blurMax: 15
        }
    }
}
```

Note: actual background blur (blurring what is behind the window) requires
compositor support. On Hyprland, set the `layerrule` for your namespace:

```ini
# hyprland.conf
layerrule = blur, my-bar
layerrule = ignorealpha 0.3, my-bar
```

### Animation Choreography

For polished UI, stagger animations so elements do not all appear at once:

```qml
Column {
    spacing: 4

    Repeater {
        model: items

        Rectangle {
            required property int index

            opacity: 0
            y: 20

            // Stagger: each item starts 50ms after the previous
            Component.onCompleted: {
                staggerTimer.interval = index * 50;
                staggerTimer.start();
            }

            Timer {
                id: staggerTimer
                onTriggered: {
                    parent.opacity = 1;
                    parent.y = 0;
                }
            }

            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }
}
```

Use different durations for enter and exit to make interactions feel responsive.
The Caelestia shell uses faster exit animations (350ms) than enter animations
(500ms), following Material Design guidance:

```qml
transitions: [
    Transition {
        from: ""; to: "visible"
        NumberAnimation {
            duration: 500   // Slower entrance
            easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1]  // Expressive with overshoot
        }
    },
    Transition {
        from: "visible"; to: ""
        NumberAnimation {
            duration: 350   // Faster exit
            easing.bezierCurve: [0.05, 0, 2/15, 0.06, 1/6, 0.4, 5/24, 0.82, 0.25, 1, 1, 1]
        }
    }
]
```

### Multi-Monitor: Per-Screen State

When using `Variants` for multi-monitor, you need per-screen state. The
Caelestia shell solves this with `PersistentProperties` per scope and a global
`Visibilities` singleton that maps monitors to their state:

```qml
Variants {
    model: Quickshell.screens

    Scope {
        id: scope
        required property ShellScreen modelData

        PersistentProperties {
            id: visibility
            property bool bar: true
            property bool launcher: false
            property bool dashboard: false
        }

        PanelWindow {
            screen: scope.modelData
            // Use visibility.bar, visibility.launcher, etc.
        }
    }
}
```

To control panels on the focused monitor from global shortcuts, maintain a map:

```qml
// services/Visibilities.qml
pragma Singleton
import Quickshell

Singleton {
    property var screens: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        screens.set(Hyprland.monitorFor(screen), visibilities);
    }

    function getForActive(): var {
        return screens.get(Hyprland.focusedMonitor);
    }
}
```

Then from a shortcut handler:

```qml
function toggleLauncher(): void {
    const v = Visibilities.getForActive();
    v.launcher = !v.launcher;
}
```

### Debugging

**console.log**: Your primary tool. Output appears in the terminal where you
launched QuickShell:

```qml
Component.onCompleted: {
    console.log("Loaded with", Quickshell.screens.length, "screens");
    console.log("Focused monitor:", Hyprland.focusedMonitor?.name);
}
```

**QML warnings**: QuickShell prints type errors, null access warnings, and
binding loop warnings to stderr. Watch for these and fix them -- they indicate
bugs:

```
qrc:/QtQuick/Controls/Basic/Button.qml:50: TypeError: Cannot read property 'width' of null
```

**Common pitfalls:**

1. **Null safety**: Always use `?.` (optional chaining) when accessing
   properties that might be null:
   ```qml
   // Bad: crashes if focusedWorkspace is null
   text: Hyprland.focusedWorkspace.id

   // Good: safely returns undefined/null
   text: Hyprland.focusedWorkspace?.id ?? 1
   ```

2. **Binding vs assignment**: In a `Binding` or property declaration, `:`
   creates a reactive binding. In a function, `=` creates a one-time assignment
   that breaks the binding:
   ```qml
   property int x: parent.width / 2  // Binding: always centered

   function resetPosition() {
       x = 0;  // Assignment: binding is now broken!
       x = Qt.binding(() => parent.width / 2);  // Restore binding
   }
   ```

3. **Component.onCompleted timing**: This fires after the component is created
   but before it is fully laid out. If you need geometry, use a small delay:
   ```qml
   Component.onCompleted: Qt.callLater(() => {
       // Now width/height/x/y are finalized
   })
   ```

4. **ObjectModel vs JavaScript arrays**: QuickShell provides `ObjectModel`
   types (like `Hyprland.workspaces`) that have a `.values` property to get
   a JS array. You cannot use JS array methods directly on the model object.

5. **pragma ComponentBehavior: Bound**: Add this at the top of files using
   `Repeater` or `Variants` to ensure that delegate children can access
   `required property` values from their parent delegate. Without it, property
   access may silently fail.

---

## Next Steps

You now have the building blocks to create a complete desktop shell. Some
project ideas to try:

- **Extend the bar**: Add a system tray, notification count, or media
  now-playing indicator.
- **Build a launcher**: Use `DesktopEntries`, a `TextField` for search, and
  a `ListView` for results.
- **Create an OSD**: Show volume/brightness overlays that appear on change and
  auto-hide after a timeout (like `modules/osd/Wrapper.qml`).
- **Add a notification center**: Use `NotificationServer` to collect
  notifications and display them in a sidebar.
- **Build a session menu**: Power, logout, lock, and reboot buttons with
  confirmation (like `modules/session/`).

For a complete, production-quality example of all these features working
together, study the Caelestia shell in this repository. Start with `shell.qml`,
follow the imports into `modules/drawers/Drawers.qml` (the main per-monitor
shell), and trace through the module tree.

Key files to study:
- `shell.qml` -- entry point
- `modules/drawers/Drawers.qml` -- per-monitor shell orchestration
- `modules/drawers/Panels.qml` -- panel layout and composition
- `modules/bar/Bar.qml` -- bar with dynamic entries
- `services/Hypr.qml` -- Hyprland integration singleton
- `services/Audio.qml` -- PipeWire audio singleton
- `services/Colours.qml` -- Material 3 color system
- `config/Config.qml` -- JSON-based config with live reload
- `components/Anim.qml` -- reusable animation component
