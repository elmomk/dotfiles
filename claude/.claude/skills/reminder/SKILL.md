---
name: reminder
description: "Persist a reminder of work that still needs to happen into the shared teach-me library, under its own Reminders nav section — same site/server as /teach-me and /daily. Reminders are grouped by topic, one subpage per topic (index is just the rollup); each call adds a dated entry (what's left, context, first step, refs); 'done' moves an entry to its page's Done list. Triggers: reminder, remind me, note for later, park this, todo for later, /reminder."
argument-hint: "[<what still needs to happen>] | done <slug> | list"
---

# Reminder

Add a **reminder of outstanding work** to the shared library's **Reminders** section —
**one page per topic** under `~/teach-me/library/docs/reminders/`, children of the
Reminders nav section (sibling of Tutorials/Daily). `index.md` holds only the rollup
(TL;DR + topic list), never entries. Serve on the same port as `/teach-me` (8042) and
publish to the SIT hub like daily does.

Three verbs:

- **add** (default) — file an entry on the page of the topic it belongs to. Pull the
  substance from the conversation when the args are thin: the point of a reminder is that
  a future session can act on it without this session's context.
- **done <slug>** — move that entry from its topic's Open block to Done (strikethrough,
  stamp the date).
- **list** — print the open entries in chat, grouped by topic (no site rebuild).

## Step 0 — ensure the library + Reminders section exist

```bash
for d in ~/.claude/skills/teach-me ~/work/git/configs/.agents/skills/teach-me; do
  [ -f "$d/scripts/ensure_library.sh" ] && TM="$d" && break
done
[ -n "$TM" ] && bash "$TM/scripts/ensure_library.sh" || echo "install the teach-me skill first"
python3 ~/.claude/skills/reminder/scripts/ensure_reminders.py   # index + nav section (idempotent)
```

Keep `$TM` — its `serve_library.sh` / `publish_sit.sh` / `open_site.sh` are reused below.

## Step 1a — pick the topic (add)

`ls ~/teach-me/library/docs/reminders/` and check the existing pages' titles. A topic is
a project or area ("IDP", "Scrum suite", "Dotfiles"), not a task — **reuse an existing
page whenever the work belongs there**; create new topics sparingly:

```bash
python3 ~/.claude/skills/reminder/scripts/ensure_reminders.py topic <slug> "<Title>"
```

(scaffolds `docs/reminders/<slug>.md` + its nav row, alphabetized, idempotent; title
short, no quotes in it).

## Step 1b — author the entry (add)

Append (newest first) inside the `<!-- reminders:start -->` … `<!-- reminders:end -->`
block of the **topic's page**:

```markdown
## <YYYY-MM-DD> · <short imperative title> { #<kebab-slug> }

**Still to do** — 2–4 sentences: exactly what work remains and why it matters.

**Context** — what a cold session needs to know (state of the world, what was already tried
or decided), with hyperlinks to every referenced MR/pipeline/repo/ticket/artifact.

**First step** — the concrete next action to start with.
```

Writing rules (house style, same spirit as daily):

- Title is the WORK, not the event ("Make scrum branch CI green", not "CI failed").
- The slug is stable — it's the `done` handle; kebab-case, ≤5 words, unique across ALL
  topic pages.
- Hyperlink every reference (MRs `[proj!N](url)`, pipelines, board items — see the daily
  skill's hyperlink rule; board links via `python3 ~/.claude/skills/daily/scripts/board_links.py`).
- Reminders are for CROSS-SESSION work. Don't file things finishing this session.
- If an equivalent entry already exists (grep the slug/topic across `docs/reminders/*.md`),
  update it in place instead of duplicating.

Then refresh the rollups:

- the topic page's TL;DR: `N open — newest: **<title>**` (or "No open reminders 🎉");
- the index `## Topics` list (inside `<!-- topics:start/end -->`, alphabetical, same
  order as the nav): `- **[<Title>](<slug>.md)** — N open · newest: [<entry title>](<slug>.md#<entry-slug>)`
  (a topic with nothing open: `— none open · N done`);
- the index TL;DR: `N open — newest: **[<entry title>](<topic>.md#<entry-slug>)** (<Topic>)`
  (or "No open reminders 🎉").

For **done <slug>**: find the page (`grep -l '{ #<slug> }' ~/teach-me/library/docs/reminders/*.md`),
cut the entry from its Open block, retitle `## ~~…~~ ✅ done <date>`, append it under that
page's `<!-- done:start -->` block (keep its body), and refresh the same rollups.

## Step 2 — build · serve · publish · open

```bash
cd ~/teach-me/library && uv run zensical build          # fix until clean
bash "$TM/scripts/serve_library.sh" 8042                # no-ops if already up
```

Publish to the SIT hub in the background (never block): run
`bash "$TM/scripts/publish_sit.sh"` via Bash with `run_in_background: true`.

```bash
bash "$TM/scripts/open_site.sh" 8042 reminders/<topic-slug>/
```

Report the URL `http://127.0.0.1:8042/reminders/<topic-slug>/` + one line on what was
added/closed, and note the SIT copy is refreshing in the background.

## Examples

- `/reminder` after discussing broken CI → files "Make scrum branch CI green" on the
  **Scrum suite** page with the pipeline links and the chosen fix approach.
- `/reminder rotate the SIT robot token before 08-01` — files it verbatim + context on
  the matching topic page (creating the topic only if none fits).
- `/reminder done make-scrum-branch-ci-green` — moves it to that page's Done list.
- `/reminder list` — prints open entries in chat, grouped by topic.
