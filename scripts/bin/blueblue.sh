#!/bin/bash -xe

# Description: A script to toggle Bluetooth power and connect to a specified device.
# Usage: ./blueblue.sh [true]
#   - Passing 'true' as the first argument will attempt to reconnect only.
#   - Without an argument, it will toggle Bluetooth power and connect.

# --- Configuration ---
# Set the name of your Bluetooth device here (e.g., "WF-1000XM4").
# Use 'bluetoothctl devices' to find the correct name.
DEVICE_NAME="WF-1000XM5"

# --- Helper Functions ---

# Function to send a desktop notification
send_notification() {
  notify-send "Blueblue Manager" "$1"
}

# Function to connect to the specified Bluetooth device
connect_to_device() {
  # Get the MAC address of the device by its name
  local DEVICE_MAC=$(bluetoothctl devices | grep "$DEVICE_NAME" | awk '{print $2}')

  # Check if the device was found
  if [[ -z "$DEVICE_MAC" ]]; then
    send_notification "Error: Device '$DEVICE_NAME' not found. Is it turned on?"
    return 1
  fi

  # Check if the device is already connected
  local CONNECTED=$(bluetoothctl info "$DEVICE_MAC" | grep "Connected" | awk '{print $2}')

  if [[ "$CONNECTED" == "yes" ]]; then
    send_notification "Device '$DEVICE_NAME' is already connected."
    return 0
  fi

  send_notification "Attempting to connect to '$DEVICE_NAME'..."
  bluetoothctl connect "$DEVICE_MAC"

  # Optional: You can add a small delay here to give the connection time to establish
  # sleep 1
}

# --- Main Script Logic ---

# Check if Bluetooth is soft-blocked by rfkill
BLOCK_STATUS=$(rfkill list | grep -i hci0 -A1 | grep -i "Soft" | awk '{print $NF}')

if [[ "$BLOCK_STATUS" == "yes" ]]; then
  sudo rfkill unblock bluetooth
  send_notification "Unblocked Bluetooth using rfkill. Please run the script again."
  exit 1
fi

# Check the first argument to determine the script's mode
if [[ "$1" == "true" ]]; then
  connect_to_device
else
  # Get the current Bluetooth power state
  POWER_STATUS=$(bluetoothctl show | grep -i "Powered" | awk '{print $NF}')

  if [[ "$POWER_STATUS" == "yes" ]]; then
    bluetoothctl power off
    send_notification "Bluetooth is now OFF."
  else
    bluetoothctl power on
    send_notification "Bluetooth is now ON. Giving it a moment..."

    # Give the Bluetooth adapter a moment to initialize
    sleep 2

    connect_to_device
  fi
fi
