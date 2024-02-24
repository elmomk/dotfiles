# Set umask
umask 0007

# Commands to run in interactive sessions
if status is-interactive
    # Remove greeting message
    set -g fish_greeting

    set -gx TERMINFO_DIRS $TERMINFO_DIRS:$HOME/.local/share/terminfo
    # Indicate 24-bit color support
    #set -gx COLORTERM truecolor

    # Prefer US English and use UTF-8
    set -gx LANG en_US.UTF-8
    set -gx LC_ALL en_US.UTF-8

    # Make nvim the default editor
    set -gx EDITOR nvim

    # Settings for GPG
    set -gx GPG_TTY (tty)

    # # # Load Starship Prompt
    # starship init fish | source
    # # # Load zoxide
    # zoxide init fish | source
    #
    # source ~/.apikeys
    # export AWS_VAULT_PROMPT=ykman

    # Update PATH
    # if test (uname -s) = Darwin
    #     # Use GNU utils
    #     #fish_add_path --prepend --move (brew --prefix coreutils)/libexec/gnubin (brew --prefix)/opt/gnu-sed/libexec/gnubin
    #     #set -gx MANPATH (brew --prefix coreutils)/libexec/gnuman $MANPATH
    #     fish_add_path --prepend --move (brew --prefix)/opt/gnu-sed/libexec/gnubin
    # end
    fish_add_path --prepend --move $HOME/bin $HOME/.local/bin $HOME/.krew/bin/ $HOME/go/bin/ $HOME/.cargo/bin

    # Load completions
    # if test -d (brew --prefix)"/share/fish/completions"
        # set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/completions
    # end
    # if test -d (brew --prefix)"/share/fish/vendor_completions.d"
        # set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
    # end

    for file in ~/.config/fish/completions/*.fish
        source $file
    end
end
