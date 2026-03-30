pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ClaudeProcess claude
    required property var visibilities

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top bar: session info
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
                    text: root.claude.model || "Claude"
                    font.pointSize: Appearance.font.size.smaller
                    font.bold: true
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: root.claude.cost > 0
                    text: "$" + root.claude.cost.toFixed(4)
                    font.pointSize: Appearance.font.size.small
                    font.family: Appearance.font.family.mono
                    color: Colours.palette.m3outline
                }

                // New session button
                StyledRect {
                    implicitWidth: newSessionIcon.implicitWidth + Appearance.padding.small * 2
                    implicitHeight: newSessionIcon.implicitHeight + Appearance.padding.small * 2
                    radius: Appearance.rounding.small
                    color: newSessionArea.containsMouse ? Colours.palette.m3surfaceContainerHighest : "transparent"

                    MaterialIcon {
                        id: newSessionIcon
                        anchors.centerIn: parent
                        text: "add_circle"
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3primary
                    }

                    MouseArea {
                        id: newSessionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.claude.newSession()
                    }
                }
            }
        }

        // Separator
        StyledRect {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            Layout.bottomMargin: Appearance.spacing.small
            implicitHeight: 1
            color: Colours.tPalette.m3outlineVariant
        }

        // Message list
        StyledListView {
            id: messageList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.spacing.small
            verticalLayoutDirection: ListView.TopToBottom

            model: root.claude.messages

            delegate: ChatMessage {
                required property int index

                width: messageList.width
            }

            // Auto-scroll to bottom on new messages
            Connections {
                target: root.claude
                function onMessageAdded(index: int): void {
                    messageList.positionViewAtEnd();
                }
            }

            // Empty state
            StyledText {
                anchors.centerIn: parent
                visible: messageList.count === 0
                text: qsTr("Send a message to start")
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
            }
        }

        // Busy indicator
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            visible: root.claude.busy
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: "hourglass_top"
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3primary

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 2000
                    loops: Animation.Infinite
                    running: root.claude.busy
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Thinking...")
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3outline
            }
        }

        // Separator
        StyledRect {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            Layout.bottomMargin: Appearance.spacing.small
            implicitHeight: 1
            color: Colours.tPalette.m3outlineVariant
        }

        // Input area
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: inputRow.implicitHeight + Appearance.padding.normal * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainerLow

            RowLayout {
                id: inputRow

                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.small

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: inputField.implicitHeight + Appearance.padding.small * 2
                    radius: Appearance.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest

                    StyledTextField {
                        id: inputField

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.small
                        placeholderText: qsTr("Ask Claude...")
                        enabled: !root.claude.busy
                        font.pointSize: Appearance.font.size.smaller

                        onAccepted: {
                            if (text.trim().length > 0) {
                                root.claude.send(text.trim());
                                text = "";
                            }
                        }

                        // Grab focus when panel becomes visible
                        Connections {
                            target: root.visibilities
                            function onClaudeChanged(): void {
                                if (root.visibilities.claude)
                                    inputField.forceActiveFocus();
                            }
                        }
                    }
                }

                // Send button
                StyledRect {
                    implicitWidth: sendIcon.implicitWidth + Appearance.padding.small * 2
                    implicitHeight: sendIcon.implicitHeight + Appearance.padding.small * 2
                    radius: Appearance.rounding.small
                    color: sendArea.containsMouse && !root.claude.busy
                        ? Colours.palette.m3primaryContainer
                        : "transparent"

                    MaterialIcon {
                        id: sendIcon
                        anchors.centerIn: parent
                        text: "send"
                        font.pointSize: Appearance.font.size.small
                        color: root.claude.busy ? Colours.palette.m3outline : Colours.palette.m3primary
                    }

                    MouseArea {
                        id: sendArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.claude.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: {
                            if (!root.claude.busy && inputField.text.trim().length > 0) {
                                root.claude.send(inputField.text.trim());
                                inputField.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
