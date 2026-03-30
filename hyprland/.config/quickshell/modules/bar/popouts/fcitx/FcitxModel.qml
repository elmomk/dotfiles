pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: model
    visible: false

    ListModel {
        id: _listModel
    }
    property alias listModel: _listModel

    function refresh() {
        _rebuild();
    }

    function _rebuild() {
        _listModel.clear();

        const methods = Fcitx.inputMethods;
        if (!methods || methods.length === 0)
            return;

        for (const im of methods) {
            _listModel.append({
                imName: im.name,
                imLabel: im.label,
                imAbbr: im.abbr
            });
        }
    }

    Connections {
        target: Fcitx
        function onInputMethodsChanged() {
            _rebuild();
        }
    }
}
