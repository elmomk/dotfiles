pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var visibilities

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top bar: title
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: infoRow.implicitHeight + Appearance.padding.normal * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainerLow

            RowLayout {
                id: infoRow

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: "smart_toy"
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3primary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Claude Code"
                    font.pointSize: Appearance.font.size.smaller
                    font.bold: true
                    color: Colours.palette.m3onSurface
                }

                // Close button
                StyledRect {
                    implicitWidth: closeIcon.implicitWidth + Appearance.padding.small * 2
                    implicitHeight: closeIcon.implicitHeight + Appearance.padding.small * 2
                    radius: Appearance.rounding.small
                    color: closeArea.containsMouse ? Colours.palette.m3surfaceContainerHighest : "transparent"

                    MaterialIcon {
                        id: closeIcon
                        anchors.centerIn: parent
                        text: "close"
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visibilities.claude = false
                    }
                }
            }
        }

        // The rest is empty - foot terminal window covers this area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
