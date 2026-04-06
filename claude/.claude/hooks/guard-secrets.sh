#!/bin/bash
# PreToolUse hook: prevent writing secrets/credentials into source files.
# User-level hook — applies to all projects.
#
# Merged from per-project hooks in gorilla_coach and gorilla_mcp.
# Checks both file destinations and content patterns.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
NEW_CONTENT=""

if [ "$TOOL_NAME" = "Edit" ]; then
  NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
elif [ "$TOOL_NAME" = "Write" ]; then
  NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
fi

# Skip if no content to check
if [ -z "$NEW_CONTENT" ]; then
  exit 0
fi

# Block writes to sensitive file types regardless of project
BASENAME=$(basename "$FILE_PATH" 2>/dev/null || echo "")
case "$BASENAME" in
  .env|.env.*|*.key|*.pem|credentials.json|*-sheets-key.json)
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked: cannot write to secrets/credential files"}}' >&2
    exit 2
    ;;
esac

# Check for hardcoded secret patterns in content being written
# Covers: Google API keys, GitHub PATs, OpenAI/Anthropic keys, AWS access keys,
# PEM private keys, Google service account keys, Tailscale auth keys
if echo "$NEW_CONTENT" | grep -qE '(AIza[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9]{20,}|sk-ant-[A-Za-z0-9]{20,}|AKIA[A-Z0-9]{16}|-----BEGIN (RSA |EC )?PRIVATE KEY|gsk_[A-Za-z0-9]{20,}|tskey-[A-Za-z0-9-]{20,})'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked: detected hardcoded API key or private key in content. Use environment variables instead."}}' >&2
  exit 2
fi

exit 0
