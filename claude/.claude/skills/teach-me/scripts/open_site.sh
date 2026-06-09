#!/usr/bin/env bash
# open_site.sh — open a served teach-me site in the user's browser.
#
# Usage: open_site.sh [port] [path]
#   port  default 8042
#   path  default / (e.g. "walkthrough/" to deep-link a page)
#
# Prefers open-url (WSL/macOS/Linux-aware, with a headless browser-bridge fallback),
# then falls back to WSL (explorer.exe), macOS (open), Linux (xdg-open). Always exits
# 0 so a non-zero from the launcher (explorer.exe is noisy) never aborts a caller.
set -uo pipefail
PORT="${1:-8042}"
PATH_SUFFIX="${2:-}"
URL="http://127.0.0.1:${PORT}/${PATH_SUFFIX}"

if command -v open-url >/dev/null 2>&1; then
  # On a headless dev-server, open-url hands the URL to a laptop-side browser-bridge
  # over the SSH reverse tunnel. The page only loads if the serve port is also
  # forward-tunnelled (the dev-server helper sets up both -R 8765 and -L 8042).
  open-url "$URL" || true
elif grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
  explorer.exe "$URL" || true
elif command -v open >/dev/null 2>&1; then
  open "$URL" || true
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" || true
else
  echo "[teach-me] open this in your browser: $URL"
fi
echo "[teach-me] $URL"
exit 0
