#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
stow -v core zsh zsh-personal starship tmux gitconfig hyprland mo-vim udev
