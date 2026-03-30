import "../services"
import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var list
    readonly property string query: list.search.text.slice(`${Config.launcher.actionPrefix}claude `.length)

    function onClicked(): void {
        if (query.length > 0 && !Claude.busy) {
            Claude.ask(query);
            root.list.visibilities.launcher = false;
        }
    }

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    scale: stateLayer.containsMouse ? Appearance.interaction.hoverScale : 1.0

    Behavior on scale {
        Anim {
            duration: Appearance.anim.durations.small
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    StateLayer {
        id: stateLayer

        radius: Appearance.rounding.normal

        function onClicked(): void {
            root.onClicked();
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.larger

        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: "smart_toy"
            font.pointSize: Appearance.font.size.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: label.implicitHeight + desc.implicitHeight

            StyledText {
                id: label

                text: {
                    if (Claude.busy)
                        return qsTr("Waiting for Claude...");
                    if (!root.query)
                        return qsTr("Type a question for Claude");
                    return root.query;
                }

                color: {
                    if (Claude.busy)
                        return Colours.palette.m3onSurfaceVariant;
                    if (!root.query)
                        return Colours.palette.m3onSurfaceVariant;
                    return Colours.palette.m3onSurface;
                }

                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
                width: parent.width
            }

            StyledText {
                id: desc

                text: {
                    if (Claude.busy)
                        return qsTr("Processing your question...");
                    if (Claude.lastResult)
                        return qsTr("Last: %1").arg(Claude.lastResult);
                    return qsTr("Press Enter to ask");
                }

                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
                width: parent.width

                anchors.top: label.bottom
            }
        }
    }
}
