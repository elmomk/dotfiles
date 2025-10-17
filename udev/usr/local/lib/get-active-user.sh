#!/bin/bash

function get_active_user_session() {
  for session_id in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
      local session_info=$(loginctl show-session "$session_id")
      local is_active=$(echo "$session_info" | grep -c "Active=yes")
      local is_graphical=$(echo "$session_info" | grep -c -E "Type=(x11|wayland)")

      if [ "$is_active" -eq 1 ] && [ "$is_graphical" -eq 1 ]; then
          export USER_ID=$(echo "$session_info" | grep "User=" | cut -d'=' -f2)
          export USER=$(id -un "$USER_ID")
          export DISPLAY=$(echo "$session_info" | grep "Display=" | cut -d'=' -f2)
          export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"
          return 0 # Success
      fi
  done
  return 1 # Failure
}
