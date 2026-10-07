#!/usr/bin/env bash
# record_gif.sh — record a terminal demo as a GIF via vhs (mise: vhs+ttyd+ffmpeg).
#
# Usage:
#   record_gif.sh <out.gif> -- <shell command...>   # one-shot: types the command, records
#   record_gif.sh <out.gif> <tape-file>             # full control: your own .tape script
#
# One-shot mode generates a minimal tape (house theme, 1200x600, types the command,
# waits for it to finish). Point <out.gif> inside the library's docs/ tree (e.g.
# docs/tutorials/<topic>/gifs/demo.gif) so zensical copies it into the built site.
set -euo pipefail

export PATH="$HOME/.local/share/mise/shims:$PATH"
command -v vhs >/dev/null || { echo "vhs not found — run: mise use -g vhs ttyd ffmpeg" >&2; exit 1; }

out=${1:?usage: record_gif.sh <out.gif> -- <command...> | <out.gif> <tape-file>}
shift
mkdir -p "$(dirname "$out")"

if [ "${1:-}" = "--" ]; then
  shift
  cmd="$*"
  # vhs's tape parser rejects many absolute paths — record in the output dir by basename
  outdir=$(cd "$(dirname "$out")" && pwd)
  tape=$(mktemp --suffix=.tape)
  trap 'rm -f "$tape"' EXIT
  cat > "$tape" <<EOF
Output $(basename "$out")
Set FontSize 18
Set Width 1200
Set Height 600
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms
Type "$cmd"
Sleep 500ms
Enter
Sleep 6s
EOF
  (cd "$outdir" && vhs "$tape")
else
  vhs "$1"
fi
echo "wrote $out"
