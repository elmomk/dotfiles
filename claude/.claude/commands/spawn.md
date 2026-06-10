Run a subagent in a new tmux pane using the `spawn-agent` wrapper, so its progress is visible and the final answer comes back to this session.

Usage: `/spawn [--tui] [--keep] <prompt>`

## Flags

- `--tui` — open the full interactive Claude Code TUI in the new pane (instead of headless stream). Returns the first complete assistant response by tailing the session transcript. Pane stays open for further interaction.
- `--keep` — headless mode, but leave the pane open after completion instead of auto-closing (useful for inspecting logs).

Default (no flags): headless mode, filtered stream-json in the pane, pane auto-closes ~5s after done.

## Workflow

`$ARGUMENTS` is the full invocation (flags + prompt). Parse trivially:
- If `$ARGUMENTS` starts with `--tui` or `--keep`, pass that flag through; the rest is the prompt.
- Otherwise the whole thing is the prompt.

Call via Bash:

```
spawn-agent "<prompt>" [--tui|--keep]
```

**Important:** the prompt must be **self-contained** — the subagent starts in a fresh session with no access to this conversation's context. Spell out file paths, what to read, and what format you want back.

Stdout from `spawn-agent` is the subagent's final answer. Stderr carries the pane id and transcript path (useful if you need to revisit the run).

## When to prefer this over the built-in `Agent` tool

- Longer research tasks where watching progress matters
- Tasks where you might want to jump into the pane and intervene (use `--tui`)
- Anything you'd want to rerun/inspect later (logs persist at `/tmp/spawn-agent-*.jsonl`)

For quick one-shot lookups, the built-in `Agent` is still faster (no process spawn overhead) and its output goes straight into context.
