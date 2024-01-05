#!/bin/bash

bluetoothctl info | grep Batter | awk '{print $NF}' | tr -d "()"
