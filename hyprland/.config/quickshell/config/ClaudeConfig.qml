import Quickshell.Io

JsonObject {
    property bool enabled: true
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property real scale: 1
        property int width: 500 * scale
    }
}
