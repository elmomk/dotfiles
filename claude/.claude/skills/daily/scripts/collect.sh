#!/usr/bin/env bash
# collect.sh — thin wrapper around gather_context.py for the daily skill.
#
# Fans out across git + GitLab + claude-memory for a time window and prints one JSON
# bundle on stdout. Jira is gathered separately by the skill via the Atlassian MCP.
#
# Usage:
#   collect.sh --since 2026-05-31 [--until 2026-06-01] [--repos "<glob> ..."]
#
# Env:
#   DAILY_REPOS  space-separated repo path globs (default: ~/work/git/* and ~/git/*).
#                Equivalent to passing --repos.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ARGS=("$@")
if [[ -n "${DAILY_REPOS:-}" ]] && [[ ! " ${ARGS[*]} " == *" --repos "* ]]; then
  ARGS+=(--repos "$DAILY_REPOS")
fi

exec python3 "$SCRIPT_DIR/gather_context.py" "${ARGS[@]}"
