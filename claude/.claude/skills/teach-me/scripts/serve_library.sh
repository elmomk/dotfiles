#!/usr/bin/env bash
# serve_library.sh — serve the teach-me library's built site, detached and cache-safe.
#
# Idempotent. Probes the port first: if OUR server (serve_site.py, recognized by its
# X-Teachme-Library header) already answers, this no-ops — it serves site/ straight from
# disk, so the latest `zensical build` shows up on the next browser refresh. If a stale
# `zensical serve` from an older skill version holds the port (it sends no Cache-Control,
# letting browsers cache pages — and the nav baked into them — for hours), that exact
# listener PID is killed and replaced. Anything else on the port is left alone (error).
#
# The server starts via setsid in its own session, so it survives the Claude session —
# run this as a normal foreground command; run_in_background is NOT needed.
#
# Usage: serve_library.sh [port]   (default 8042)
# Honors $TEACHME_HOME (default: ~/teach-me); the library lives at $TEACHME_HOME/library.
set -uo pipefail

PORT="${1:-8042}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${TEACHME_HOME:-$HOME/teach-me}"
LIB="$HOME_DIR/library"

[[ -f "$LIB/zensical.toml" ]] || { echo "[teach-me] ERROR: library not scaffolded at $LIB (run add_topic.sh first)" >&2; exit 1; }

# Probe the port. Marker header → our server is up, nothing to do.
headers="$(curl -sf -o /dev/null -D - "http://127.0.0.1:${PORT}/" 2>/dev/null)" || headers=""
if [[ -n "$headers" ]]; then
  if grep -qi '^x-teachme-library:' <<<"$headers"; then
    echo "[teach-me] server already running on 127.0.0.1:${PORT} — it serves site/ from disk, so the latest build is live; refresh the browser tab."
    exit 0
  fi
  # Someone else answers. If it's a leftover `zensical serve`, replace it (its missing
  # Cache-Control header is what made browsers show a stale nav). Kill by exact PID —
  # never by name pattern.
  pid="$(ss -ltnp 2>/dev/null | awk -v p=":${PORT}\$" '$4 ~ p {print $NF}' | grep -o 'pid=[0-9]*' | head -1 | cut -d= -f2)"
  if [[ -n "${pid:-}" ]] && grep -qa zensical "/proc/$pid/cmdline" 2>/dev/null; then
    echo "[teach-me] replacing stale 'zensical serve' (pid $pid) on port ${PORT} with the no-cache server …"
    kill "$pid" 2>/dev/null
    for _ in 1 2 3 4 5; do kill -0 "$pid" 2>/dev/null || break; sleep 0.4; done
  else
    echo "[teach-me] ERROR: port ${PORT} is held by something that isn't the library server (pid ${pid:-unknown}) — not touching it." >&2
    exit 1
  fi
fi

# The server serves site/ from disk — make sure a build exists (the skills build as a
# separate step; this covers a first run).
[[ -f "$LIB/site/index.html" ]] || (cd "$LIB" && uv run zensical build) || exit 1

setsid python3 "$SCRIPT_DIR/serve_site.py" "$PORT" >> "$LIB/.serve.log" 2>&1 < /dev/null &

for _ in 1 2 3 4 5 6 7 8; do
  sleep 0.4
  if curl -sf -o /dev/null "http://127.0.0.1:${PORT}/" 2>/dev/null; then
    echo "[teach-me] serving http://127.0.0.1:${PORT}/ (detached — survives this session; log: $LIB/.serve.log)"
    exit 0
  fi
done
echo "[teach-me] ERROR: server did not come up on port ${PORT} — last log lines:" >&2
tail -5 "$LIB/.serve.log" >&2
exit 1
