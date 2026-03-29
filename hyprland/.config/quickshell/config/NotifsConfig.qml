import Quickshell.Io

JsonObject {
    property bool expire: true
    property int defaultExpireTimeout: 5000
    property real clearThreshold: 0.3
    property int expandThreshold: 20
    property bool actionOnClick: false
    property int groupPreviewNum: 3
    property bool openExpanded: false // Show the notifichation in expanded state when opening
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property real scale: 1
        property int width: 500 * scale
        property int image: 41 * scale
        property int badge: 20 * scale
    }
}
