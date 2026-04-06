---
name: pipx-run
description: Run a Python tool via pipx (auto-installs if needed). Use for Playwright, black, ruff, etc. ALWAYS use this instead of pip install or direct python tool invocation.
argument-hint: <tool> [args...] (e.g. playwright screenshot, black ., ruff check)
---

Run a Python CLI tool via `pipx run`. This auto-installs the tool in an isolated venv if not already present.

**IMPORTANT:** Never use `pip install`, `pip3 install`, or `python -m pip install`. Always use `pipx install` for persistent installs or `pipx run` for one-shot execution.

**Usage:** `$ARGUMENTS`

## Common tools

- `playwright install firefox` — install Playwright browser
- `playwright screenshot <url>` — take a screenshot
- `black .` — format Python code
- `ruff check .` — lint Python code
- `mkdocs serve` — serve docs locally
- `zensical build` — build static site
- `httpie` — HTTP client

## Steps

1. Parse the tool name and arguments from `$ARGUMENTS`
2. Verify `pipx` is available: `which pipx`
3. For one-shot execution: `pipx run $ARGUMENTS`
4. For persistent install (if the user asks to "install"): `pipx install <package>`
5. If the tool needs browsers (playwright), first run: `pipx run playwright install firefox`
6. Report the result

## When to use pipx install vs pipx run

- `pipx run <tool> [args]` — one-shot: downloads, runs, discards. Use when you just need to run a tool once.
- `pipx install <package>` — persistent: installs to `~/.local/bin`. Use when the user explicitly asks to install a tool, or when it will be called repeatedly (e.g. from scripts).
- `pipx list` — show persistently installed tools
