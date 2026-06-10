Turn an ad-hoc workaround into a reusable tool. Given a description of a workaround or one-liner the user discovered, package it into the appropriate form(s):

## What to produce

Based on the workaround's nature, create one or more of:

### 1. Shell script (~/dotfiles/scripts/bin/)
For standalone CLI tools. Follow existing conventions:
- Shebang + description comment + usage
- `set -euo pipefail`
- Load credentials from `~/.secrets.json` via jq when env vars are missing
- Auto-resolve project from git remote, fall back to env vars
- Use python3 for JSON parsing (available everywhere via mise)
- Make executable, symlinked from ~/bin/

### 2. Claude Code skill (~/.claude/commands/*.md or ~/dotfiles/claude/.claude/commands/)
For tasks that benefit from AI reasoning. Follow existing skill format:
- One-line description at top
- Document available CLI tools and their usage
- Include a decision workflow (when to use which tool)
- Specify allowed tools if needed
- Symlink from dotfiles for portability

### 3. Shell function (~/.zshrc or ~/dotfiles/)
For quick aliases or wrappers that modify shell state (cd, export, etc.)

### 4. mise task (mise.toml)
For project-specific build/dev commands

## Process

1. Ask the user to describe the workaround (or read it from conversation context)
2. Determine which form(s) fit best
3. Check for existing tools that overlap — extend rather than duplicate
4. Write the tool(s), following the conventions of neighboring files
5. Wire up: chmod +x, symlinks, add to relevant index/docs
6. Test the new tool works

## Conventions to follow
- Scripts go in ~/dotfiles/scripts/bin/ (symlinked to ~/bin/)
- Skills go in ~/dotfiles/claude/.claude/commands/ (symlinked to ~/.claude/commands/)
- Credentials: always fall back to ~/.secrets.json via jq, never hardcode
- Project resolution: explicit arg > git remote > env var
- Keep tools focused — one tool, one job

ARGUMENTS: $ARGUMENTS
