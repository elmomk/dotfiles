import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool showOnHover: true
    property int mediaUpdateInterval: 500
    property int resourceUpdateInterval: 1000
    property int dragThreshold: 50
    property Sizes sizes: Sizes {}
    property Performance performance: Performance {}

    component Performance: JsonObject {
        property bool showBattery: true
        property bool showGpu: true
        property bool showCpu: true
        property bool showMemory: true
        property bool showStorage: true
        property bool showNetwork: true
    }

    component Sizes: JsonObject {
        property real scale: 1
        property int tabIndicatorHeight: 3 * scale
        property int tabIndicatorSpacing: 5 * scale
        property int infoWidth: 200 * scale
        property int infoIconSize: 25 * scale
        property int dateTimeWidth: 110 * scale
        property int mediaWidth: 200 * scale
        property int mediaProgressSweep: 180
        property int mediaProgressThickness: 8 * scale
        property int resourceProgessThickness: 10 * scale
        property int weatherWidth: 250 * scale
        property int mediaCoverArtSize: 150 * scale
        property int mediaVisualiserSize: 80 * scale
        property int resourceSize: 200 * scale
        property int heroCardMinWidth: 400 * scale
        property int heroCardHeight: 150 * scale
        property int gaugeCardMinWidth: 250 * scale
        property int gaugeCardHeight: 220 * scale
        property int networkCardMinWidth: 200 * scale
        property int batteryWidth: 120 * scale
        property int sliderWidth: 280 * scale
        property int placeholderWidth: 400 * scale
        property int placeholderHeight: 350 * scale
    }
}
