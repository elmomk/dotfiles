#!/bin/bash
cd "$(dirname "$0")/.." || exit 1

case "${1:-}" in
  home|laptop)
    stow -v core zsh zsh-personal starship tmux gitconfig hyprland mo-vim udev claude
    ;;
  wsl)
    stow -v core wsl zsh zsh-personal starship tmux gitconfig mo-vim claude
    ;;
  *)
    echo "Usage: $0 {home|laptop|wsl}"
    exit 1
    ;;
esac
