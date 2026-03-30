pragma ComponentBehavior: Bound

import qs.components
import qs.config
import QtQuick

Item {
    id: root

    required property var visibilities
    readonly property real nonAnimWidth: Config.claude.sizes.width

    visible: width > 0
    implicitWidth: 0

    states: State {
        name: "visible"
        when: root.visibilities.claude && Config.claude.enabled

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

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large

        active: true
        Component.onCompleted: active = Qt.binding(() => (root.visibilities.claude && Config.claude.enabled) || root.visible)

        sourceComponent: Content {
            implicitWidth: Config.claude.sizes.width - Appearance.padding.large * 2
            claude: claudeProcess
            visibilities: root.visibilities
        }
    }

    ClaudeProcess {
        id: claudeProcess
    }
}
