#!/bin/bash

for session_id in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
  session_info=$(loginctl show-session "$session_id")

  is_active=$(echo "$session_info" | grep -c "Active=yes")
  is_graphical=$(echo "$session_info" | grep -c -E "Type=(x11|wayland)")

  if [ "$is_active" -eq 1 ] && [ "$is_graphical" -eq 1 ]; then
    USER_ID=$(echo "$session_info" | grep "User=" | cut -d'=' -f2)
    USER=$(id -un "$USER_ID")
    DISPLAY=$(echo "$session_info" | grep "Display=" | cut -d'=' -f2)
    break
  fi
done

if [ -z "$USER" ]; then
  exit 1
fi

# Set the DBUS address variable for the user's session
DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"

# Run notify-send as the user, passing the required environment variables directly.
sudo -u "$USER" DISPLAY="$DISPLAY" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" /usr/bin/notify-send "ErgoDox EZ Connected" "Hello World!" --icon=input-keyboard
