#!/bin/bash -xe

POWER=$(bluetoothctl show | grep -i powerstate | awk '{print $NF}')

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
