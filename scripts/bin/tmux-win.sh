#!/usr/bin/env bash

# read -rp "Enter window name: " name
read -rp "Enter window name & command: " query

# if [[ -z "$name" || -z "$query" ]]; then
#     echo "Window name and command are required"
#     exit 1
# fi
if [[ -z "$query" ]]; then
    echo "Window name and command are required"
    exit 1
fi

# tmux neww bash -c "tmux-windowizer $name $query"
tmux neww bash -c "tmux-windowizer $query"
