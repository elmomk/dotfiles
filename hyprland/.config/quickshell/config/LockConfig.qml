import Quickshell.Io

JsonObject {
    property bool recolourLogo: false
    property bool enableFprint: true
    property int maxFprintTries: 3
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property real scale: 1
        property real heightMult: 0.7
        property real ratio: 16 / 9
        property int centerWidth: 600 * scale
    }
}
