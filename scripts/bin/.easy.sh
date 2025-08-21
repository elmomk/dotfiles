#!/bin/bash

WORD="$(cat ~/bin/.pass | base64 -d)"

sleep .5
ydotool type "$WORD"
ydotool key 28:1 28:0
