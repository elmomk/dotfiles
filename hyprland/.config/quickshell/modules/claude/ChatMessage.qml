pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string role
    required property string text
    required property string toolName
    required property string toolInput
    required property string timestamp

    property bool toolExpanded: false

    implicitWidth: parent?.width ?? 0
    implicitHeight: layout.implicitHeight + Appearance.padding.small * 2

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.small
        spacing: Appearance.spacing.small
        layoutDirection: root.role === "user" ? Qt.RightToLeft : Qt.LeftToRight

        // Role icon
        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: root.role === "user" ? "person" : root.role === "tool" ? "build" : "smart_toy"
            font.pointSize: Appearance.font.size.small
            color: root.role === "user" ? Colours.palette.m3primary : root.role === "tool" ? Colours.palette.m3tertiary : Colours.palette.m3secondary
        }

        // Message bubble
        StyledRect {
            Layout.fillWidth: true
            Layout.maximumWidth: root.width * 0.85
            implicitHeight: contentCol.implicitHeight + Appearance.padding.normal * 2
            radius: Appearance.rounding.normal
            color: root.role === "user"
                ? Colours.palette.m3primaryContainer
                : root.role === "tool"
                    ? Colours.palette.m3tertiaryContainer
                    : Colours.palette.m3surfaceContainerHigh

            ColumnLayout {
                id: contentCol

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.small

                // Tool name header (only for tool messages)
                StyledText {
                    visible: root.role === "tool"
                    Layout.fillWidth: true
                    text: root.toolName
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.smaller
                    font.bold: true
                    color: Colours.palette.m3onTertiaryContainer
                    elide: Text.ElideRight

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toolExpanded = !root.toolExpanded
                    }
                }

                // Tool input (collapsed by default)
                StyledText {
                    visible: root.role === "tool" && root.toolExpanded && root.toolInput.length > 0
                    Layout.fillWidth: true
                    text: root.toolInput
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onTertiaryContainer
                    wrapMode: Text.Wrap
                    opacity: 0.8
                }

                // Message text (for user and assistant)
                StyledText {
                    visible: root.role !== "tool"
                    Layout.fillWidth: true
                    text: root.text
                    font.pointSize: Appearance.font.size.smaller
                    color: root.role === "user"
                        ? Colours.palette.m3onPrimaryContainer
                        : Colours.palette.m3onSurface
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                }

                // Timestamp
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: root.role === "user" ? Text.AlignRight : Text.AlignLeft
                    text: root.timestamp
                    font.pointSize: Appearance.font.size.small
                    color: root.role === "user"
                        ? Colours.palette.m3onPrimaryContainer
                        : root.role === "tool"
                            ? Colours.palette.m3onTertiaryContainer
                            : Colours.palette.m3onSurfaceVariant
                    opacity: 0.6
                }
            }
        }

        // Spacer to push bubble to the correct side
        Item {
            Layout.fillWidth: true
        }
    }
}
