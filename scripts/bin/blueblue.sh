#!/bin/bash -xe

POWER=$(bluetoothctl show | grep -i powerstate | awk '{print $NF}')
BLOCK=$(rfkill list | grep -i hci0 -A1 | grep Soft | awk '{print $NF}')

if [[ "$BLOCK" == "yes" ]]; then
  sudo rfkill unblock bluetooth
  notify-send "Bluetooth" "rfkill unblock bluetooth first"
fi

if [[ "$POWER" == "on" ]]; then
  bluetoothctl power off
  notify-send "Bluetooth" "off"
else
  bluetoothctl devices
  bluetoothctl power on
  notify-send "Bluetooth" "on"
  DEVICE=$(bluetoothctl devices | grep WF | awk '{print $2}')
  bluetoothctl connect $DEVICE
fi
