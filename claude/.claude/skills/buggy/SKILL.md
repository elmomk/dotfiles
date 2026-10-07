---
name: buggy
description: "Write up bugs and defects found during investigation into the shared teach-me library, under its own Bugs nav section — same site/server as /teach-me, /daily and /reminder. Bugs are grouped by system, one page per system; each entry carries symptom, decisive evidence, root cause, blast radius and fix. Use whenever an investigation turns up defects worth keeping: 'file these bugs', 'write these up', 'log this bug', 'buggy', '/buggy', 'record what we found', 'put these issues on the site', or after any debugging session that surfaced problems nobody is tracking. Triggers: buggy, file a bug, log this bug, write up these issues, bug report, record these findings, known issues."
argument-hint: "[<what's broken>] | fixed <slug> | list"
---

# Buggy

File **defects worth keeping** into the shared library's **Bugs** section — **one page
per system** under `~/teach-me/library/docs/bugs/`, children of the Bugs nav section
(sibling of Plans/Reminders). `index.md` holds only the rollup (TL;DR + severity counts
+ system list), never entries. Serve on the same port as `/teach-me` (8042) and publish
to the SIT hub like daily does.

The point: bugs found while chasing something else normally die with the session. An
entry here has to let a cold session act — so evidence is quoted, not summarized.

Three verbs:

- **add** (default) — file each bug on the page of the system it belongs to. Pull the
  substance from the conversation when the args are thin.
- **fixed <slug>** — move that entry from its system's Open block to Fixed (strikethrough,
  stamp the date, keep the body).
- **list** — print open bugs in chat, grouped by system, severity-ordered (no rebuild).

## Step 0 — ensure the library + Bugs section exist

```bash
for d in ~/.claude/skills/teach-me ~/work/git/configs/.agents/skills/teach-me; do
  [ -f "$d/scripts/ensure_library.sh" ] && TM="$d" && break
done
[ -n "$TM" ] && bash "$TM/scripts/ensure_library.sh" || echo "install the teach-me skill first"
python3 ~/.claude/skills/buggy/scripts/ensure_bugs.py   # index + nav section (idempotent)
```

Keep `$TM` — its `serve_library.sh` / `publish_sit.sh` / `open_site.sh` are reused below.

## Step 1a — pick the system (add)

`ls ~/teach-me/library/docs/bugs/` and check existing pages' titles. A system is the
thing that's broken — a service, controller, repo or pipeline (`litellm-proxy`,
`figma-mcp`, `selfservice`) — **reuse an existing page whenever the bug belongs there**:

```bash
python3 ~/.claude/skills/buggy/scripts/ensure_bugs.py system <slug> "<Title>"
```

(scaffolds `docs/bugs/<slug>.md` + its nav row, alphabetized, idempotent; title short,
no quotes in it).

## Step 1b — author the entry (add)

Append (highest severity first, then newest first) inside the `<!-- bugs:start -->` …
`<!-- bugs:end -->` block of the **system's page**:

```markdown
## <severity icon> <short symptom title> { #<kebab-slug> }

| Field | Value |
| --- | --- |
| **Severity** | :material-fire: P1 · breaks work now |
| **Status** | Open |
| **Found** | <YYYY-MM-DD> |
| **Verified** | Live — <how, in a few words> |

**Symptom** — what you observe from outside, 1–2 sentences.

**Evidence**

​```
<the shortest decisive line, verbatim>
​```

**Mechanism** — why it happens. Name the code path, config key or process.

**Impact** — who or what is affected, and how often. Numbers if you have them.

**Fix** — the concrete change, with the file path or config key it lands in.
```

Writing rules (house style, same spirit as daily/reminder):

- Title is the SYMPTOM, not the fix ("Fallback target shares the failing quota domain",
  not "Change the fallback list").
- **Evidence is quoted verbatim, and it is the shortest line that proves the claim.** A
  paraphrase is not evidence. If nothing was actually observed, say so in **Verified**
  and downgrade the language — `suspected`, not `is`.
- **Verified** distinguishes what you saw from what you inferred: `Live — /proc read`,
  `Log — 20 occurrences`, `Config — read from the ConfigMap`, `Inferred — not reproduced`.
  A cold session needs to know which claims to re-check before acting.
- Severity is about consequence, not effort: :material-fire: P1 breaks work now or fails silently
  where nothing catches it; :material-alert: P2 is silently wrong or degraded; :material-information-outline: P3 is noise, latent
  risk or wasted effort with no user impact today.
- **Severity is written as a `:material-*:` shortcode, never a raw Unicode emoji** — the
  library's `tools/lint_readability.py` gate rejects raw emoji (they render font-dependently;
  shortcodes are SVG). Use `:material-fire:` / `:material-alert:` /
  `:material-information-outline:`, and `:material-check-circle:` for fixed.
- The slug is stable — it's the `fixed` handle; kebab-case, ≤5 words, unique across ALL
  system pages.
- Hyperlink every reference (MRs `[proj!N](url)`, pipelines, runbooks, board items — see
  the daily skill's hyperlink rule).
- One bug per entry. A symptom that's downstream of another bug gets its own entry that
  links to the cause, rather than being folded in — they get fixed and closed separately.
- If an equivalent entry exists (grep the slug across `docs/bugs/*.md`), update it in
  place instead of duplicating.

Then refresh the rollups:

- the system page's TL;DR: `N open — <counts by severity>, worst: **<title>**`
  (or "No open bugs");
- the index `## Systems` list (inside `<!-- systems:start/end -->`, alphabetical, same
  order as the nav):
  `- **[<Title>](<slug>.md)** — N open (:material-fire: a · :material-alert: b · :material-information-outline: c) · worst: [<entry title>](<slug>.md#<entry-slug>)`
  (a system with nothing open: `— none open · N fixed`);
- the index TL;DR: `N open across M systems — <total counts by severity>`
  (or "No open bugs").

For **fixed <slug>**: find the page (`grep -l '{ #<slug> }' ~/teach-me/library/docs/bugs/*.md`),
cut the entry from its Open block, retitle `## ~~…~~ :material-check-circle: fixed <date>`, set the Status row
to `Fixed <date>`, append it under that page's `<!-- fixed:start -->` block (keep the
body — the evidence is the value), and refresh the same rollups.

## Step 2 — build · serve · publish · open

```bash
cd ~/teach-me/library && uv run zensical build          # fix until clean
bash "$TM/scripts/serve_library.sh" 8042                # no-ops if already up
```

Publish to the SIT hub in the background (never block): run
`bash "$TM/scripts/publish_sit.sh"` via Bash with `run_in_background: true`.

```bash
bash "$TM/scripts/open_site.sh" 8042 bugs/<system-slug>/
```

Report the URL `http://127.0.0.1:8042/bugs/<system-slug>/` + one line per bug filed, and
note the SIT copy is refreshing in the background.

## Examples

- `/buggy` after a debugging session → files every defect surfaced, grouped onto the
  system pages they belong to, with the log lines that proved each one.
- `/buggy the retry_delay key is silently ignored by the litellm router` — files it on
  the litellm-proxy page with the warning line as evidence.
- `/buggy fixed supergateway-leaks-child-per-session` — moves it to that page's Fixed list.
- `/buggy list` — prints open bugs in chat, grouped by system, worst first.
