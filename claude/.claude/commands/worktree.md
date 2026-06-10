Create a git worktree using the user's `worktree` zsh function.

Usage: /worktree <branch-name>

## Workflow

Run the user's shell function via Bash:

```
worktree <branch-name>
```

This creates a new branch and worktree at `$(git rev-parse --show-toplevel)/../<branch with / replaced by _>`, then cds into it.

$ARGUMENTS is the branch name. If empty, run `git worktree list` and stop.

## After creation

- Report the worktree path so the user knows where it is
- Note: `cd` in a Bash subshell doesn't persist — use the worktree path in subsequent tool calls
