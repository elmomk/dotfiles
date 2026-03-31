import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool showOnHover: true
    property int mediaUpdateInterval: 500
    property int resourceUpdateInterval: 1000
    property int dragThreshold: 50
    property bool showDashboard: true
    property bool showMedia: true
    property bool showPerformance: true
    property bool showWeather: true
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
        readonly property int tabIndicatorHeight: 3
        readonly property int tabIndicatorSpacing: 5
        readonly property int infoWidth: 200 * scale
        readonly property int infoIconSize: 25 * scale
        readonly property int dateTimeWidth: 110 * scale
        readonly property int mediaWidth: 200 * scale
        readonly property int mediaProgressSweep: 180
        readonly property int mediaProgressThickness: 8 * scale
        readonly property int resourceProgessThickness: 10 * scale
        readonly property int weatherWidth: 250 * scale
        readonly property int mediaCoverArtSize: 150 * scale
        readonly property int mediaVisualiserSize: 80 * scale
        readonly property int resourceSize: 200 * scale
    }
}
