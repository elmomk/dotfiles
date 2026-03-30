pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string currentIm: _currentIm
    readonly property string currentLabel: _imLabel(_currentIm)
    readonly property var inputMethods: _inputMethods
    readonly property bool running: _running

    property string _currentIm: ""
    property var _inputMethods: []
    property bool _running: false

    function toggle(): void {
        _toggleProc.running = true;
    }

    function switchTo(imName: string): void {
        _switchProc.command = ["fcitx5-remote", "-s", imName];
        _switchProc.running = true;
    }

    function _imLabel(imName: string): string {
        if (!imName || imName.length === 0)
            return "";

        const lower = imName.toLowerCase();

        if (lower === "keyboard-us" || lower === "keyboard-us-intl" || lower.startsWith("keyboard-us"))
            return "EN";
        if (lower.startsWith("keyboard-jp") || lower === "anthy" || lower === "mozc" || lower === "skk")
            return "JP";
        if (lower.startsWith("keyboard-kr") || lower === "hangul" || lower.startsWith("hangul"))
            return "KR";
        if (lower.startsWith("keyboard-cn") || lower === "pinyin" || lower === "shuangpin" || lower === "wubi" || lower.startsWith("rime"))
            return "ZH";
        if (lower.startsWith("keyboard-tw") || lower === "chewing" || lower === "zhuyin")
            return "ZH";
        if (lower.startsWith("keyboard-de"))
            return "DE";
        if (lower.startsWith("keyboard-fr"))
            return "FR";
        if (lower.startsWith("keyboard-es"))
            return "ES";
        if (lower.startsWith("keyboard-"))
            return imName.substring(9, Math.min(11, imName.length)).toUpperCase();

        // Fallback: first 2 chars
        return imName.substring(0, 2).toUpperCase();
    }

    Component.onCompleted: {
        _checkProc.running = true;
    }

    // Check if fcitx5 is running
    Process {
        id: _checkProc
        command: ["fcitx5-remote", "--check"]
        onExited: function(exitCode, exitStatus) {
            _running = (exitCode === 0);
            if (_running) {
                _pollProc.running = true;
                _listProc.running = true;
            } else {
                // Retry after a delay
                _retryTimer.running = true;
            }
        }
    }

    Timer {
        id: _retryTimer
        interval: 5000
        repeat: false
        onTriggered: _checkProc.running = true
    }

    // Poll current IM
    Process {
        id: _pollProc
        command: ["fcitx5-remote", "-n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name.length > 0 && name !== _currentIm) {
                    _currentIm = name;
                }
            }
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                _running = false;
        }
    }

    Timer {
        id: _pollTimer
        interval: 500
        running: root._running
        repeat: true
        onTriggered: {
            if (!_pollProc.running)
                _pollProc.running = true;
        }
    }

    // List available IMs via dbus
    Process {
        id: _listProc
        command: ["dbus-send", "--session", "--print-reply", "--dest=org.fcitx.Fcitx5",
                  "/controller", "org.fcitx.Fcitx.Controller1.AvailableInputMethods"]
        stdout: StdioCollector {
            onStreamFinished: _parseInputMethods(text)
        }
        onExited: function(exitCode, exitStatus) {
            // If dbus method fails, try simpler approach
            if (exitCode !== 0)
                _listSimpleProc.running = true;
        }
    }

    // Simpler fallback: list from input method group
    Process {
        id: _listSimpleProc
        command: ["dbus-send", "--session", "--print-reply", "--dest=org.fcitx.Fcitx5",
                  "/controller", "org.fcitx.Fcitx.Controller1.InputMethodGroups"]
        stdout: StdioCollector {
            onStreamFinished: _parseGroups(text)
        }
    }

    // Toggle IM
    Process {
        id: _toggleProc
        command: ["fcitx5-remote", "-t"]
        onExited: function(exitCode, exitStatus) {
            // Poll immediately after toggle
            _pollProc.running = true;
        }
    }

    // Switch to specific IM
    Process {
        id: _switchProc
        onExited: function(exitCode, exitStatus) {
            _pollProc.running = true;
        }
    }

    function _parseInputMethods(text: string): void {
        // Parse dbus reply - look for string entries that look like IM names
        const methods = [];
        const lines = text.split("\n");
        let i = 0;
        while (i < lines.length) {
            const line = lines[i].trim();
            // Look for struct entries in the dbus array reply
            if (line.startsWith("string \"")) {
                const match = line.match(/string "([^"]+)"/);
                if (match) {
                    const name = match[1];
                    // Grab the next string as label if present
                    let label = name;
                    if (i + 1 < lines.length) {
                        const nextLine = lines[i + 1].trim();
                        const labelMatch = nextLine.match(/string "([^"]+)"/);
                        if (labelMatch)
                            label = labelMatch[1];
                    }
                    // Filter: only add what looks like an IM name (has no spaces, or keyboard- prefix)
                    if (name.indexOf(" ") === -1 && name.length > 0) {
                        methods.push({
                            name: name,
                            label: label,
                            abbr: _imLabel(name)
                        });
                    }
                }
            }
            i++;
        }

        if (methods.length > 0) {
            _inputMethods = methods;
        } else {
            // Fallback
            _listGroupItemsProc.running = true;
        }
    }

    Process {
        id: _listGroupItemsProc
        command: ["dbus-send", "--session", "--print-reply", "--dest=org.fcitx.Fcitx5",
                  "/controller", "org.fcitx.Fcitx.Controller1.CurrentInputMethodGroup"]
        stdout: StdioCollector {
            onStreamFinished: _parseCurrentGroup(text)
        }
    }

    function _parseCurrentGroup(text: string): void {
        // Parse strings from dbus output
        const methods = [];
        const re = /string "([^"]+)"/g;
        let match;
        while ((match = re.exec(text)) !== null) {
            const name = match[1];
            if (name.length > 0 && name.indexOf(" ") === -1) {
                methods.push({
                    name: name,
                    label: name,
                    abbr: _imLabel(name)
                });
            }
        }
        if (methods.length > 0)
            _inputMethods = methods;
    }

    function _parseGroups(text: string): void {
        // Just extract group names from the dbus response
        const re = /string "([^"]+)"/g;
        let match;
        const groups = [];
        while ((match = re.exec(text)) !== null) {
            groups.push(match[1]);
        }
        // If we found groups, query the current group's items
        if (groups.length > 0)
            _listGroupItemsProc.running = true;
    }
}
