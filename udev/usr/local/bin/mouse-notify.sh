#!/bin/bash

# Source the common function and run it
source /usr/local/lib/get-active-user.sh
get_active_user_session || exit 1

# Send notification using the exported variables
sudo -u "$USER" DISPLAY="$DISPLAY" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
/usr/bin/notify-send "Mouse Connected" "Kensington Trackball is ready" --icon=input-mouse
