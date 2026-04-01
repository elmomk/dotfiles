#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
stow -v core wsl zsh zsh-personal starship tmux gitconfig mo-vim
