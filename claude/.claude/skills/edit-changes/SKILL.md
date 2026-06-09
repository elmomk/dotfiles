---
name: edit-changes
description: "Open files changed on current branch in nvim in a new tmux pane. Triggers: 'open changes in nvim', 'edit changed files', 'nvim diff', 'open my diff in nvim', 'split nvim with changes'."
argument-hint: "Optional base ref (default: master, falls back to main)"
---

# edit-changes

Splits the current tmux window horizontally and opens every file the current branch has changed (vs `master` by default) as nvim buffers in the new pane.

## When to use

- The user asks to edit, review, or open the files in their current branch's diff
- Phrasings: "open changes in nvim", "edit my changes", "open all changed files", "nvim split with the diff", "show changes in vim"

## How to invoke

Run the launcher script:

```
bash ~/.claude/skills/edit-changes/scripts/open-changes.sh [base-ref]
```

If the user mentions a specific base ("vs develop", "compared to origin/feat-x"), pass it as the argument. Otherwise omit — the script defaults to `master`, falling back to `main` automatically if `master` doesn't exist.

The script:

- Refuses with a clear error if not inside tmux (`$TMUX` unset). If this happens, tell the user to start a tmux session and retry.
- Refuses if the diff is empty. Surface the result; don't try to manufacture changes.
- Resolves the repo root via `git rev-parse --show-toplevel`, so it works correctly inside git worktrees regardless of which subdirectory the user is in.
- Includes the union of three sets, deduped: committed-vs-base, working-tree changes, and untracked files. This matches the "review my whole branch" intent rather than just committed work.
- Invokes nvim by absolute path (`/snap/bin/nvim` first, with fallbacks). **Why this matters:** the user's interactive shell aliases `nvim` to `/usr/bin/editor`, but `tmux split-window` runs the supplied command in a non-interactive shell where aliases don't load. A bare `nvim` resolves to nothing, the command exits immediately, and the new pane closes before the user can see it. The full path bypasses the alias system entirely.

## After running

The new pane is to the right of the original, with all changed files loaded as nvim buffers. The first file is shown; the rest are accessible via `:bn` / `:bp` / `:ls`. Mention this only if the user seems unfamiliar with buffer navigation — otherwise just confirm the pane opened and how many files it contains.
