# List all symlinks in your home directory pointing to your dotfiles folder

```bash
find ~ -maxdepth 2 -type l -lname "*dotfiles*"
/home/user/.tmux.conf
/home/user/.zshrc-work
/home/user/.gitconfig
/home/user/.zshrc-fn
/home/user/.gitconfig-work
/home/user/.config/nvim
/home/user/.config/starship.toml
/home/user/bin
/home/user/.zshrc-zinit
/home/user/.zshrc-personal

```

```bash
check_stow
Target: Parent Directory (default)
------------------------------------
[ ] alacritty
[ ] arduino
[ ] dunst
[ ] fish
[x] gitconfig
[ ] hyprland
[ ] i3
[x] lazyvim
[ ] leftwm
[ ] mo-vim
[ ] regolith2_i3
[ ] scripts
[x] starship
[ ] sxhkdrc
[x] tmux
[ ] udev
[ ] wsl
[x] zsh-personal
[ ] zsh
```

```bash
stow wsl
stow gitconfig 
#WARNING: don't forget to add ~/.gitconfig-work
stow lazyvim
stow starship
stow tmux
stow zsh-personal
```

# TODO: consolidate into one wsl for ease of use ?
