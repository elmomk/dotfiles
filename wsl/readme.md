# List all symlinks in your home directory pointing to your dotfiles folder

```bash
find ~ -maxdepth 2 -type l -lname "*dotfiles*"
/home/momoyang/.tmux.conf
/home/momoyang/.zshrc-work
/home/momoyang/.gitconfig
/home/momoyang/.zshrc-fn
/home/momoyang/.gitconfig-work
/home/momoyang/.config/nvim
/home/momoyang/.config/starship.toml
/home/momoyang/bin
/home/momoyang/.zshrc-zinit
/home/momoyang/.zshrc-personal

```

```bash
stow wsl
stow gitconfig 
stow lazyvim
stow starship
stow tmux
stow zsh-personal
```

# TODO: consolidate into one wsl for ease of use
