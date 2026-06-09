#!/usr/bin/env bash
# ensure_library.sh — scaffold the ONE shared teach-me Zensical library, idempotently.
#
# The teach-me skill keeps a single site (the "library") at $TEACHME_HOME/library,
# served by ONE server, with two top-level sections: Tutorials (teach-me explainers)
# and Daily (dated logs from the daily skill). Both skills call this to guarantee the
# library exists before they write into it. No-op if the library is already scaffolded.
#
# Usage: ensure_library.sh
# Honors $TEACHME_HOME (default: ~/teach-me); the library lives at $TEACHME_HOME/library.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(cd "${SCRIPT_DIR}/../assets" && pwd)"
HOME_DIR="${TEACHME_HOME:-$HOME/teach-me}"
LIB="$HOME_DIR/library"

# Already scaffolded → nothing to do.
[[ -f "$LIB/zensical.toml" ]] && exit 0

render() { # tmpl-name  site_name  description  -> stdout
  python3 - "$ASSETS_DIR/$1" "$2" "$3" <<'PY'
import sys, pathlib
tmpl, name, desc = sys.argv[1], sys.argv[2], sys.argv[3]
print(pathlib.Path(tmpl).read_text().replace("__SITE_NAME__", name).replace("__SITE_DESCRIPTION__", desc), end="")
PY
}

command -v uv >/dev/null 2>&1 || { echo "[teach-me] ERROR: 'uv' not found on PATH" >&2; exit 1; }
mkdir -p "$LIB"; cd "$LIB"
uv init -q . >/dev/null 2>&1 || true
uv add --dev zensical >/dev/null 2>&1
uv run zensical new . >/dev/null 2>&1
rm -f docs/markdown.md

render zensical.toml.tmpl "Explainers" "A library of teach-me explainers and dated daily logs — one section per topic." > zensical.toml
render library-index.md.tmpl "Explainers" "" > docs/index.md

# Section landing pages so the Tutorials/Daily nav blocks are never empty.
mkdir -p docs/tutorials docs/daily

cat > docs/tutorials/index.md <<'MD'
---
icon: lucide/graduation-cap
---

# Tutorials

!!! abstract "What this is"
    Structured explainers built with the teach-me method — lead with the gist, diagram the
    shape, ground the nouns before the rules, prove it with a worked example. Each topic is
    its own section in the left sidebar.

Pick a topic from the sidebar. New explainers are added here as their own section.
MD

cat > docs/daily/index.md <<'MD'
---
icon: lucide/calendar-days
---

# Daily

!!! abstract "What this is"
    Dated daily logs, newest first in the sidebar. A **morning** entry covers the previous
    workday and the plan for today; an **evening** entry recaps what actually got done.
    Built from git, GitLab MRs, Jira, and conversation memory.

Pick a date from the sidebar.
MD

echo "[teach-me] library ready: $LIB"
