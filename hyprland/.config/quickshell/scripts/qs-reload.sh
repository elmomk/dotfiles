#!/usr/bin/env bash
# Quick reload helper for quickshell development
# Usage: qs-reload.sh [screenshot]
set -euo pipefail

pkill qs 2>/dev/null || true
sleep 1

qs > /tmp/qs-reload.log 2>&1 &
sleep 4

if grep -q "ERROR.*Failed to load" /tmp/qs-reload.log; then
    echo "FATAL: Config failed to load"
    grep "ERROR" /tmp/qs-reload.log
    exit 1
fi

echo "=== Status ==="
grep -E "INFO.*Loaded|ERROR|WARN.*scene" /tmp/qs-reload.log | head -10

if [[ "${1:-}" == "screenshot" || "${1:-}" == "s" ]]; then
    grim /tmp/qs-reload.png
    echo "Screenshot: /tmp/qs-reload.png"
fi
