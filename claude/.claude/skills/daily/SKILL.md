---
name: daily
description: "Build a teach-me-styled, dated daily log in the shared teach-me site. A morning run covers the previous workday + today's plan (from git, GitLab MRs, the GitLab SaaS board, and claude memory); an evening run recaps what got done today. Triggers: daily, standup, standup notes, morning/evening update, recap, what did I do today/yesterday, what's my plan today."
argument-hint: "[morning|evening] [YYYY-MM-DD] [projects...] (e.g., 'evening', 'morning idp selfservice')"
---

# Daily

> **Write the output normally — caveman does not apply here.** The daily log page is
> read by other people. Full sentences, articles and connectives intact, whatever length
> the content needs. Caveman/compressed modes govern chat replies, not artifacts: if one
> is active, keep it for the conversation around the work and write the page itself in
> normal prose.

> **Write the page in a background agent, not in the foreground.** A daily run is a long
> sequence — collector, board, approved-mrs, many edits, then stamp/nav/lint/build/serve/
> publish. Inline it floods the transcript and interrupts whatever the user is actually
> doing. See **Delegation** below; it is the default, not an optimisation.

Produce a dated daily log as a page in the **shared teach-me library** (one site, one
server), under the `Daily` section — `~/teach-me/library/docs/daily/<DATE>.md`. Write it with
the teach-me method (gist first, scannable, refs everywhere), and serve it on the same port
as `/teach-me` (8042).

Two modes:

- **Morning** — covers the **previous workday** (recap) and **today's plan**, drawn from git
  log, GitLab MRs, the GitLab SaaS board (tasks-n-docs), and claude memory.
- **Evening** — recaps **what got done today**.

Background: read [references/data-sources.md](references/data-sources.md) (sources + window)
and [references/standup-format.md](references/standup-format.md) (page skeleton + writing
rules) before authoring.

## Delegation — run the whole thing in the background

Spawn an **Agent** with `run_in_background: true` and `subagent_type: general-purpose`, hand it
Steps 0–7, and carry on. Report the URL when it lands.

**When the daily is the user's only ask** (`/daily`, "standup", "what's my plan"), delegate the
whole run — there is nothing to report in the foreground until the page exists.

**When the daily follows work you just did in this session**, do not make the agent rediscover
that work. Report your findings in chat first, then pass them into the prompt verbatim — SHAs,
MR states, approvals, measurements, timestamps — with an explicit *do NOT re-verify these,
record them*. A subagent that re-derives state can reach a different answer than the one you
just gave the user, which is worse than not delegating.

Also put in the prompt:

- exactly which marker blocks to write and which to leave alone;
- "write in normal prose, not the active compressed chat style";
- the environment traps: the `/usr/bin` PATH strip in worktree shells, the transient
  `dial tcp … i/o timeout` on gitlab.com that must be retried **serially** rather than
  diagnosed, and never exporting `GITLAB_TOKEN` for gitlab.com calls;
- "report back only: what the page now contains, gate/build result, published URL".

**Two adjustments once delegated:**

- **Step 3.5 does not nest.** A subagent cannot spawn a subagent, so the delegated agent runs
  the low-hanging-fruit flow **inline** as its own step, after the plan block is written. It
  can then skip the `lhf` placeholder entirely and write the real section in one pass.
- **Never run two page-writers at once on the same library** — they race on `zensical build`
  and on the nav files. If one is already running, continue it with **SendMessage** instead of
  spawning another.

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

Run the collector for the right window (see data-sources.md). Use the teach-me
convention of delegating heavy gathering to a background Agent if it's slow; otherwise run
inline:

```bash
# evening recap of D:
bash scripts/collect.sh --since <DATE> --until <DATE+1>
# morning, mining the previous workday (only if no prior recap — see step 3):
bash scripts/collect.sh --since <PREV> --until <DATE>
```

Then pull **work-tracking tickets from the GitLab SaaS board** (`tasks-n-docs`, project
on gitlab.com) — **not Jira**; tracking moved off Jira on 2026-07-06 (see
data-sources.md). Resolve them with the board script:

```bash
python3 scripts/board_links.py --mine        # my open assigned board issues → KEY  web_url  status  summary
```

That yields the plan's in-progress/assigned tickets *and* their board links in one shot. Fold
git + GitLab + board + memory together. Optionally pass a project filter from the args to
narrow repos (`--repos`).

Ticket links come from the board — no Atlassian MCP, no base-URL dance (see the hyperlink rule
in Step 3). GitLab MR links come ready-made: each MR in the collector's `gitlab` section
carries its `web_url`.

## Step 3 — author the right block

Page skeleton and writing rules: see standup-format.md. Patch only the relevant marker block.

**Hyperlink every reference.** Render each GitLab MR as `[<project>!<iid>](<web_url>)` using
the `web_url` field from the collector's `gitlab` section, and each ticket as
`[<PE-KEY>](<board work-item URL>)` — keep the familiar `PE-XXXX` label, but link it to the
**GitLab SaaS board** work-item, resolved with `python3 scripts/board_links.py PE-1234 …`
(pass *every* key on the page; it prints `KEY  web_url  state`). Board-native items with no
PE-key link as `#<iid>`. **Fallback:** a key the board returns as `-` isn't mirrored yet — link
it to Jira `https://<atlassian.site>/browse/<KEY>`. Never leave a bare `!56` or
`PE-1234` in the page when you have its link.

### Morning → write the `plan` block

1. **Reuse rule (important).** Before mining the previous workday, check
   `docs/daily/<PREV>.md`. If it exists and its `recap` block is non-empty, **reuse that
   recap** (condense it) as the "Since <PREV>" section — do **not** re-run the collector/board
   for the previous day. Only if there's no such recap, mine the sources for the
   `<PREV>→<DATE>` window and synthesize "Since <PREV>" (you may also backfill <PREV>'s recap
   block while you're at it).
2. Write **Plan — <DATE>**: today's intended work from open/draft MRs, in-progress/assigned
   board tickets (current iteration; `board_links.py --mine`), and stated next-steps in memory — as a short checklist with
   refs. **Liveness guard:** memory and the dashboard cache lag reality, so don't write "merge
   X" / "push Y" for an MR that has already merged or closed. The `--live` "To merge" data from
   Step 3.6 is the authoritative open-MR set for this run — if a plan-cited MR isn't in it (or
   you can confirm it merged), mark that item done instead of listing it as pending work.
3. Write **Since <PREV> (<weekday>)**: the previous workday's outcomes (reused or mined).
4. Embed the low-hanging-fruit placeholder between the Plan checklist and "Since <PREV>"
   (verbatim — a **background agent** fills it; see Step 3.5):

   ```
   <!-- lhf:start -->
   _🍇 Low-hanging fruit: background analysis running…_
   <!-- lhf:end -->
   ```

### Evening → write the `recap` block

Write **What got done — <DATE>**: outcomes from today's commits, merged/updated MRs, board
status changes, and memory — lead with what shipped, reference IDs. Add a `!!! warning
"Blockers"` only for real external blockers (else "None").

Always (re)write the `!!! abstract "TL;DR"` gist to match the page's current contents. If the
page doesn't exist, create it from the skeleton with both marker blocks (the block you're not
writing stays empty).

## Step 3.5 — fire the low-hanging-fruit agent (morning only, background)

> **If you are yourself the delegated background agent** (see *Delegation* above), you cannot
> spawn another one. Run the low-hanging-fruit flow **inline** here instead, then write the
> real `lhf` section directly and skip the placeholder. Everything below applies only to a
> foreground run.

The plan's `lhf` block is filled by a **separate background agent**, not the main flow — its
~60 live GitLab calls (per-MR merge status + pipeline + approvals) must not slow the
build/serve. After writing the plan block (Step 3), spawn it and **do not wait**:

> Use the **Agent** tool with `run_in_background: true` and `subagent_type: general-purpose`,
> prompt: *"Run the low-hanging-fruit skill in daily mode: read
> `~/.claude/skills/low-hanging-fruit/SKILL.md` and execute its `daily <DATE>` flow — gather
> live MR signals, classify, patch the `lhf` block of that day's page, rebuild, and re-sync."*

Then continue to Steps 4–7 with the placeholder in place. The agent (via the **low-hanging-fruit**
skill) gathers in ~4s, classifies into Tier A/B/C/🔴, patches the `lhf` block, rebuilds, and
re-runs open_site.sh when it finishes (~20–40s later) — so the section lands in the page
shortly after you serve. In Step 7, tell the user the fruit analysis is
finishing in the background. (Evening runs skip this — the plan block and its `lhf` section
persist from the morning.)

## Step 3.6 — refresh the "To merge" block (both modes, inline)

The `merge` block (between the TL;DR and `plan`) is the topic-organized view of what's approved
and ready to merge — so a glance at the top of the page recalls the merge backlog by feature, not
by scrolling the `lhf` tiers. It's still cheap enough for the main flow — `--live` does one
light GitLab GET per approved MR (~15, ~5–10s), only to resolve a stale/`checking` merge_status
and drop already-merged MRs — so do it **inline in the main flow, every run** (morning *and*
evening). (This is far lighter than `lhf`'s full per-MR pipeline+approvals+threads sweep, which
is why that one stays in a background agent.)

1. Gather + group via the **approved-mrs** skill (don't reinvent the clustering):

   ```bash
   bash ~/.claude/skills/approved-mrs/scripts/approved.sh --live   # TSV: ref · merge_status · conflicts · created · web_url · title
   ```

   `--live` re-checks each row against GitLab so `merge_status` is the *resolved* verdict
   (`mergeable`/`conflict`, never a stale `checking`/`unchecked`) and any MR that has since merged
   is dropped — don't list a merged MR as "to merge". Cluster the rows by topic using the ladder
   in `~/.claude/skills/approved-mrs/SKILL.md` (same epic/ticket → same feature noun → same
   scope). If the script prints "no mr-review-status cache", leave the existing block untouched
   and note it in Step 7.

   **Emit a table, not prose bullets.** This block is *tabular state* — MRs with a topic, a
   status and a blocker. Rendered as prose it produced 2,379 inline MR links across the daily
   pages, 35% of their bytes as raw URL characters, and one page repeating `configs!1727`
   twelve times. A table says the same thing, scans, and passes the gate (tables are exempt
   from the prose link budget — that is the point of using one):

   ```markdown
   ## To merge — approved, by topic

   | MR | Topic | State | Blocked on |
   | --- | --- | --- | --- |
   | [cf!1723](url) → [cf!1724](url) | team-authz data model | approved · mergeable | parked — merge-order word |
   | [dp!103](url) | PE-2333 editor workbench | approved · green | bundle order |

   _13 mergeable · 1 conflicted · 1 Draft._
   ```

   Group rows by topic (same epic/ticket → same feature noun), leading with the epic/ticket.
   Keep the footnote to one line.

2. Write the section (opening with the H2 `## ✅ To merge — approved, by topic`) to
   `/tmp/merge-<DATE>.md`, then patch **only** the `merge` block — inserting it just above
   `<!-- plan:start -->` if the markers don't exist yet (pages created before this feature):

   ```bash
   python3 - "<DATE>" <<'PY'
   import sys, pathlib, re
   date = sys.argv[1]
   page = pathlib.Path.home()/f"teach-me/library/docs/daily/{date}.md"
   sec  = pathlib.Path(f"/tmp/merge-{date}.md").read_text().rstrip()
   body = page.read_text()
   block = "<!-- merge:start -->\n"+sec+"\n<!-- merge:end -->"
   if "<!-- merge:start -->" in body:
       body = re.sub(r"<!-- merge:start -->.*?<!-- merge:end -->", block, body, flags=re.S)
   else:                                   # older page: inject above the plan block
       body = body.replace("<!-- plan:start -->", block+"\n\n<!-- plan:start -->", 1)
   page.write_text(body)
   print("merge block patched")
   PY
   ```

## Step 3.7 — write the "Decisions and constraints" block (both modes, inline)

The `decisions` block is what a *later* session reads before it acts. It carries what was
decided today and — the part that matters more — what those decisions **forbid**: the
"NO MERGE until X" kind of constraint that binds work nobody has started yet.

It is templated here for exactly the reason the `merge` block is. Measured across ten
generated daily pages: the templated "To merge — approved" section appears **10/10**, an
ad-hoc decision table appears **1/10**. The one that existed sat at line 440 of a 479-line
page, under a heading invented that morning, with its hard constraints scattered into a
`Blockers` admonition — and the next working day two merge requests were merged against it.
Un-templated sections mostly do not get written, and on the day one does, nothing can find
it. A fixed heading, a fixed place and a fixed shape fix both halves. Cheap enough for the
main flow — it reads no live state at all — so do it **inline, every run**, morning *and*
evening.

1. Gather the day's decisions. The primary source is **this session's own conversation**: a
   call made in chat exists nowhere else until it is written down, and the collector cannot
   see it. Add anything decided in an ADR written today (`~/teach-me/library/docs/decisions/`),
   plus decisions visible as outcomes in the recap — an MR closed rather than merged, a
   design rejected, a deploy deliberately held.

   **A decision is not an intention.** "Finish !77" is plan work. A decision picked one
   option over another that was live, or forbade something: it has a *because*. If it has no
   rejected alternative and no consequence for tomorrow, it belongs in the plan block, not
   here.

2. **Emit a table, not prose bullets** — same reason as Step 3.6, and one more: the `Binds`
   column is the whole payload, and prose hides it.

   ```markdown
   ## Decisions and constraints

   | Decision | Why | Binds |
   | --- | --- | --- |
   | Close [dp!67](url), don't merge it | one annotation key + Rust-side alias resolution won; !67 inverts that | NO MERGE of [dp!67](url) — close it |
   | [cf!3050](url) lands before [cf!3106](url) | measured conflict in `team_rosters.yaml` | NO MERGE of [cf!3106](url) until [cf!3050](url) is on master |
   | Hold the devportal SIT deploy | no devportal build parses the new roster shape | DO NOT click `deploy:sit` on devportal until the reader fix lands |
   | Park the five open questions until Monday | the platform owner is away | — |
   ```

   The **`Binds` column is written for a session that was not here.** When the decision
   forbids something, open the cell with the prohibition in capitals — `NO MERGE`, `DO NOT
   DEPLOY`, `HOLD` — name what it applies to as a link, and name the condition that lifts it.
   A constraint with no stated release condition is a constraint nobody can ever clear, so
   always write the *until*. When a decision binds nothing past today, the cell is a bare
   `—`; that is a fact and it is fine.

3. **Degrade explicitly — never silently.** A day with no decisions writes exactly:

   ```markdown
   ## Decisions and constraints

   _No decisions recorded today._
   ```

   Not an empty section, and not a missing one. A reader must be able to tell "nothing was
   decided" from "nobody wrote this section", and an empty block reads as the second.

4. Write the section (opening with the H2 `## Decisions and constraints`, **that string
   exactly**) to `/tmp/decisions-<DATE>.md`, then patch **only** the
   `decisions` block — it sits directly under the TL;DR, above `merge`, because a constraint
   that forbids a merge has to be read before the list of merges:

   ```bash
   python3 - "<DATE>" <<'PY'
   import sys, pathlib, re
   date = sys.argv[1]
   page = pathlib.Path.home()/f"teach-me/library/docs/daily/{date}.md"
   sec  = pathlib.Path(f"/tmp/decisions-{date}.md").read_text().rstrip()
   body = page.read_text()
   block = "<!-- decisions:start -->\n"+sec+"\n<!-- decisions:end -->"
   m = re.search(r"<!-- decisions:start -->(.*?)<!-- decisions:end -->", body, flags=re.S)
   if m:
       # A later run with nothing new must not blank rows an earlier one recorded:
       # morning writes the block empty, and the day's decisions land in the evening.
       if "|" not in sec and "|" in m.group(1):
           print("decisions block kept — nothing new to record"); raise SystemExit
       body = body[:m.start()] + block + body[m.end():]
   elif "<!-- merge:start -->" in body:        # older page: inject above the merge block
       body = body.replace("<!-- merge:start -->", block+"\n\n<!-- merge:start -->", 1)
   else:                                       # older still: above the plan block
       body = body.replace("<!-- plan:start -->", block+"\n\n<!-- plan:start -->", 1)
   page.write_text(body)
   print("decisions block patched")
   PY
   ```

## Step 3.9 — stamp the page

A daily log is a point-in-time record, and the `merge`/`lhf` blocks are live GitLab state
frozen at write time. The filename gives the *day*; the stamp gives the *hour*, so a reader
can tell a page written four minutes ago from one written this morning. Idempotent —
re-running replaces the block, so morning and evening runs agree.

```bash
python3 "$TM/scripts/stamp.py" ~/teach-me/library/docs/daily/<DATE>.md --note "<morning|evening> run"
```

## Step 4 — sync nav

```bash
python3 scripts/sync_daily_nav.py     # regenerates the Daily nav block, newest first
```

## Step 5 — lint, then build

The readability gate runs first — it fails on a page that drifts past the budgets in
standup-format.md (TL;DR lede ≤80w, prose paragraph ≤250w, ≤4 links/100w in prose,
≤10% bold, no raw Unicode emoji). It exists because those rules were stated and ignored for
months while pages grew 1.49× in five weeks; nothing counted a word.

```bash
cd ~/teach-me/library
python3 tools/lint_readability.py     # exit 1 -> fix the page, don't touch the baseline
uv run zensical build                 # fix until "No issues found"
```

If the gate flags today's page, **reshape it, don't trim the facts**: threads → a table, the
narrative → a `??? abstract` collapsible, shipped/evidence/left → content tabs.

## Step 6 — serve (ONE server)

```bash
bash "$TM/scripts/serve_library.sh" 8042   # normal foreground command — the server detaches
```

The script **checks the port first**: if the library server is already up it no-ops,
otherwise it starts a detached no-cache static server over `site/` that survives the
Claude session (no `run_in_background` needed). It serves what step 5 built, straight from
disk — an already-open browser tab just needs a refresh. **Run only one server**, and never
`pkill` by name pattern — the script replaces a stale server by exact PID itself.

## Step 6.5 — publish to the SIT hub (background)

So teammates can read the same library on the shared internal gateway under **`/teach-me/`**
(path-based — the gateway IP, no DNS; `publish_sit.sh` prints the exact `http://<gw-ip>/teach-me/`),
publish the freshly built `site/` to the SIT hub — but never block the serve/open. Fire
it and move on: run `bash "$TM/scripts/publish_sit.sh"` via the Bash tool with
`run_in_background: true`. It bakes `site/` into an nginx image, pushes it to the registry, applies
the idempotent Deployment/Service/HTTPRoute, and rolls the pod (~1–2 min; you're notified on
completion). In Step 7, add a one-liner that the SIT copy is refreshing in the background. If it
reports a GAR `403 uploadArtifacts denied`, the one-time `project_iam` writer grant isn't applied
yet — surface that and continue.

## Step 7 — open + report

```bash
bash "$TM/scripts/open_site.sh" 8042 daily/<DATE>/
```

Tell the user the URL `http://127.0.0.1:8042/daily/<DATE>/` and a one-line summary of what
the page now contains (e.g. "morning: plan for today + Friday recap reused").

Note (headless dev box): port convention — **8042 is this box's live server**, reached by
the user's browser through the dev-server SSH helper's `-L 8042` forward (primary,
always-fresh). The laptop keeps a warm-standby copy on **8043**, refreshed by the laptop
browser-bridge's *sync-on-view* (rsync `docs/` → regen navs → rebuild) whenever a `:8042`
URL passes through it. Still open via open_site.sh — the bridge hop (`-R 8765`) is what
refreshes the standby and pops the tab. Page won't load or looks stale? The SSH tunnel is
down or lost the port race to a laptop process — this box's `~/teach-me/library/.serve.log`
shows the user's own page hits when the tunnel is healthy.

## Examples

- `/daily` — mode by clock, today's date, all repos
- `/daily morning` — force morning (prev-workday recap + today's plan)
- `/daily evening` — force evening recap of today
- `/daily morning idp selfservice` — morning, narrowed to those projects
- `/daily evening 2026-05-29` — write the evening recap for a specific date
