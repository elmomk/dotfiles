# ~/.zshenv — sourced by every zsh (incl. tmux panes). Keep minimal: env/PATH only.

# Guarantee the system directories are always present, even for non-interactive
# `zsh -c` shells whose inherited PATH was stripped (e.g. a direnv/mise revert to
# a snapshot captured by a minimal-PATH shell). Append any missing standard dir so
# tools like /usr/bin/git can never go "command not found". Order: existing PATH
# first (mise/user dirs keep priority), system dirs appended only if absent.
for _d in /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin; do
  case ":$PATH:" in
    *":$_d:"*) ;;
    *) PATH="$PATH:$_d" ;;
  esac
done
unset _d
export PATH

export PATH="$HOME/.local/bin:$PATH"
