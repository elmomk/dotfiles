#!/usr/bin/env bash

# This script is used to generate the cheat sheet for the cht.sh project.
# Based on the video of ThePrimeagen | tmux & cht.sh & fzf: https://youtu.be/hJzqEAf2U4I

# This script is used to generate the cheat sheet for the cht.sh project.
languages=$(echo "golang lua bash python rust shell" | tr ' ' '\n' | sort)
# core_utils=$(echo "$(/usr/bin/ls /usr/bin) az rsync  distrobox fd ripgrep pacman npm yay tmux vim nvim awk sed grep find sort uniq wc xargs bat fzf mv rm ssh systemctl docker kubectl terraform ansible scp" | tr ' ' '\n' | sort)
core_utils=$(echo "git tr cut useradd usermod groupmod groupadd paru helm az rsync  distrobox fd ripgrep pacman npm yay tmux vim nvim awk sed grep find sort uniq wc xargs bat fzf mv rm ssh systemctl docker kubectl terraform ansible scp" | tr ' ' '\n' | sort)
# core_utils=$(echo "paru useradd az rsync  distrobox fd ripgrep pacman npm yay tmux vim nvim awk sed grep find sort uniq wc xargs bat fzf mv rm ssh systemctl docker kubectl terraform ansible scp" | tr ' ' '\n' | sort)

selected=$(printf '%s\n%s' "$languages" "$core_utils" | fzf --preview 'curl -s cht.sh/{}' --preview-window=right:75%:wrap)
echo "$selected"
read -rp "Enter topic: " query

if printf '%s' "$languages" | grep -qs "$selected"; then
  echo "https://cht.sh/$selected/$query"
  curl cht.sh/$selected/$query 2>/dev/null | bat & while [ : ]; do sleep 1; done
  # tmux neww bash -c "curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
  # tmux display-popup -E "curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
else
    echo "https://cht.sh/$selected~$query"
  curl cht.sh/$selected~$query 2>/dev/null | bat & while [ : ]; do sleep 1; done
  # tmux neww bash -c "curl cht.sh/$selected~$query & while [ : ]; do sleep 1; done"
  # tmux display-popup -E "curl cht.sh/$selected~$query & while [ : ]; do sleep 1; done"
fi
