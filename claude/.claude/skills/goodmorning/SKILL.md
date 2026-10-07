---
name: goodmorning
description: Survey every tmux pane to recover where each Claude session stopped, before restarting anything — window names, scrollback, and the transcript that maps each pane to a resumable session id. Use at the start of a day, after a reboot or a mass kill, or when the user says good morning, /goodmorning, where did we stop, what was I doing yesterday, survey the panes, what's in my tmux sessions, recover yesterday's context, catch me up.
---

# goodmorning

Yesterday's work is not in your context. It is in the panes. Before anything is
restarted, walk every one of them and write down where it stopped — because a
session that gets resumed without that is a session that redoes work, or drops
it silently.

This skill is **the survey step only**. It reads. It does not restart a session,
adopt a captain, or run `/daily` — those are separate decisions, and the survey
is what makes them answerable. See [After the survey](#after-the-survey).

Everything below was exercised against the live tmux server and transcript store
on 2026-08-14. Where something has **not** been verified, it says so.

## When not to use this

- **One pane.** Read it. A table of one row is ceremony.
- **A session you are already inside.** Its context is your context; the
  scrollback tells you nothing you do not already hold.
- **You already know what you are resuming.** Go resume it.

The survey earns its cost at three panes and up, and most of all after an event
that killed several at once.

## Step 1 — enumerate, and read the window names

```bash
tmux list-sessions
tmux list-panes -a -F '#{session_name}|#{window_index}|#{window_name}|#{pane_id}|#{pane_current_command}|#{pane_current_path}|#{pane_dead}'
```

**Window names are the first signal and they are free.** They survive a
tmux-resurrect restore, so a pane that came back as a bare shell still carries
yesterday's topic in its name — `✳ alloy-point-2-loki-investigation`,
`✳ Review merge request fast forward requirement`. Read them before you read
anything expensive.

Three things the listing will lie to you about:

- **Session creation time is the restore, not the work.** A restored server
  stamps every session with the same second. Measured 2026-08-14: all eight
  sessions on this box reported `created Fri Aug 14 09:16:00 2026`. That
  timestamp dates the restore and nothing else.
- **`pane_current_path` does not discriminate.** Measured the same morning: five
  differently-scoped sessions — alloy, configs, devportal, mr-watch, selfservice
  — all reported `/home/<user>/work/idp/selfservice`. The path tells
  you where a shell is, not what the session was doing. The window name is
  strictly better.
- **`pane_current_command` is not reliably `claude`.** Split panes inside a
  Claude window came back as `2.1.231` / `2.1.232` — a version string where a
  command name belongs. Filtering panes on `== claude` drops real ones.

## Step 2 — read the scrollback

This is the point of the skill.

```bash
tmux capture-pane -p -S -200 -t %8 | grep -v '^\s*$' | tail -25
```

The scrollback outlives the process. It holds three things that exist nowhere
else once the session is gone:

1. **the recap line** — what the session decided it had finished;
2. **the queued-but-unrun user message** still sitting at the prompt;
3. **the half-finished tool call** it died in the middle of.

Measured on pane `%8`, 2026-08-14, all three shapes present in 25 lines:

```text
※ recap: AUTO_HEAL_CONFLICTS is live in prod and MR !44 is merged; I'm now
  holding under the admiral session's orders, doing no new work. Next action is
  yours: pick which of #2832's four release-path fixes to implement…
❯ stop holding, claim !59
```

That second line is an **order the user typed and the session never ran.** It is
not in any transcript, not in any memory file, and it is lost the moment the pane
is cleared. Pane `%5` was holding one too (`❯ post it`). Recovering those is
worth the whole survey on its own.

**Write scrollback-heavy output to the scratchpad, not to chat**, past three or
four panes. Twenty-five lines times eight panes is two hundred lines of terminal
noise in the middle of a conversation that has not started yet.

## Step 3 — map each pane to its session id

`claude --resume` takes a session id, so a pane you cannot name is a pane you
cannot restart. Two methods; learn both, because the first one alone is
ambiguous on this box.

### By recency — and watch for the cluster

```bash
find ~/.claude/projects -name '*.jsonl' -newermt '2026-08-13' \
  -printf '%T@ %TY-%Tm-%Td %TH:%TM  %s  %p\n' | sort -rn | head -20
```

Transcripts live at `~/.claude/projects/<slugified-cwd>/<session-uuid>.jsonl`.
Ranking by last write puts yesterday's live sessions on top.

**A cluster of transcripts whose last write shares the same second is a mass
kill, not seven coincidences.** That is how 2026-08-14's 19:00 event was
identified — the shared timestamp *is* the evidence, and it tells you the
sessions ended together rather than finishing one by one.

The slug directory does **not** separate sessions: on this box ten of the twelve
most recent transcripts sat in the same
`-home-<user>-work-idp-selfservice/`. Recency ranks them; it does
not identify them. Which is why:

### By content fingerprint — when recency is ambiguous

Pick a handful of decisive keywords per pane from what its scrollback showed — a
distinctive filename, an env var, a CR name — and `grep -c` them across the
candidate transcripts. The transcript that hits is the pane's.

```bash
for f in ~/.claude/projects/*/*.jsonl; do
  n=$(grep -c -e 'AUTO_HEAL_CONFLICTS' -e '!44' "$f" 2>/dev/null)
  [ "$n" -gt 0 ] && echo "$n  $f"
done | sort -rn | head
```

Measured 2026-08-14: **this resolved five of seven panes in a single pass.**
Full recipe, including how to choose keywords that discriminate, in
[references/recipes.md](references/recipes.md).

## Step 4 — the two traps

Both of these were hit for real on 2026-08-14. Neither announces itself.

### Trap 1 — not every transcript is a pane

A transcript may belong to a **delegated teammate** of another session, with no
window of its own. Resuming one puts a subagent in a window where a lead should
be.

The discriminator is **`teamName`, not `agentName`.** Real pane-owning sessions
carry an `agentName` too — `be968d83` is `install-otel-operator`, `b0a01936` is
`alloy-rollout-manifests-merge`, both top-level sessions in their own windows.
Only a teammate carries `teamName`:

```bash
grep -m1 -o '"agentName":"[^"]*"\|"teamName":"[^"]*"' <transcript>.jsonl
```

Measured 2026-08-14, transcript `31eab5e2`:

```json
"agentName":"daily-writer"   "teamName":"session-66b4c9dc"
```

`teamName` is `session-<first 8 hex of the parent's uuid>`, so **it names the
owning session outright** — `session-66b4c9dc` → the pane running
`66b4c9dc-3719-47ec-8ad9-c885c738a0c9`. That turns the trap into a lookup: a
`teamName` means *don't resume this, resume its parent*. Verified across 20
teammate transcripts; every prefix that resolved pointed at a real session file.

**Caveat, measured the same pass:** two teammates (`fb6a635d`, `3f0e8ef7`) named
parents with no transcript on disk. A missing parent still proves the child is a
teammate — it just means the pane is gone and there is nothing to resume.

### Trap 2 — an earlier death is not part of the mass kill

A pane whose Claude exited hours before the others needs different handling, and
the shared-timestamp cluster in step 3 will not contain it. The tell is in the
shell, not the transcript: a zsh duration report and a resume line left in
history.

```text
took 8h13m28s
crew --resume <uuid>
```

Measured 2026-08-14: that pane's session had ended hours before the 19:00 event.
The `took ` marker is real and greppable — it showed on panes `%3` and `%15`
this morning. Treat such a pane on its own terms; do not fold it into the
cluster's story.

## Step 5 — report the table, then stop

One row per pane. This is the deliverable.

| pane | tmux session | window name | session id | resume mode | where it stopped |
| --- | --- | --- | --- | --- | --- |
| `%8` | selfservice | ✳ Review merge request fast forward requirement | `4486faa4…` | full | !44 merged, holding under admiral; **unrun order queued:** "stop holding, claim !59" |
| `%2` | alloy | ✳ alloy-point-2-loki-investigation | `b0a01936…` | summary | — |
| `%3` | captain dev | tmux namer | — | exited 8h13m earlier, not in the cluster | — |

Call out the queued-but-unrun messages explicitly. They are orders the user gave
that nobody executed, and they are the one thing a resume will not replay.

**Then stop.** Do not restart anything.

### Surface the resume choice; do not make it

Restarting turns on a resume-from-summary versus resume-full decision, and it is
the user's. Measured 2026-08-14 across seven sessions: roughly **550k tokens from
summary against 1.54M full** — near a 3× spread, large enough that it is a
budget decision and not an implementation detail. Put both numbers in front of
the user and let them pick.

Note also that **every session will park at its resume prompt until answered** —
`This session is Xh Ym old and N tokens` *(wording as reported 2026-08-14; not
re-observed, since a live session does not display it)*. Resuming seven sessions
is therefore seven prompts, not one, and nothing proceeds until each is cleared.

## After the survey

The survey ends here. What follows it is chosen, not implied:

- **`/admiral`** — if the recovered sessions should come back as a commanded
  fleet, that skill adopts and spawns captains. It has its own rules about
  ungoverned sessions; this skill does not duplicate them.
- **`/daily`** — the morning log. The survey's table is good input to it; it is
  not a substitute for it, and this skill never runs it.

Hand over the table and let the next decision be made with it.

## Known rough edges

- **`pgrep -f <uuid>` self-matches inside the Bash tool.** The `zsh -c` wrapper
  carries the command text, so the pattern finds the very shell searching for it
  and every "is it still running?" check answers yes forever. Verified
  2026-08-14: `pgrep -f` on a uuid that exists nowhere but in that command line
  returned a PID. Filter with `ps -eo comm,args` excluding shells, or match on
  the Claude process's `argv[0]`.
- **`stat -h` and `basename -h` are not valid here.** GNU coreutils 9.4 parses
  `-h` as a flag and both error out with `invalid option -- 'h'`. Use `stat -c`
  and shell parameter expansion (`${p##*/}`) instead. Both were hit on
  2026-08-14.
- **A missing window is a note, not a verdict.** Windows get renamed, moved and
  broken out while the session under them runs on.
- **Scrollback is finite.** `-S -200` is a working default, not a guarantee; a
  session that printed a lot after its last useful line will have pushed it out.
  Widen to `-S -1000` for a pane whose story does not close.
