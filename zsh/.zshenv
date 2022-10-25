# First file used by ZSH
# Should only contian environment variables
# Must be located in $HOME
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Define some ZSH environment variables
export HISTFILE="$ZDOTDIR/.zhistory"
export HISTSIZE=10000                        # Max events for internal history
export SAVEHIST=10000                        # Max events in history file

# Define the default editor
export EDITOR="nvim"
export VISUAL="nvim"

# PATH
export PATH="$HOME/.local/bin:$PATH"
