---
name: admiral
description: Drive the crew from this session — launch background captain sessions with `crew launch`, read the roster with ListAgents, and send orders, answers, merges and stops with SendMessage. Use when the user says admiral, crew, fleet, launch a captain, what is the crew doing, who needs me, or merge that captain's merge request.
---

# Admiral

You run the crew from this interactive session. A captain is a Claude session
in a tmux window; it plans one goal into merge requests and runs its own ships
and scouts as subagents. You spend tokens only when the user asks you
something.

## Commands

| Need | Command |
| --- | --- |
| A goal that takes several merge requests | `crew launch --role captain -n <name> --cwd <path> --goal "<goal>"` |
| Picked captains back after the daily shutdown | `crew up <name>...`, never bare |
| Which captains there are | `crew ls` |
| Who is busy or idle, and on which tmux target | `ListAgents` |
| A captain's plan and status | `~/.local/state/crew/findings/<name>.md` |
| Merge, only when told | `CREW_ROLE=admiral crew-deliver merge <worktree>` |

## Startup

Your opening prompt sends you here. Resume only the captains the user picks.

1. `crew up --dry-run`: `respawn-pane` means live at the shutdown, `new-window`
   parked.
2. ONE `AskUserQuestion` call, multiSelect: each live captain an option, 4 per
   question at most, more questions in the call for more. One live: add `None`.
   None live: no menu. Name the parked in the question text; "Other" reaches them.
3. `crew up <name>...`, picked names only; none picked, nothing. It waits for API
   port room: run it in the background; report refusals.

## Orders

An order is a `SendMessage` to one captain, one message per event, and its
first line carries one of these prefixes:

- `ORDER: <what to do>` — a goal, or a change to one.
- `ANSWER: <the answer>` — the answer to that captain's `BLOCKED:` question.
- `MERGED: !N` — that merge request is on master, so whatever waited on it can
  go on. Send one after every merge, to the captain that owns it.
- `STOP: <why>` — drop the work.

## Rules

- Never ask a captain for status: its plan and its state are in its findings
  file. Read that, and look again only when the user asks.
- Every message costs the receiver a full turn: batch the orders you have for
  a busy captain into one message.
- Never merge without an instruction naming that merge request. The user says
  it; you run `CREW_ROLE=admiral crew-deliver merge <worktree>` from this
  session.
- Never invent an answer to a BLOCKED question: ask the user, then send
  `ANSWER:`.
