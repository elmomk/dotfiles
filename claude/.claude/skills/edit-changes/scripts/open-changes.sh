#!/usr/bin/env bash
set -euo pipefail

base="${1:-master}"

if [ -z "${TMUX:-}" ]; then
    echo "edit-changes: not inside tmux (TMUX unset). Start tmux first." >&2
    exit 1
fi

if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "edit-changes: not in a git repository." >&2
    exit 1
fi
cd "$repo_root"

if ! git rev-parse --verify --quiet "$base" >/dev/null; then
    if [ "$base" = "master" ] && git rev-parse --verify --quiet main >/dev/null; then
        base=main
    else
        echo "edit-changes: base ref '$base' not found." >&2
        exit 1
    fi
fi

mapfile -t files < <(
    {
        git diff --name-only "$base"...HEAD
        git diff --name-only HEAD
        git ls-files --others --exclude-standard
    } 2>/dev/null | awk 'NF' | sort -u
)

if [ ${#files[@]} -eq 0 ]; then
    echo "edit-changes: no changed files vs $base." >&2
    exit 1
fi

# Resolve nvim binary by full path. The user's shell aliases `nvim` to /usr/bin/editor,
# but tmux split-window runs in a non-interactive shell where aliases don't load —
# the command would exit immediately and the new pane would close before display.
nvim_bin=""
for candidate in /snap/bin/nvim /usr/local/bin/nvim /usr/bin/nvim; do
    if [ -x "$candidate" ]; then
        nvim_bin="$candidate"
        break
    fi
done
if [ -z "$nvim_bin" ]; then
    echo "edit-changes: nvim binary not found in standard locations." >&2
    exit 1
fi

# printf %q handles filenames with spaces or shell metacharacters
quoted=$(printf '%q ' "${files[@]}")

tmux split-window -h -c "$repo_root" "$nvim_bin $quoted"

echo "edit-changes: opened ${#files[@]} file(s) vs $base in new pane."
