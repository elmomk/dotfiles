pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.small
    width: Config.bar.sizes.claudeWidth

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        MaterialIcon {
            text: "smart_toy"
            font.pointSize: Appearance.font.size.large
            color: Colours.palette.m3primary
            fill: 1
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Claude Code")
            font.weight: 500
        }

        StyledText {
            text: ClaudeSessions.processRunning ? qsTr("%1 active").arg(ClaudeSessions.sessionCount) : qsTr("%1 recent").arg(ClaudeSessions.sessionCount)
            color: ClaudeSessions.processRunning ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
        }
    }

    // Session list
    Repeater {
        model: ScriptModel {
            values: [...ClaudeSessions.activeSessions]
        }

        RowLayout {
            id: sessionRow

            required property var modelData
            required property int index

            Layout.fillWidth: true
            Layout.rightMargin: Appearance.padding.small
            spacing: Appearance.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: "folder"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                Layout.fillWidth: true
                text: sessionRow.modelData.project
                elide: Text.ElideMiddle
            }

            StyledText {
                text: sessionRow.modelData.timeAgo
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }
        }
    }

    // Empty state
    Loader {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        active: ClaudeSessions.sessionCount === 0

        sourceComponent: StyledText {
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("No recent sessions")
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
