#!/usr/bin/env bash
# add_topic.sh — ensure the single teach-me library exists, then add a topic section.
#
# The skill keeps ONE Zensical site (the "library") with a section per topic, served by
# ONE server — instead of a separate site/port per explanation. This script is idempotent:
# it scaffolds the library on first use, then creates docs/<topic>/ with a starter overview.
#
# Usage: add_topic.sh <topic-slug> ["Topic Title"] ["Topic description"]
#   topic-slug   kebab-case section folder, e.g. oauth-pkce
#   title        human title for the section (defaults to the slug)
#   description  optional one-line topic summary for the section overview
#
# Honors $TEACHME_HOME (default: ~/teach-me); the library lives at $TEACHME_HOME/library.
set -euo pipefail

SLUG="${1:?usage: add_topic.sh <topic-slug> [title] [description]}"
TITLE="${2:-$SLUG}"
DESCRIPTION="${3:-A teach-me explainer: ${TITLE}.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(cd "${SCRIPT_DIR}/../assets" && pwd)"
HOME_DIR="${TEACHME_HOME:-$HOME/teach-me}"
LIB="$HOME_DIR/library"

render() { # tmpl-name  site_name  description  -> stdout
  python3 - "$ASSETS_DIR/$1" "$2" "$3" <<'PY'
import sys, pathlib
tmpl, name, desc = sys.argv[1], sys.argv[2], sys.argv[3]
print(pathlib.Path(tmpl).read_text().replace("__SITE_NAME__", name).replace("__SITE_DESCRIPTION__", desc), end="")
PY
}

# 1. Ensure the library site exists (scaffold once, with the house-style theme + landing).
if [[ ! -f "$LIB/zensical.toml" ]]; then
  command -v uv >/dev/null 2>&1 || { echo "[teach-me] ERROR: 'uv' not found on PATH" >&2; exit 1; }
  mkdir -p "$LIB"; cd "$LIB"
  uv init -q . >/dev/null 2>&1 || true
  uv add --dev zensical >/dev/null 2>&1
  uv run zensical new . >/dev/null 2>&1
  render zensical.toml.tmpl "Explainers" "A library of teach-me explainers — one section per topic." > zensical.toml
  render library-index.md.tmpl "Explainers" "" > docs/index.md
  rm -f docs/markdown.md
  echo "[teach-me] created library: $LIB"
fi

# 2. Ensure the Tutorials section exists. Teach-me topics live UNDER docs/tutorials/ so they
#    group into one nav umbrella (the Daily skill owns docs/daily/ the same way). Self-heals
#    older libraries that predate this layout.
TUT="$LIB/docs/tutorials"
if [[ ! -f "$TUT/index.md" ]]; then
  mkdir -p "$TUT"
  render tutorials-index.md.tmpl "" "" > "$TUT/index.md"
  echo "[teach-me] created Tutorials section: docs/tutorials/"
fi

# 3. Add the topic section (starter overview) unless it already exists.
TDIR="$TUT/$SLUG"
if [[ -f "$TDIR/index.md" ]]; then
  echo "[teach-me] reusing existing topic: docs/tutorials/$SLUG/"
else
  mkdir -p "$TDIR"
  render index.md.tmpl "$TITLE" "$DESCRIPTION" > "$TDIR/index.md"
  echo "[teach-me] added topic: docs/tutorials/$SLUG/  (starter index.md)"
fi

cat <<EOF
[teach-me] library: $LIB
[teach-me] next:
  1. author $LIB/docs/tutorials/$SLUG/*.md  (overview + pages, applying the method)
  2. nest a nav block for "$TITLE" INSIDE the "Tutorials" section of $LIB/zensical.toml,
     between the \`# >>> tutorials\` / \`# <<< tutorials\` markers (pages as tutorials/$SLUG/<page>.md)
  3. add a row for this topic to the landing table in $LIB/docs/index.md (link tutorials/$SLUG/index.md)
  4. build:  (cd "$LIB" && uv run zensical build)   # fix until "No issues found"
  5. serve:  bash "$SCRIPT_DIR/serve_library.sh" 8042   # ONE server; no-ops if already running
  6. open:   bash "$SCRIPT_DIR/open_site.sh" 8042 tutorials/$SLUG/
EOF
