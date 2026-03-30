pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool hasActive: _sessions.length > 0
    readonly property int sessionCount: _sessions.length
    readonly property var activeSessions: _sessions
    readonly property bool processRunning: _processCount > 0

    property var _sessions: []
    property int _processCount: 0

    Component.onCompleted: {
        _findProc.running = true;
        _pgrepProc.running = true;
    }

    // Find recent session files (modified in last 60 minutes)
    Process {
        id: _findProc
        command: ["find", `${Paths.home}/.claude/projects`, "-name", "*.json", "-path", "*/sessions/*", "-mmin", "-60", "-type", "f", "-printf", "%T@ %p\n"]
        stdout: StdioCollector {
            onStreamFinished: root._parseSessions(text)
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                root._sessions = [];
        }
    }

    // Check for running claude processes
    Process {
        id: _pgrepProc
        command: ["sh", "-c", "pgrep -c -f 'claude' 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const count = parseInt(text.trim());
                root._processCount = isNaN(count) ? 0 : count;
            }
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                root._processCount = 0;
        }
    }

    // Refresh every 30 seconds
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            if (!_findProc.running)
                _findProc.running = true;
            if (!_pgrepProc.running)
                _pgrepProc.running = true;
        }
    }

    function _parseSessions(text: string): void {
        const lines = text.trim().split("\n").filter(l => l.length > 0);
        const sessions = [];

        for (const line of lines) {
            const spaceIdx = line.indexOf(" ");
            if (spaceIdx === -1)
                continue;

            const mtime = parseFloat(line.substring(0, spaceIdx));
            const path = line.substring(spaceIdx + 1);

            // Extract project name from path: ~/.claude/projects/<slug>/sessions/<id>.json
            const parts = path.split("/");
            const sessionsIdx = parts.lastIndexOf("sessions");
            if (sessionsIdx < 1)
                continue;

            const projectSlug = parts[sessionsIdx - 1];
            const fileName = parts[parts.length - 1];
            const sessionId = fileName.replace(".json", "");

            // Decode project slug: -home-mo-project becomes /home/mo/project
            const projectName = _decodeSlug(projectSlug);

            // Calculate time ago
            const now = Date.now() / 1000;
            const secsAgo = Math.max(0, Math.floor(now - mtime));
            const timeAgo = _formatTimeAgo(secsAgo);

            sessions.push({
                id: sessionId.substring(0, 8),
                project: projectName,
                timeAgo: timeAgo,
                mtime: mtime
            });
        }

        // Sort by most recent first, limit to 8
        sessions.sort((a, b) => b.mtime - a.mtime);
        _sessions = sessions.slice(0, 8);
    }

    function _decodeSlug(slug: string): string {
        // Convert slug like -home-mo-dotfiles to a short project name
        // Take the last meaningful segment
        const parts = slug.split("-").filter(p => p.length > 0);
        if (parts.length === 0)
            return slug;
        // Skip common path prefixes (home, username)
        const meaningful = parts.length > 2 ? parts.slice(2) : parts;
        return meaningful.join("/");
    }

    function _formatTimeAgo(secs: int): string {
        if (secs < 60)
            return qsTr("just now");
        const mins = Math.floor(secs / 60);
        if (mins < 60)
            return qsTr("%1m ago").arg(mins);
        const hrs = Math.floor(mins / 60);
        return qsTr("%1h ago").arg(hrs);
    }
}
