#!/bin/bash
# PreToolUse hook: intercept pip/pip3 install and direct invocation of python tools.
# Denies the command and tells Claude to use pipx instead.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only check Bash commands
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block pip install / pip3 install / python -m pip install
if echo "$CMD" | grep -qE '^\s*(pip3?|python3?\s+-m\s+pip)\s+install\b'; then
  PACKAGE=$(echo "$CMD" | grep -oP '(pip3?|python3?\s+-m\s+pip)\s+install\s+\K\S+' || echo "the package")
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Blocked: use 'pipx install $PACKAGE' for persistent install or 'pipx run $PACKAGE' for one-shot execution. Never use pip install directly.\"}}" >&2
  exit 2
fi

exit 0
