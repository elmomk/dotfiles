import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int hideDelay: 2000
    property bool enableBrightness: true
    property bool enableMicrophone: false
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property real scale: 1
        property int sliderWidth: 30 * scale
        property int sliderHeight: 150 * scale
    }
}
