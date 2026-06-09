---
name: daily
description: "Build a teach-me-styled, dated daily log in the shared teach-me site. A morning run covers the previous workday + today's plan (from git, GitLab MRs, Jira, and claude memory); an evening run recaps what got done today. Triggers: daily, standup, standup notes, morning/evening update, recap, what did I do today/yesterday, what's my plan today."
argument-hint: "[morning|evening] [YYYY-MM-DD] [projects...] (e.g., 'evening', 'morning idp selfservice')"
---

# Daily

Produce a dated daily log as a page in the **shared teach-me library** (one site, one
server), under the `Daily` section — `~/teach-me/library/docs/daily/<DATE>.md`. Write it with
the teach-me method (gist first, scannable, refs everywhere), and serve it on the same port
as `/teach-me` (8042).

Two modes:

- **Morning** — covers the **previous workday** (recap) and **today's plan**, drawn from git
  log, GitLab MRs, Jira, and claude memory.
- **Evening** — recaps **what got done today**.

Background: read [references/data-sources.md](references/data-sources.md) (sources + window)
and [references/standup-format.md](references/standup-format.md) (page skeleton + writing
rules) before authoring.

## Step 0 — ensure the shared library exists

Daily writes into the teach-me library. Ensure it's scaffolded by calling teach-me's
`ensure_library.sh`, located in order:

1. `~/.claude/skills/teach-me/scripts/ensure_library.sh`
2. `~/work/git/configs/.agents/skills/teach-me/scripts/ensure_library.sh`

```bash
for d in ~/.claude/skills/teach-me ~/work/git/configs/.agents/skills/teach-me; do
  [ -f "$d/scripts/ensure_library.sh" ] && TM="$d" && break
done
[ -n "$TM" ] && bash "$TM/scripts/ensure_library.sh" || echo "install the teach-me skill first"
```

Keep `$TM` — its `scripts/open_site.sh` is reused in step 7.

## Step 1 — mode, date, previous workday

Mode = the `morning`/`evening` arg if given, else by local time (morning if hour < 12).
Compute the dates with one helper:

```bash
python3 - "$@" <<'PY'
import sys, datetime as dt
args = [a.lower() for a in sys.argv[1:]]
mode = "morning" if "morning" in args else "evening" if "evening" in args else None
# explicit date arg?
date = next((a for a in args if len(a)==10 and a[4]=="-" and a[7]=="-"), None)
D = dt.date.fromisoformat(date) if date else dt.date.today()
if mode is None:
    mode = "morning" if dt.datetime.now().hour < 12 else "evening"
p = D - dt.timedelta(days=1)
while p.weekday() >= 5:          # skip Sat/Sun
    p -= dt.timedelta(days=1)
print(f"MODE={mode}\nDATE={D}\nPREV={p}\nPREV_DOW={p.strftime('%A')}\nDOW={D.strftime('%A')}")
PY
```

## Step 2 — gather context

Run the collector for the right window (see data-sources.md). Use the teach-me/cc-mem
convention of delegating heavy gathering to a background Agent if it's slow; otherwise run
inline:

```bash
# evening recap of D:
bash scripts/collect.sh --since <DATE> --until <DATE+1>
# morning, mining the previous workday (only if no prior recap — see step 3):
bash scripts/collect.sh --since <PREV> --until <DATE>
```

Then query **Jira** via the Atlassian MCP `searchJiraIssuesUsingJql` (JQL examples in
data-sources.md): recent transitions for the recap, open in-sprint issues for the plan. Fold
git + GitLab + Jira + memory together. Optionally pass a project filter from the args to
narrow repos (`--repos`) and JQL.

Capture the **Atlassian site base URL** for building issue links — call
`getAccessibleAtlassianResources` once (its `url` is the `https://<site>.atlassian.net` base),
so every Jira key can be linked as `<base>/browse/<KEY>`. GitLab MR links come ready-made:
each MR in the collector's `gitlab` section carries its `web_url`.

## Step 3 — author the right block

Page skeleton and writing rules: see standup-format.md. Patch only the relevant marker block.

**Hyperlink every reference.** Render each GitLab MR as `[<project>!<iid>](<web_url>)` using
the `web_url` field from the collector's `gitlab` section, and each Jira issue as
`[<KEY>](<base>/browse/<KEY>)` where `<base>` is the Atlassian site URL (get it once from the
MCP — see step 2 — or from a returned issue's `self`/browse URL). Never leave a bare `!56` or
`PE-1234` in the page when you have its link.

### Morning → write the `plan` block

1. **Reuse rule (important).** Before mining the previous workday, check
   `docs/daily/<PREV>.md`. If it exists and its `recap` block is non-empty, **reuse that
   recap** (condense it) as the "Since <PREV>" section — do **not** re-run the collector/Jira
   for the previous day. Only if there's no such recap, mine the sources for the
   `<PREV>→<DATE>` window and synthesize "Since <PREV>" (you may also backfill <PREV>'s recap
   block while you're at it).
2. Write **Plan — <DATE>**: today's intended work from open/draft MRs, in-progress/assigned
   Jira in the active sprint, and stated next-steps in memory — as a short checklist with
   refs.
3. Write **Since <PREV> (<weekday>)**: the previous workday's outcomes (reused or mined).

### Evening → write the `recap` block

Write **What got done — <DATE>**: outcomes from today's commits, merged/updated MRs, Jira
transitions, and memory — lead with what shipped, reference IDs. Add a `!!! warning
"Blockers"` only for real external blockers (else "None").

Always (re)write the `!!! abstract "TL;DR"` gist to match the page's current contents. If the
page doesn't exist, create it from the skeleton with both marker blocks (the block you're not
writing stays empty).

### Cartoon of the day

Add a date-rotating tech cartoon at the bottom of the page (light note to end on). Run
`python3 scripts/cartoon.py <DATE>` and place its output as a `<!-- cartoon:start -->` …
`<!-- cartoon:end -->` block at the end of the page — **replacing** any existing cartoon block
(idempotent; the same date always yields the same cartoon, so morning and evening runs agree).
The helper rotates through 5 cartoons by `date.toordinal() % 5`, so consecutive days alternate.

## Step 4 — sync nav

```bash
python3 scripts/sync_daily_nav.py     # regenerates the Daily nav block, newest first
```

## Step 5 — build

```bash
cd ~/teach-me/library && uv run zensical build    # fix until "Build successful" / no issues
```

## Step 6 — serve (ONE server)

Serve the library with the Bash tool's `run_in_background` so it survives the turn:

```bash
bash "$TM/scripts/serve_library.sh" 8042
```

The script **checks the port first**: if a server is already serving the library it no-ops
(live-reload picks up the new page), otherwise it starts `zensical serve`. **Run only one
server**, and never `pkill -f "zensical serve"` (the pattern matches the killer's own command
line and kills the server you just started).

## Step 7 — open + report

```bash
bash "$TM/scripts/open_site.sh" 8042 daily/<DATE>/
```

Tell the user the URL `http://127.0.0.1:8042/daily/<DATE>/` and a one-line summary of what
the page now contains (e.g. "morning: plan for today + Friday recap reused").

## Examples

- `/daily` — mode by clock, today's date, all repos
- `/daily morning` — force morning (prev-workday recap + today's plan)
- `/daily evening` — force evening recap of today
- `/daily morning idp selfservice` — morning, narrowed to those projects
- `/daily evening 2026-05-29` — write the evening recap for a specific date
