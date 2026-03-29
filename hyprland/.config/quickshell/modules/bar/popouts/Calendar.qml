pragma ComponentBehavior: Bound

import qs.components
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property date currentDate: new Date()

    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        anchors.fill: parent
        spacing: Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Item {
                implicitWidth: implicitHeight
                implicitHeight: prevIcon.implicitHeight + Appearance.padding.small * 2

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentDate = new Date(root.currYear, root.currMonth - 1, 1)
                }

                MaterialIcon {
                    id: prevIcon

                    anchors.centerIn: parent
                    text: "chevron_left"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 700
                }
            }

            Item {
                Layout.fillWidth: true

                implicitWidth: monthYearText.implicitWidth + Appearance.padding.normal * 2
                implicitHeight: monthYearText.implicitHeight + Appearance.padding.small * 2

                MouseArea {
                    anchors.fill: parent
                    cursorShape: {
                        const now = new Date();
                        return (root.currMonth === now.getMonth() && root.currYear === now.getFullYear()) ? Qt.ArrowCursor : Qt.PointingHandCursor;
                    }
                    onClicked: root.currentDate = new Date()
                }

                StyledText {
                    id: monthYearText

                    anchors.centerIn: parent
                    text: grid.title
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                    font.capitalization: Font.Capitalize
                }
            }

            Item {
                implicitWidth: implicitHeight
                implicitHeight: nextIcon.implicitHeight + Appearance.padding.small * 2

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentDate = new Date(root.currYear, root.currMonth + 1, 1)
                }

                MaterialIcon {
                    id: nextIcon

                    anchors.centerIn: parent
                    text: "chevron_right"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 700
                }
            }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: grid.locale

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font.weight: 500
                color: (model.day === 0 || model.day === 6) ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight

            MonthGrid {
                id: grid

                month: root.currMonth
                year: root.currYear

                anchors.fill: parent

                spacing: 3
                locale: Qt.locale()

                delegate: Item {
                    id: dayItem

                    required property var model

                    implicitWidth: implicitHeight
                    implicitHeight: dayText.implicitHeight + Appearance.padding.small * 2

                    StyledRect {
                        anchors.centerIn: parent
                        implicitWidth: parent.implicitWidth
                        implicitHeight: parent.implicitHeight
                        radius: Appearance.rounding.full
                        color: dayItem.model.today ? Colours.palette.m3primary : "transparent"
                    }

                    StyledText {
                        id: dayText

                        anchors.centerIn: parent

                        horizontalAlignment: Text.AlignHCenter
                        text: grid.locale.toString(dayItem.model.day)
                        color: {
                            if (dayItem.model.today)
                                return Colours.palette.m3onPrimary;

                            const dayOfWeek = dayItem.model.date.getUTCDay();
                            if (dayOfWeek === 0 || dayOfWeek === 6)
                                return Colours.palette.m3secondary;

                            return Colours.palette.m3onSurfaceVariant;
                        }
                        opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                        font.pointSize: Appearance.font.size.normal
                        font.weight: dayItem.model.today ? 700 : 500
                    }
                }
            }
        }
    }
}
