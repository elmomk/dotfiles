#!/usr/bin/env bash
# Listen for monitor hotplug events and re-run display detection.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [ ! -S "$SOCKET" ]; then
    echo "display-monitor: socket not found, exiting" >&2
    exit 1
fi

socat -U - "UNIX-CONNECT:$SOCKET" |
while IFS='>>' read -r event data; do
    case "$event" in
        monitoradded*|monitorremoved*)
            sleep 1
            "$SCRIPT_DIR/display-detect.sh"
            ;;
    esac
done
