#!/bin/bash

# Source the common function to get user session details
source /usr/local/lib/get-active-user.sh
get_active_user_session || exit 1

# Define the directory to save pictures
PIC_DIR="/home/$USER/Pictures/USB_Events"

# Create the directory as the user if it doesn't exist
sudo -u "$USER" mkdir -p "$PIC_DIR"

# Define the filename with a timestamp
FILENAME="$PIC_DIR/$(date +%Y-%m-%d_%H%M%S).jpg"

# Take the picture as the user
# --no-banner removes the default timestamp overlay from fswebcam
sudo -u "$USER" DISPLAY="$DISPLAY" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
/usr/bin/fswebcam --no-banner -r 1280x720 "$FILENAME"
