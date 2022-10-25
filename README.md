# My dotfiles

This repository contains my configuration files for Linux.

## Requirements

- git (to clone this repository)
- stow (to deploy the configuration files)
- $HOME/.config directory used as XDG_HOME_CONFIG

## How to use
Clone this repository into your home directory.

Go into `$HOME/.dotfiles` and use `stow` to deploy the config files you want to.

```bash
cd $HOME/.dotfiles
stow <package name>
```

This will create required symbolic links so that your configuration files are taken into account the next time you start your tools.

To delete the symbolic links.

```bash
cd $HOME/.dotfiles
stow -D <package name>
```

