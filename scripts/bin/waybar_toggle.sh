#!/bin/bash

if [ $(pgrep waybar) ]; then
  $(pkill waybar)
else
  $(waybar &)
fi
