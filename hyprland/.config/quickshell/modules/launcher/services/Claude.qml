pragma Singleton

import ".."
import qs.config
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property bool busy: false
    property string lastResult: ""

    function ask(prompt: string): void {
        if (busy)
            return;

        root.busy = true;
        root.lastResult = "";
        askProc.command = ["claude", "-p", "--verbose", "--output-format", "stream-json", prompt];
        askProc.running = true;
    }

    property var _proc: Process {
        id: askProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;

                const output = text.trim();
                const lines = output.split("\n");
                let result = "";

                for (const line of lines) {
                    try {
                        const obj = JSON.parse(line);
                        if (obj.type === "result" && obj.result) {
                            result = obj.result;
                            break;
                        }
                    } catch (e) {
                        continue;
                    }
                }

                if (!result) {
                    // Fallback: try to find any content_block_delta with text
                    for (const line of lines) {
                        try {
                            const obj = JSON.parse(line);
                            if (obj.type === "content_block_delta" && obj.delta?.text) {
                                result += obj.delta.text;
                            }
                        } catch (e) {
                            continue;
                        }
                    }
                }

                if (!result)
                    result = "No response from Claude.";

                root.lastResult = result;
                Toaster.toast("Claude", result, "smart_toy", Toast.Info);
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.busy) {
                root.busy = false;
                root.lastResult = "Claude exited with error (code " + exitCode + ")";
                Toaster.toast("Claude", root.lastResult, "smart_toy", Toast.Error);
            }
        }
    }
}
