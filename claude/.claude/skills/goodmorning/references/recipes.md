# goodmorning recipes

Long-form command recipes for the pane survey. Everything here was run against
the live tmux server and transcript store on 2026-08-14 unless marked otherwise.

## 1. Full enumeration in one pass

```bash
{
  echo "=== sessions ==="
  tmux list-sessions
  echo
  echo "=== panes ==="
  tmux list-panes -a -F \
    '#{session_name}|#{window_index}|#{window_name}|#{pane_id}|#{pane_current_command}|#{pane_current_path}|#{pane_dead}'
} > /tmp/pane-survey.txt
```

Pipe-separated rather than tab-separated on purpose: a tab-delimited read
collapses empty fields and shifts every column after the first missing one, and
`window_name` is routinely empty.

`#{pane_dead}` is `1` only when `remain-on-exit` is set; on a default server a
dead pane is simply gone, so **absence of a pane is not evidence a session died
cleanly.** The transcript timestamps in §3 are the better evidence.

## 2. Scrollback sweep across every pane

Write it to disk. Past three or four panes this is hundreds of lines and it does
not belong in the conversation.

Use the session's scratchpad directory if the harness gave you one; there is no
`~/scratch` on this box (checked 2026-08-14), so fall back to `/tmp` rather than
assuming it.

```bash
dir="${CLAUDE_SCRATCHPAD:-/tmp}"; mkdir -p "$dir"
out="$dir/scrollback-$(date +%Y%m%d-%H%M).txt"
: > "$out"
for p in $(tmux list-panes -a -F '#{pane_id}'); do
  {
    echo "########## $p  $(tmux display -p -t "$p" '#{session_name}:#{window_index} #{window_name}')"
    tmux capture-pane -p -S -200 -t "$p" | grep -v '^\s*$' | tail -25
    echo
  } >> "$out"
done
echo "$out"
```

Then read `$out` and quote only what matters into the table.

### Targeted greps that pay for themselves

Run these across all panes before reading anything in full — each one answers a
specific question in one line per pane.

```bash
# a queued-but-unrun user message still sitting at the prompt
for p in $(tmux list-panes -a -F '#{pane_id}'); do
  m=$(tmux capture-pane -p -S -50 -t "$p" | grep -E '^❯ ' | tail -1)
  [ -n "$m" ] && echo "$p  UNRUN: $m"
done

# the session's own recap of where it stopped
for p in $(tmux list-panes -a -F '#{pane_id}'); do
  m=$(tmux capture-pane -p -S -400 -t "$p" | grep -o '※ recap:.*' | tail -1)
  [ -n "$m" ] && echo "$p  $m"
done

# trap 2: a shell that outlived its Claude
for p in $(tmux list-panes -a -F '#{pane_id}'); do
  t=$(tmux capture-pane -p -S -400 -t "$p" | grep -oE 'took [0-9]+h[0-9]+m[0-9]+s' | tail -1)
  r=$(tmux capture-pane -p -S -400 -t "$p" | grep -oE -- '--resume [0-9a-f-]{36}' | tail -1)
  [ -n "$t$r" ] && echo "$p  took='$t'  resume='$r'"
done
```

The unrun-message grep found `❯ stop holding, claim !59` on `%8` and
`❯ post it` on `%5` on 2026-08-14. Neither existed anywhere else.

## 3. Rank transcripts, and spot the mass kill

```bash
find ~/.claude/projects -name '*.jsonl' -newermt '2026-08-13' \
  -printf '%T@ %TY-%Tm-%Td %TH:%TM  %s  %p\n' | sort -rn | head -20
```

Columns: epoch (for exact-second comparison), human time, size in bytes, path.

**Read the epoch column, not the human one.** `%TH:%TM` rounds to the minute and
hides the signal — seven sessions killed in the same second and seven that
happened to be busy in the same minute look identical at minute resolution. The
`%T@` value is what proves a mass kill.

To collapse the cluster explicitly:

```bash
find ~/.claude/projects -name '*.jsonl' -newermt '2026-08-13' -printf '%T@ %p\n' \
  | awk '{ printf "%d %s\n", $1, $2 }' \
  | sort -rn | awk '{ c[$1]++; f[$1]=f[$1]" "$2 } END { for (t in c) if (c[t]>1) print c[t]" transcripts at epoch "t":"f[t] }'
```

**A pair is not an event.** Measured 2026-08-14 on a live, healthy box, this
printed three groups of exactly two — a session and one of its teammates flush
to disk in the same second as a matter of course. What indicts a mass kill is a
group of *five or more*, or a group whose members are unrelated **top-level**
sessions (classify them with §5 first). Run the group members through the
teammate check before calling it an event.

Size matters too: a transcript of a few dozen KB is a short session, and one at
7 MB is a long one that will be expensive to resume in full. That is direct
input to the summary-versus-full choice the user has to make.

## 4. Content fingerprinting

Use when recency alone cannot say which transcript belongs to which pane —
which on this box is most of the time, because the cwd slug collapses many
unrelated sessions into one directory.

**Choosing keywords.** A good fingerprint term appears in one session's work and
nowhere else. In rough order of reliability:

1. a merge request or issue number (`!44`, `#2832`)
2. a CR or resource name (`my-cluster`, `AwsFleetProjectDefinition`)
3. an env var or constant (`AUTO_HEAL_CONFLICTS`)
4. a distinctive filename or path fragment

Avoid repo names, cluster names and skill names — they appear in every session
on the box and will match everything.

```bash
# usage: fingerprint '<kw1>' '<kw2>' ...
fingerprint() {
  args=(); for k in "$@"; do args+=(-e "$k"); done
  for f in ~/.claude/projects/*/*.jsonl; do
    n=$(grep -c "${args[@]}" "$f" 2>/dev/null || true)
    [ "${n:-0}" -gt 0 ] && printf '%6d  %s\n' "$n" "$f"
  done | sort -rn | head -5
}

fingerprint 'AUTO_HEAL_CONFLICTS' '!44'
```

Read the *ratio*, not the top hit alone: one transcript at 40 hits and the rest
at 1–2 is a clean match; several bunched together means the keywords are not
discriminating and you need a better one.

A single term is usually not enough. Measured 2026-08-14, `AUTO_HEAL_CONFLICTS`
alone returned `56 / 43 / 15 / 11 / 10` across five transcripts — no winner, and
taking the top row would have mapped the pane wrongly. Adding a second, narrower
term (`!44`) is what separated them. **Treat a flat distribution as a failed
fingerprint, not as an answer.**

Measured 2026-08-14: with well-chosen terms this resolved five of seven panes in
one pass.

## 5. Teammate-vs-session classification (trap 1)

Run this over every candidate transcript **before** proposing any of them for
resume.

```bash
for f in $(find ~/.claude/projects -name '*.jsonl' -newermt '2026-08-13'); do
  id="${f##*/}"; id="${id%.jsonl}"          # NOT basename -h; see below
  meta=$(grep -m1 -o '"agentName":"[^"]*"\|"teamName":"[^"]*"' "$f" | tr '\n' ' ')
  case "$meta" in
    *teamName*) echo "TEAMMATE  ${id:0:8}  $meta" ;;
    *)          echo "SESSION   ${id:0:8}  $meta" ;;
  esac
done | sort
```

The classification rule, measured:

| first user record has | verdict |
| --- | --- |
| `teamName` present | delegated teammate — **no window of its own, do not resume** |
| `agentName` only | top-level session — resumable, `agentName` is its topic |
| neither | top-level session |

`agentName` alone proves nothing: `be968d83` (`install-otel-operator`) and
`b0a01936` (`alloy-rollout-manifests-merge`) both carry one and both own panes.

### Resolving a teammate to its parent

`teamName` is `session-<first 8 hex of the parent's uuid>`:

```bash
tn=$(grep -m1 -o '"teamName":"session-[0-9a-f]*"' "$f" | grep -o '[0-9a-f]\{8\}$')
find ~/.claude/projects -name "$tn-*.jsonl"
```

Verified across 20 teammate transcripts on 2026-08-14; every prefix that
resolved pointed at a real session file, and the pairing
`"agentName":"daily-writer"` + `"teamName":"session-66b4c9dc"` resolved to
`66b4c9dc-3719-47ec-8ad9-c885c738a0c9`.

Two of the 20 (`fb6a635d`, `3f0e8ef7`) resolved to **no file at all**. That is
still a definite teammate classification — the parent's transcript is simply
gone, so there is nothing to resume and the row should say so.

## 6. Is a session still running?

```bash
ps -eo pid,comm,args | grep -v -E '^\s*[0-9]+\s+(zsh|bash|sh|grep)\b' | grep claude
```

**Do not use `pgrep -f <uuid>` from the Bash tool.** The `zsh -c` wrapper carries
the command text, so the pattern matches the shell running the search. Verified
2026-08-14: `pgrep -f` on a uuid present nowhere but in that command line
returned a PID. Any "is it still running?" loop built on it answers yes forever.

A non-Claude process can also legitimately carry a session id — the zsh tmux
launches a window with, or any command mentioning the id — so require the match
to be a Claude process by its `argv[0]`, not merely a line containing the uuid.

## 7. Coreutils traps on this box

GNU coreutils 9.4. Both of these were hit on 2026-08-14:

```bash
stat -h /tmp             # stat: invalid option -- 'h'
basename -h /tmp/foo/bar # basename: invalid option -- 'h'
```

`-h` is parsed as a flag by both, not as "no-dereference" or "help". Use:

```bash
stat -c '%Y %s %n' <file>    # epoch mtime, size, name
id="${f##*/}"; id="${id%.jsonl}"   # basename, in the shell
dir="${f%/*}"                       # dirname, in the shell
```

Also note the shell in this harness resets its cwd between calls — use absolute
paths, or `cd` inside the same compound command.

`date` is available and fine to call in a shell recipe; the restriction on
`Date.now()` applies to workflow scripts, not to these.
