pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Item {
    id: root

    property alias messages: messageModel
    property bool busy: false
    property string sessionId: ""
    property real cost: 0
    property string model: ""
    property int durationMs: 0

    // Accumulates streaming text for the current assistant message
    property string _currentText: ""
    property bool _hasCurrentAssistant: false

    signal messageAdded(int index)

    function send(prompt: string): void {
        if (busy)
            return;

        // Add user message
        messageModel.append({
            role: "user",
            text: prompt,
            toolName: "",
            toolInput: "",
            timestamp: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
        });
        messageAdded(messageModel.count - 1);

        _currentText = "";
        _hasCurrentAssistant = false;
        busy = true;

        const cmd = ["claude", "-p", "--verbose", "--output-format", "stream-json"];
        if (sessionId.length > 0) {
            cmd.push("--resume");
            cmd.push(sessionId);
        }
        cmd.push(prompt);

        proc.command = cmd;
        proc.running = true;
    }

    function newSession(): void {
        if (busy)
            return;
        sessionId = "";
        cost = 0;
        model = "";
        durationMs = 0;
        messageModel.clear();
    }

    ListModel {
        id: messageModel
    }

    Process {
        id: proc

        stdout: SplitParser {
            onRead: data => root._parseLine(data)
        }

        onExited: (exitCode, exitStatus) => {
            root.busy = false;
            // Finalize any pending assistant message
            if (root._hasCurrentAssistant && root._currentText.length > 0) {
                // Update the last assistant message with final text
                const idx = root._findLastAssistant();
                if (idx >= 0)
                    messageModel.set(idx, { text: root._currentText });
            }
            root._hasCurrentAssistant = false;
            root._currentText = "";
        }
    }

    function _parseLine(line: string): void {
        let obj;
        try {
            obj = JSON.parse(line);
        } catch (e) {
            return;
        }

        if (obj.type === "system" && obj.subtype === "init") {
            if (obj.session_id)
                sessionId = obj.session_id;
            if (obj.model)
                model = obj.model;
            return;
        }

        if (obj.type === "assistant") {
            const content = obj.message?.content;
            if (!content || !Array.isArray(content))
                return;

            for (const block of content) {
                if (block.type === "text") {
                    _currentText += block.text;

                    if (!_hasCurrentAssistant) {
                        // Create new assistant message
                        messageModel.append({
                            role: "assistant",
                            text: _currentText,
                            toolName: "",
                            toolInput: "",
                            timestamp: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
                        });
                        _hasCurrentAssistant = true;
                        messageAdded(messageModel.count - 1);
                    } else {
                        // Update existing assistant message
                        const idx = _findLastAssistant();
                        if (idx >= 0)
                            messageModel.set(idx, { text: _currentText });
                    }
                }
            }
            return;
        }

        if (obj.type === "tool_use") {
            // Finalize current assistant text before tool
            _hasCurrentAssistant = false;
            _currentText = "";

            const toolName = obj.tool?.name ?? "unknown";
            const toolInput = obj.tool?.input ? JSON.stringify(obj.tool.input, null, 2) : "";

            messageModel.append({
                role: "tool",
                text: "",
                toolName: toolName,
                toolInput: toolInput.length > 200 ? toolInput.substring(0, 200) + "..." : toolInput,
                timestamp: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
            });
            messageAdded(messageModel.count - 1);
            return;
        }

        if (obj.type === "result") {
            if (obj.total_cost_usd !== undefined)
                cost = obj.total_cost_usd;
            if (obj.duration_ms !== undefined)
                durationMs = obj.duration_ms;

            // If there is a result text and we have no assistant message for it, add one
            if (obj.result && obj.result.length > 0) {
                if (_hasCurrentAssistant) {
                    // Update existing
                    const idx = _findLastAssistant();
                    if (idx >= 0)
                        messageModel.set(idx, { text: obj.result });
                } else {
                    messageModel.append({
                        role: "assistant",
                        text: obj.result,
                        toolName: "",
                        toolInput: "",
                        timestamp: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
                    });
                    messageAdded(messageModel.count - 1);
                }
            }

            _hasCurrentAssistant = false;
            _currentText = "";
            return;
        }
    }

    function _findLastAssistant(): int {
        for (let i = messageModel.count - 1; i >= 0; i--) {
            if (messageModel.get(i).role === "assistant")
                return i;
        }
        return -1;
    }
}
