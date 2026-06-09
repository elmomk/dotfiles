#!/usr/bin/env bash
# serve_library.sh — serve the teach-me library, but only if it isn't already served.
#
# Idempotent. Probes the port first: if an HTTP server already answers there, this
# no-ops (Zensical's live-reload picks up new/edited pages, so a second server is never
# needed and would only fail to bind the port). Otherwise it runs `zensical serve` in the
# foreground — launch this via the Bash tool's run_in_background so the server survives
# the turn.
#
# Usage: serve_library.sh [port]   (default 8042)
# Honors $TEACHME_HOME (default: ~/teach-me); the library lives at $TEACHME_HOME/library.
set -uo pipefail

PORT="${1:-8042}"
HOME_DIR="${TEACHME_HOME:-$HOME/teach-me}"
LIB="$HOME_DIR/library"

# Already serving? Probe the port. A response means a server is up — reuse it.
if curl -sf -o /dev/null "http://127.0.0.1:${PORT}/" 2>/dev/null; then
  echo "[teach-me] server already running on 127.0.0.1:${PORT} — live-reload will pick up your changes; not starting a second one."
  exit 0
fi

# As a fallback (no curl, or curl blocked), check whether anything is listening.
if command -v curl >/dev/null 2>&1; then :; else
  if command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ":${PORT}\b"; then
    echo "[teach-me] port ${PORT} already in use — assuming the library server is up; not starting a second one." >&2
    exit 0
  fi
fi

[[ -f "$LIB/zensical.toml" ]] || { echo "[teach-me] ERROR: library not scaffolded at $LIB (run add_topic.sh first)" >&2; exit 1; }

echo "[teach-me] starting server on http://127.0.0.1:${PORT}/ …"
cd "$LIB"
exec uv run zensical serve -a "127.0.0.1:${PORT}"
