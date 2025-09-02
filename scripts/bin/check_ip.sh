#!/bin/bash

# Define the log file path
LOG_FILE="/tmp/logs_ip"

# Get the current IP address for the 'wlan' interface.
# The command 'ip a' lists all network interfaces and their details.
# 'grep wlan' filters for the line containing "wlan".
# 'awk' is used to get the second field, which is the IP address with the CIDR notation (e.g., 192.168.1.10/24).
# 'cut' then removes the CIDR part, leaving only the IP address.
IP_ADDRESS=$(ip a | grep "inet" | grep "wlan" | awk '{print $2}' | cut -d'/' -f1)

# Check if an IP address was found.
if [[ -z "$IP_ADDRESS" ]]; then
  # If no IP was found, log an error message.
  echo "$(date +"%Y-%m-%d %H:%M:%S") - ERROR: Could not find IP address for wlan interface." >>"$LOG_FILE"
  exit 1
fi

# Get the current timestamp in YYYY-MM-DD HH:MM:SS format.
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Combine the timestamp and IP address into a single log entry.
LOG_ENTRY="$TIMESTAMP - Current IP is: $IP_ADDRESS"

# Append the log entry to the log file.
# The '>>' operator appends to the file instead of overwriting it.
echo "$LOG_ENTRY" >>"$LOG_FILE"

# Provide a success message to the user.
echo "IP address logged to $LOG_FILE"
