# Daily page format

Each day is one page: `~/teach-me/library/docs/daily/<YYYY-MM-DD>.md`. It is written with
the **teach-me method** (gist first, then scannable structure) and carries two independently
updatable marker blocks so a morning run and an evening run on the same date never clobber
each other.

## Page skeleton

```markdown
---
icon: lucide/calendar-days
---

# 2026-06-01 · Monday

!!! abstract "TL;DR"
    **The lede: ≤80 words.** The headline of the day, standing alone. Not a summary of
    everything — the one thing someone who reads nothing else must know.

    | Thread | State | Waiting on |
    | --- | --- | --- |
    | [PE-1234 → v2.5.0](#anchor) | :material-circle: staged for prod | `deploy:prod` click, gated on [cf!1768](url) |
    | [Team-authz](#anchor) | :material-circle: 10/11 approved | [cf!1766](url) first review |

??? abstract "The full picture"
    The complete narrative, unabridged — every thread, with its evidence. Nothing is cut;
    it is *layered*. A reader who wants the whole day opens this.

<!-- decisions:start -->
## Decisions and constraints
<!-- refreshed every run; what was decided today and what it forbids tomorrow. `_No decisions recorded today._` when there were none — never an empty block. -->
<!-- decisions:end -->

<!-- merge:start -->
## ✅ To merge — approved, by topic
<!-- refreshed every run from the approved-mrs skill; clusters my approved MRs by epic so the merge backlog is memorable. Replace, don't dup. -->
<!-- merge:end -->

<!-- plan:start -->
## Plan — 2026-06-01
- [ ] <today's intended work, one line each, with linked MR/ticket refs>
      e.g. Finish [configs!56](https://gitlab.example.com/.../merge_requests/56) ([PE-1234](https://gitlab.com/<board-group>/tasks-n-docs/-/work_items/1234))

<!-- lhf:start -->
_🍇 Low-hanging fruit: background analysis running…_
<!-- lhf:end -->

## Since 2026-05-29 (Friday)
- <what got done the previous workday — reused from its recap if it exists>
<!-- plan:end -->

<!-- recap:start -->
## What got done — 2026-06-01
- <outcome, not activity — e.g. "Merged [configs!56](<web_url>)", "[PE-1234](<browse_url>) → Done">

!!! warning "Blockers"
    <only real external blockers — waiting on review/deploy/infra. "None" if clear.>
<!-- recap:end -->
```

## Which block each run writes

- **Morning** run writes/replaces ONLY the `plan` block (creating the file with an empty
  `recap` block if it doesn't exist yet).
- **Evening** run writes/replaces ONLY the `recap` block (creating the file with an empty
  `plan` block if it doesn't exist yet).
- The `lhf` block (nested inside `plan`) is filled by a **background agent** the morning run
  spawns (SKILL.md Step 3.5), not the morning run itself — it lands a few seconds after serve.
  The morning run only writes the placeholder; evening runs leave the morning's `lhf` intact.
- The `decisions` block (directly under the TL;DR, above `merge`) is refreshed on **every**
  run, morning *and* evening (SKILL.md Step 3.7). It records the day's decisions and, in its
  `Binds` column, the constraints those decisions place on a *future* session — the
  "NO MERGE of X until Y" kind. It sits above `merge` on purpose: a constraint that forbids a
  merge must be read before the list of merges. A run with nothing to add leaves existing rows
  alone; a day with nothing decided renders the literal `_No decisions recorded today._`, so
  "nothing was decided" never looks like "nobody wrote this section". The heading string
  `## Decisions and constraints` is fixed: keep it exactly.
- The `merge` block (between TL;DR and `plan`) is refreshed on **every** run, morning *and*
  evening (SKILL.md Step 3.6). It's the topic-organized "what's approved and ready to merge"
  view — light to compute (`approved.sh --live`: one GitLab GET per ~15 approved MRs to resolve
  a stale/`checking` merge_status and drop already-merged ones, no per-MR pipeline/threads
  sweep), so unlike `lhf` it runs inline, not in a background agent. It sits highest on the page
  on purpose: the merge backlog is the thing to glance at first.

Patch surgically between the markers; never rewrite the whole file blind.

## Writing rules (carried over from the old standup)

- **Outcomes, not activity.** "Merged !56, deployed to SIT" beats "worked on the MR".
- **Refs must be clickable hyperlinks.** Every MR and board ticket is a Markdown link, not
  bare text:
    - GitLab MR → `[<project>!<iid>](<web_url>)` using the `web_url` from the collector's
      `gitlab` section, e.g. `[configs!56](https://.../merge_requests/56)`.
    - Ticket → `[<PE-KEY>](<board work-item URL>)` — the `tasks-n-docs` SaaS board item,
      resolved via `scripts/board_links.py` (see data-sources.md). Keep the `PE-XXXX` label but
      link the **board**, not Jira; an un-mirrored key falls back to
      `https://<atlassian.site>/browse/<KEY>`, board-native items → `#<iid>`.
    - Short shas and branch names can stay as inline code — they're greppable, not URLs.
  Never emit a bare `!56` or `PE-1234` when you have its URL.
- **One line per bullet.** Group by project only when there are multiple projects AND more
  than ~3 items in a section.
- **Blockers are external only** — waiting on a review, a deploy, infra, another person.
  Your own unfinished tasks are not blockers; they belong in the plan. Omit / say "None"
  when there are none.
- **Gist first.** The `!!! abstract` TL;DR should stand alone — someone reading only it
  should get the shape of the day.
- Keep the whole page tight: a daily log is skimmed, not studied.

## Budgets — enforced, not advisory

Every rule above was already here, and was ignored for months: pages grew **1.49×**, bold
**1.78×** and emoji **2.83×** in five weeks, and one TL;DR reached **516 words in a single
paragraph with 33 links**. The rules were never wrong — they were unmeasured.

`~/teach-me/library/tools/lint_readability.py` now measures them and **fails the build**.
Run it before you serve:

```bash
cd ~/teach-me/library && python3 tools/lint_readability.py   # exit 1 = fix it
```

| Budget | Limit | Why |
| --- | --- | --- |
| TL;DR lede | **≤80 words** | it is the headline, not the day |
| Any prose paragraph | **≤250 words** | past that, nobody is reading — layer the tail into `???` |
| Links in prose | **≤4 / 100 words** | tables and lists may be link-dense; *sentences* may not |
| Bold in prose | **≤10% of words** | at 1 word in 5, bold stops meaning anything |
| Raw Unicode emoji | **0** | use `:material-*:` — inline SVG, identical for every teammate |

**This does not mean write less.** It means put each thing in the container that fits it:

- a set of parallel threads → a **table** (`Thread | State | Waiting on`), not a paragraph
- the full narrative → a `??? abstract "The full picture"` collapsible, unabridged
- what shipped vs the evidence vs what's left → `=== "What shipped"` **content tabs**
- a list of MRs → a **compact table**, not prose bullets with inline links

Daily pages today use **zero** code fences, mermaid diagrams or content tabs, while the
tutorials use 647 / 187 / 178 — the tools that make the tutorials readable are missing from
the family that needs them most. Reach for them.

Pages under `docs/daily/` dated on or before **2026-07-17** are a frozen historical record:
the gate baselines them and they are never rewritten.
