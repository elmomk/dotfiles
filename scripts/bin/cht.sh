#!/usr/bin/env bash

# This script is used to generate the cheat sheet for the cht.sh project.
# Based on the video of ThePrimeagen | tmux & cht.sh & fzf: https://youtu.be/hJzqEAf2U4I

# This script is used to generate the cheat sheet for the cht.sh project.
languages=$(echo "golang lua bash python rust shell" | tr ' ' '\n' | sort)
core_utils=$(echo "tmux vim nvim awk sed grep find sort uniq wc xargs bat fzf mv rm ssh systemctl docker kubectl terraform" | tr ' ' '\n' | sort)

selected=$(printf '%s\n%s' "$languages" "$core_utils" | fzf) 
echo "$selected"
read -rp "Enter topic: " query

if printf '%s' "$languages" | grep -qs "$selected"; then
  echo "https://cht.sh/$selected/$query"
  tmux neww bash -c "curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
else
    echo "https://cht.sh/$selected~$query"
  tmux neww bash -c "curl cht.sh/$selected~$query & while [ : ]; do sleep 1; done"
fi