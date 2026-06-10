---
name: cc-mem
description: "Search conversation memory across sessions. Triggers: history, recall, past work, what did I do, search memory, standup, status update."
argument-hint: "Search query (e.g., 'Docker compose', 'migration --project configs', '--status')"
---

# Claude Code Memory Search

Search the persistent memory index at `~/.memory/` for past conversations, decisions, and patterns across all projects.

## Binary location

`/home/momoyang/work/git/claude-memory/bin/hooks`

## Instructions

**Always delegate the search to a background Agent.** This keeps the main context clean and lets the search run without blocking.

Spawn an Agent with the following prompt, filling in the user's query and flags:

```
Search claude-memory for the user's request. Run the appropriate command and return the results.

Binary: /home/momoyang/work/git/claude-memory/bin/hooks

User request: <paste the user's full /cc-mem arguments here>

Rules for determining the command:

1. If the request contains search terms, run:
   /home/momoyang/work/git/claude-memory/bin/hooks search "<query>" [flags]
   Supported flags: --project <name>, --since <YYYY-MM-DD>, --limit <n>

2. If the request is "--status" or "status", run:
   /home/momoyang/work/git/claude-memory/bin/hooks status

3. If the request is "--index" or "reindex", run:
   /home/momoyang/work/git/claude-memory/bin/hooks index

4. If the request is "--recent" or "recent" or empty, run:
   tail -30 "$(ls -t ~/.memory/*.md | head -1)"

5. If the request is about standup, jira update, or weekly summary:
   - First run: /home/momoyang/work/git/claude-memory/bin/hooks search "<relevant terms>" --since <appropriate date> --limit 30
   - Then summarize the results into a standup/update format grouped by project.

Return the raw output. Do not truncate or summarize unless asked for standup/jira format.
```

After the Agent returns, relay the results to the user. For standup/jira requests, format the output as a structured update.

## Examples

- `/cc-mem Docker compose` — search for Docker-related work
- `/cc-mem migration --project configs` — search within a specific project
- `/cc-mem alertmanager --since 2026-04-10` — recent alertmanager work
- `/cc-mem --status` — show index statistics
- `/cc-mem --recent` — browse latest entries
- `/cc-mem standup` — generate standup notes from today's activity
- `/cc-mem jira update --since 2026-04-14` — summarize work for jira
