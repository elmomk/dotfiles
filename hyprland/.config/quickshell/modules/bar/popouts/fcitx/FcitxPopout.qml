pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.config

import "."

ColumnLayout {
    id: root

    required property Item wrapper

    spacing: Appearance.spacing.small
    width: Config.bar.sizes.kbLayoutWidth

    FcitxModel {
        id: fm
    }

    Component.onCompleted: fm.refresh()

    StyledText {
        Layout.topMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("Input Methods")
        font.weight: 500
    }

    ListView {
        id: list
        model: fm.listModel

        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        Layout.topMargin: Appearance.spacing.small

        clip: true
        interactive: true
        implicitHeight: Math.min(contentHeight, 320)
        visible: fm.listModel.count > 0
        spacing: Appearance.spacing.small

        add: Transition {
            NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: 140
            }
        }

        delegate: Item {
            required property string imName
            required property string imLabel
            required property string imAbbr

            width: list.width
            height: Math.max(36, rowContent.implicitHeight + Appearance.padding.small * 2)

            readonly property bool isCurrent: imName === Fcitx.currentIm

            StateLayer {
                id: layer
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.height - 4

                radius: Appearance.rounding.full
                color: isCurrent ? Colours.palette.m3primaryContainer : "transparent"

                function onClicked(): void {
                    Fcitx.switchTo(imName);
                }
            }

            RowLayout {
                id: rowContent
                anchors.verticalCenter: layer.verticalCenter
                anchors.left: layer.left
                anchors.right: layer.right
                anchors.leftMargin: Appearance.padding.small
                anchors.rightMargin: Appearance.padding.small
                spacing: Appearance.spacing.small

                StyledText {
                    text: imAbbr
                    font.family: Appearance.font.family.mono
                    font.weight: 600
                    color: isCurrent ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    Layout.preferredWidth: 30
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    Layout.fillWidth: true
                    text: imLabel
                    elide: Text.ElideRight
                    color: isCurrent ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }

                MaterialIcon {
                    visible: isCurrent
                    text: "check"
                    color: Colours.palette.m3primary
                }
            }
        }
    }

    Rectangle {
        visible: Fcitx.currentIm.length > 0
        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        Layout.topMargin: Appearance.spacing.small

        height: 1
        color: Colours.palette.m3onSurfaceVariant
        opacity: 0.35
    }

    RowLayout {
        id: activeRow

        visible: Fcitx.currentIm.length > 0
        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        Layout.topMargin: Appearance.spacing.small
        spacing: Appearance.spacing.small

        opacity: 1
        scale: 1

        MaterialIcon {
            text: "translate"
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.fillWidth: true
            text: Fcitx.currentLabel
            elide: Text.ElideRight
            font.weight: 500
            color: Colours.palette.m3primary
        }

        Connections {
            target: Fcitx
            function onCurrentImChanged() {
                if (!activeRow.visible)
                    return;
                popIn.restart();
            }
        }

        SequentialAnimation {
            id: popIn
            running: false

            ParallelAnimation {
                NumberAnimation {
                    target: activeRow
                    property: "opacity"
                    to: 0.0
                    duration: 70
                }
                NumberAnimation {
                    target: activeRow
                    property: "scale"
                    to: 0.92
                    duration: 70
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: activeRow
                    property: "opacity"
                    to: 1.0
                    duration: 160
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: activeRow
                    property: "scale"
                    to: 1.0
                    duration: 220
                    easing.type: Easing.OutBack
                }
            }
        }
    }
}
