#!/bin/bash
# Claude Code attention notification — clickable, focuses the right tmux/workspace
# Runs notify-send in background so the hook returns immediately

# Capture ALL context before backgrounding (subshell loses env)
TMUX_SOCKET="${TMUX:-}"
TMUX_PANE_ID="${TMUX_PANE:-}"

# Query tmux targeting THIS pane specifically, not whichever pane is currently active
TMUX_SESSION=$(tmux display-message -t "$TMUX_PANE_ID" -p '#{session_name}' 2>/dev/null)
TMUX_WINDOW=$(tmux display-message -t "$TMUX_PANE_ID" -p '#{window_index}' 2>/dev/null)
TMUX_PANE_IDX=$(tmux display-message -t "$TMUX_PANE_ID" -p '#{pane_index}' 2>/dev/null)
TERM_PID=$(tmux display-message -t "$TMUX_PANE_ID" -p '#{client_pid}' 2>/dev/null)

# Resolve Hyprland window before backgrounding
WORKSPACE=""
WINDOW_ADDR=""
if [ -n "$TERM_PID" ]; then
  PPID_CHAIN="$TERM_PID"
  for _ in 1 2 3 4 5; do
    PARENT=$(ps -o ppid= -p "$PPID_CHAIN" 2>/dev/null | tr -d ' ')
    [ -z "$PARENT" ] || [ "$PARENT" = "1" ] && break
    MATCH=$(hyprctl clients -j | jq -r --argjson pid "$PARENT" '.[] | select(.pid == $pid) | "\(.workspace.id) \(.address)"')
    if [ -n "$MATCH" ]; then
      WORKSPACE=$(echo "$MATCH" | awk '{print $1}')
      WINDOW_ADDR=$(echo "$MATCH" | awk '{print $2}')
      break
    fi
    PPID_CHAIN="$PARENT"
  done
fi

# Check if user is already focused on this window+pane
ACTIVE_WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id' 2>/dev/null)
ACTIVE_ADDR=$(hyprctl activewindow -j | jq -r '.address' 2>/dev/null)
ACTIVE_TMUX_WIN=$(tmux display-message -p '#{window_index}' 2>/dev/null)
ACTIVE_TMUX_PANE=$(tmux display-message -p '#{pane_id}' 2>/dev/null)

# Skip if: same hyprland window is focused AND same tmux window+pane is active
if [ "$ACTIVE_ADDR" = "$WINDOW_ADDR" ] && [ "$ACTIVE_TMUX_WIN" = "$TMUX_WINDOW" ] && [ "$ACTIVE_TMUX_PANE" = "$TMUX_PANE_ID" ]; then
  exit 0
fi

(
  ACTION=$(notify-send -u normal -a "Claude Code" \
    -A "focus=Focus" \
    -t 30000 \
    "Claude Code needs attention" \
    "Session: ${TMUX_SESSION:-?}, Window: ${TMUX_WINDOW:-?}, Pane: ${TMUX_PANE_IDX:-?}" 2>/dev/null)

  if [ "$ACTION" = "focus" ]; then
    # Focus Hyprland window
    if [ -n "$WINDOW_ADDR" ]; then
      hyprctl dispatch focuswindow "address:${WINDOW_ADDR}" >/dev/null 2>&1
    elif [ -n "$WORKSPACE" ]; then
      hyprctl dispatch workspace "$WORKSPACE" >/dev/null 2>&1
    fi

    # Focus tmux pane — need TMUX env for tmux commands to work
    if [ -n "$TMUX_SOCKET" ] && [ -n "$TMUX_PANE_ID" ]; then
      export TMUX="$TMUX_SOCKET"
      tmux switch-client -t "${TMUX_SESSION}" 2>/dev/null
      tmux select-window -t "${TMUX_SESSION}:${TMUX_WINDOW}" 2>/dev/null
      tmux select-pane -t "${TMUX_PANE_ID}" 2>/dev/null
    fi
  fi
) &
disown
