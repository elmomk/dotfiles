pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services

Item {
    id: root

    required property var visibilities
    readonly property real nonAnimWidth: 0

    visible: false
    implicitWidth: 0

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
