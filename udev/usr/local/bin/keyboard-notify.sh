#!/bin/bash

# Source the common function and run it
source /usr/local/lib/get-active-user.sh
get_active_user_session || exit 1

# Run notify-send as the user, passing the required environment variables directly.
sudo -u "$USER" DISPLAY="$DISPLAY" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" /usr/bin/notify-send "ErgoDox EZ Connected" "Hello World!" --icon=input-keyboard
