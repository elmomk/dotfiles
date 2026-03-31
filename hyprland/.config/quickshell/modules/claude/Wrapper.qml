pragma ComponentBehavior: Bound

import qs.components
import qs.config
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var visibilities
    readonly property real nonAnimWidth: Config.claude.sizes.width
    readonly property bool shouldBeVisible: root.visibilities.claude && Config.claude.enabled

    visible: width > 0
    implicitWidth: 0

    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            // Spawn foot terminal with claude
            termProc.running = true;
        } else {
            // Kill the terminal
            termProc.signal(15); // SIGTERM
        }
    }

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: Config.claude.sizes.width
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

    // Header overlay on the panel
    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large

        active: true
        Component.onCompleted: active = Qt.binding(() => root.shouldBeVisible || root.visible)

        sourceComponent: Content {
            implicitWidth: Config.claude.sizes.width - Appearance.padding.large * 2
            visibilities: root.visibilities
        }
    }

    Process {
        id: termProc

        command: ["foot", "-a", "claude-code", "-T", "Claude Code", "claude"]

        onExited: (exitCode, exitStatus) => {
            // If the terminal exits on its own, close the panel
            if (root.visibilities.claude)
                root.visibilities.claude = false;
        }
    }
}
