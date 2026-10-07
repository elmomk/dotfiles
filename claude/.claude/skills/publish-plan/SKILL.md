---
name: publish-plan
description: "PUBLISH an already-decided plan into the shared teach-me library, under its own Plans nav section grouped by area subcategory. Same site/server as /teach-me, /daily and /reminder. One page per plan (stages, gates, hazards, verification, rollback, human checkpoints); the index is a rollup with each plan's status, next action and what it's blocked on. Pages are LIVE: re-running rewrites from current reality rather than appending. This skill does NOT decide the plan — that is plan mode's job; use it once a plan exists and the team needs to read it. Triggers: /publish-plan, publish the plan, put the plan on the site, publish the rollout plan, share the plan with the team, update the published plan, supersede the published plan."
argument-hint: "[<plan to publish> | update <slug> | supersede <slug> by <new-slug> | list]"
---

# Publish plan

> **Not plan mode.** `/plan` (and Shift+Tab) is Claude Code's built-in planning mode — it
> *decides* a plan and drafts it to `~/.claude/plans/`. This skill *publishes* one that has
> already been decided, so humans other than the model can read it. Don't fire it just
> because the user says "plan"; fire it when they want the plan **on the site**.

> **Write the output normally — caveman does not apply here.** The plan page is read by
> other people. Full sentences, articles and connectives intact, whatever length the
> content needs. Caveman/compressed modes govern chat replies, not artifacts: if one is
> active, keep it for the conversation around the work and write the page itself in
> normal prose.

Publish a **plan** to the shared library's **Plans** section — one page per plan under
`~/teach-me/library/docs/plans/`, grouped in the nav by **area subcategory** (`IDP`,
`Scrum suite`, …), sibling of Tutorials/Daily/Reminders. `index.md` is a rollup only.
Serve on 8042 and publish to the SIT hub exactly like `/daily`.

A plan is not a to-do list (`/reminder`) and not a teaching doc (`/teach-me`). It answers:
**what order, why that order, what gates each step, what bites, and what "done" means.**

Four verbs:

- **write** (default) — author or rewrite a plan page from the current state of the world.
- **update `<slug>`** — same, but you already know which plan; refresh it against live state.
- **supersede `<slug>` by `<new-slug>`** — stamp the old plan and point it at the new one.
- **list** — print each plan's status / next action / blocked-on in chat (no rebuild).

## Step 0 — ensure the library + Plans section

```bash
for d in ~/.claude/skills/teach-me ~/work/git/configs/.agents/skills/teach-me; do
  [ -f "$d/scripts/ensure_library.sh" ] && TM="$d" && break
done
[ -n "$TM" ] && bash "$TM/scripts/ensure_library.sh" || echo "install the teach-me skill first"
python3 ~/.claude/skills/publish-plan/scripts/ensure_plans.py            # index + nav section (idempotent)
```

Keep `$TM` — its `serve_library.sh` / `publish_sit.sh` / `open_site.sh` are reused below.

## Step 1 — place it

`ls ~/teach-me/library/docs/plans/` first. A **subcategory** is an area, not a project
("IDP", "Scrum suite", "Dotfiles") — reuse one; create sparingly. A **plan** is one
deliverable's route to done.

```bash
python3 ~/.claude/skills/publish-plan/scripts/ensure_plans.py cat  <cat-slug> "<Area>"
python3 ~/.claude/skills/publish-plan/scripts/ensure_plans.py plan <cat-slug> <plan-slug> "<Title>"
```

Both idempotent; nav rows/cats stay alphabetical. The cat must exist before the plan
(the script refuses rather than orphaning a page).

## Step 2 — verify before you write

**A plan asserting stale state is worse than no plan** — it gets trusted. Before writing,
check the claims you're about to make, and cite what you checked:

- MRs: state, `detailed_merge_status`, **`approvals` → `approved_by`** (open ≠ approved),
  **`reviewers`** (a blocker with no reviewer is in nobody's queue), head pipeline.
- Pipelines/jobs: real status. `manual` usually means *parked at a gate*, not failed.
- Cluster/live state where the plan depends on it — prefer one read over an assumption.
- Repo: does the file/flag/annotation the plan assumes still exist?

Put the numbers in the plan. "10 of 72 live Stacks false-reject" outranks "some may fail".

## Step 3 — author the page

Body goes inside `<!-- plan:start -->` … `<!-- plan:end -->`. Keep the header table
(`Status` · `Updated` · `Next action` · `Blocked on`) truthful — it feeds the rollup.

Sections, in this order (drop what doesn't apply — don't pad):

```markdown
## What changed vs the last plan   ← only when superseding; table, why each change
## Live state                      ← table: artifact | state | blocker. Dated.
## Stage graph                     ← fenced ASCII; show what runs in PARALLEL
                                     and mark the invariants ("X before Y — else …")
## Stage N — <name>                ← checklist; each step names its gate + job id
## Hazards & mitigations           ← table: hazard (with EVIDENCE) | mitigation
## Verification                    ← per stage, what "done" means — falsifiable
## Rollback                        ← per repo
## Human checkpoints               ← what is NOT self-servable, and whose it is
```

Writing rules:

- **Order is the product.** Every stage says what gates it and why it can't move earlier.
- **Hazards need evidence, not vibes.** Name the thing, the measurement, the blast radius.
  A hazard nobody can check is decoration.
- **Distinguish "blocked on a human" from "blocked on a machine".** Approvals, prod
  clicks and sign-offs are their own list — they don't shorten by working harder.
- **Falsifiable verification.** "bool defaults come back 21/21, today 0/21" — not "verify
  it works".
- Hyperlink every MR/pipeline/job/ticket (`[proj!N](url)`) — same rule as `/daily`.
- Say what is NOT covered. A plan silently omitting a stage reads as "handled".
- **Rewrite, don't append.** Plans are living; stale bullets are the failure mode.

For **supersede**: put `> **SUPERSEDED <date>** by [<Title>](<new-slug>.md) — <one-line why>`
as the new first line under the H1 of the old page, set its `Status` to `Superseded`, and
leave the body (the reasoning stays useful). Never delete a plan.

Then refresh the rollups:

- the plan page's TL;DR — one line: what it gets you + where it stands;
- the index `## Plans` list (inside `<!-- plans:start/end -->`, grouped by subcategory,
  same order as the nav):
  `- **[<Title>](<slug>.md)** — <Status> · next: <next action> · blocked on: <who>`;
- the index TL;DR: `N active — nearest gate: **<the thing everything waits on>**`.

## Step 4 — build · serve · publish · open

Stamp the page first — a plan asserting stale state gets trusted, so the reader must be able
to see its age. The `Updated` row carries the date; the stamp carries the hour and the offset
(this library is published to a shared hub, so a bare time is ambiguous). Idempotent.

```bash
python3 "$TM/scripts/stamp.py" ~/teach-me/library/docs/plans/<plan-slug>.md
cd ~/teach-me/library
python3 tools/lint_readability.py                       # readability gate — exit 1 = fix it
uv run zensical build                                   # fix until clean
bash "$TM/scripts/serve_library.sh" 8042                # no-ops if already up
bash "$TM/scripts/publish_sit.sh"                       # ALWAYS run_in_background: true — see below
bash "$TM/scripts/open_site.sh" 8042 plans/<plan-slug>/
```

A plan is dense by nature — that is fine, and the gate allows it. What it won't allow is a
**wall**: a >250-word paragraph, >10% of prose words bolded (plans were the worst family on
the site at **22.9%** — bold that frequent stops meaning anything), or raw Unicode emoji
instead of `:material-*:`. Reshape rather than trim: stage order is a graph, live state is a
table, hazards are a table, the long rationale goes in a `??? note` collapsible.

### The SIT publish is fire-and-forget — always

`publish_sit.sh` builds an image, pushes it to GAR and rolls out a Deployment. It takes
minutes and **nothing downstream depends on it**. Run it with `run_in_background: true`,
every time, on the first publish and on every re-publish.

Then keep going in the same turn. Specifically, do **not**:

- wait for its `<task-notification>` before doing the next thing;
- poll it, `Read` its output file, or `tail` its log to "confirm" it;
- treat it as a step that has to finish before you answer, edit the next file, or move to
  the next gate of the work you were actually doing.

It reports its own exit status when it lands. If it failed, say so then — a failed hub
publish costs the team a stale page, not correctness, and the local site on 8042 is already
serving the new build from disk. The only thing that blocks is the readability gate and
`zensical build`; those are fast and you need their results.

The same rule applies when a plan is re-published mid-task: republishing is a side effect of
the work, never the work itself. Fire it and carry on.

Report `http://127.0.0.1:8042/plans/<plan-slug>/` + one line on what changed, and note the
SIT copy is refreshing in the background.

## Notes

- **A plan in `~/.claude/plans/` is invisible to everyone but the model.** That's the point
  of this skill — if a plan is worth following it belongs where the team can read it. When
  a `~/.claude/plans/*.md` already exists, publish from it rather than re-deriving, then
  leave the local file as the scratch copy.
- Keep the slug stable — it's the `update`/`supersede` handle and the published URL.
- If a plan is really one person's to-do, it's a `/reminder`. If it teaches a system rather
  than routing work, it's `/teach-me`.
