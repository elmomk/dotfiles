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
    readonly property var today: new Date()

    function daysInMonth(year: int, month: int): int {
        return new Date(year, month + 1, 0).getDate();
    }

    function firstDayOfWeek(year: int, month: int): int {
        // 0 = Sunday
        return new Date(year, month, 1).getDay();
    }

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        anchors.fill: parent
        spacing: Appearance.spacing.small

        // Header: < Month Year >
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
                    text: root.currentDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
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

        // Day of week headers
        Grid {
            id: dowHeader

            Layout.fillWidth: true
            columns: 7
            spacing: 2

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                StyledText {
                    required property string modelData
                    required property int index

                    width: cellSize
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pointSize: Appearance.font.size.small
                    font.weight: 500
                    color: (index === 0 || index === 6) ? Colours.palette.m3secondary : Colours.palette.m3onSurface
                }
            }
        }

        // Day grid
        Grid {
            id: dayGrid

            readonly property int numDays: root.daysInMonth(root.currYear, root.currMonth)
            readonly property int startDay: root.firstDayOfWeek(root.currYear, root.currMonth)
            readonly property int prevMonthDays: root.daysInMonth(root.currYear, root.currMonth - 1)

            Layout.fillWidth: true
            columns: 7
            spacing: 2

            Repeater {
                model: 42

                Item {
                    id: dayCell

                    required property int index

                    readonly property int dayNum: {
                        if (index < dayGrid.startDay)
                            return dayGrid.prevMonthDays - dayGrid.startDay + index + 1;
                        const d = index - dayGrid.startDay + 1;
                        if (d > dayGrid.numDays)
                            return d - dayGrid.numDays;
                        return d;
                    }
                    readonly property bool isCurrentMonth: index >= dayGrid.startDay && index < dayGrid.startDay + dayGrid.numDays
                    readonly property bool isToday: isCurrentMonth && dayNum === root.today.getDate() && root.currMonth === root.today.getMonth() && root.currYear === root.today.getFullYear()

                    width: cellSize
                    height: cellSize

                    StyledRect {
                        anchors.centerIn: parent
                        implicitWidth: cellSize
                        implicitHeight: cellSize
                        radius: Appearance.rounding.full
                        color: dayCell.isToday ? Colours.palette.m3primary : "transparent"
                    }

                    StyledText {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: dayCell.dayNum.toString()
                        color: {
                            if (dayCell.isToday)
                                return Colours.palette.m3onPrimary;
                            const dow = dayCell.index % 7;
                            if (dow === 0 || dow === 6)
                                return Colours.palette.m3secondary;
                            return Colours.palette.m3onSurface;
                        }
                        opacity: dayCell.isCurrentMonth ? 1 : 0.4
                        font.pointSize: Appearance.font.size.normal
                        font.weight: dayCell.isToday ? 700 : 400
                    }
                }
            }
        }
    }

    readonly property real cellSize: Appearance.font.size.normal * 4
}
