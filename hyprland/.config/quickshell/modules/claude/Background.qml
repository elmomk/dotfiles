import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Wrapper wrapper

    readonly property real rounding: Config.border.rounding

    strokeWidth: -1
    fillColor: Colours.palette.m3surface

    // Background shape for left-side panel
    // Draws from top-left corner down the left edge
    PathLine {
        relativeX: root.wrapper.width + root.rounding
        relativeY: 0
    }
    PathArc {
        relativeX: -root.rounding
        relativeY: root.rounding
        radiusX: root.rounding
        radiusY: root.rounding
    }
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.rounding * 2
    }
    PathArc {
        relativeX: root.rounding
        relativeY: root.rounding
        radiusX: root.rounding
        radiusY: root.rounding
    }
    PathLine {
        relativeX: -root.wrapper.width - root.rounding
        relativeY: 0
    }

    Behavior on fillColor {
        CAnim {}
    }
}
