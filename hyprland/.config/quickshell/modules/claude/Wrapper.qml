pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

Item {
    id: root

    required property var visibilities
    readonly property real nonAnimWidth: Config.claude.sizes.width
    readonly property bool scratchpadVisible: {
        const mon = Hypr.focusedMonitor;
        return mon?.lastIpcObject?.specialWorkspace?.name === "special:claude";
    }

    visible: width > 0
    implicitWidth: 0

    states: State {
        name: "visible"
        when: root.scratchpadVisible

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

    Connections {
        target: root.visibilities

        function onClaudeChanged(): void {
            if (root.visibilities.claude) {
                Hypr.dispatch("togglespecialworkspace claude");
                root.visibilities.claude = false;
            }
        }
    }
}
