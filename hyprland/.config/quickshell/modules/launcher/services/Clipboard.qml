pragma Singleton

import ".."
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${Config.launcher.actionPrefix}clip `.length);
    }

    list: entries
    key: "content"

    property list<QtObject> entries: []

    function reload(): void {
        listProc.running = true;
    }

    function paste(clipId: string): void {
        pasteProc.clipId = clipId;
        pasteProc.running = true;
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                const parsed = [];
                for (const line of lines) {
                    const tabIdx = line.indexOf("\t");
                    if (tabIdx === -1)
                        continue;
                    const id = line.substring(0, tabIdx).trim();
                    const content = line.substring(tabIdx + 1);
                    parsed.push({
                        clipId: id,
                        content: content,
                        name: content
                    });
                }
                root.entries = parsed.map(e => entryComponent.createObject(root, e));
            }
        }
    }

    Process {
        id: pasteProc

        property string clipId
        command: ["bash", "-c", `cliphist decode ${clipId} | wl-copy`]
    }

    component ClipEntry: QtObject {
        required property string clipId
        required property string content
        readonly property string name: content
        readonly property string desc: `ID: ${clipId}`
        readonly property string icon: "content_paste"

        function onClicked(list: AppList): void {
            root.paste(clipId);
            list.visibilities.launcher = false;
        }
    }

    Component {
        id: entryComponent
        ClipEntry {}
    }
}
