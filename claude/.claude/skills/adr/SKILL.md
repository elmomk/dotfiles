---
name: adr
description: "Record an architecture decision as a numbered ADR in the shared teach-me library, under its own Decisions nav section — same site/server as /teach-me, /daily, /buggy and /reminder. One permanent page per decision: context, options weighed, the decision, consequences, and an explicit verified-vs-assumed split. Use whenever a call gets made that a future session would otherwise have to re-derive: 'adr', '/adr', 'record this decision', 'write this up as an ADR', 'why did we choose X', 'decision record', 'document the architecture decision', 'we decided to…'. Also for reversing one — a new ADR supersedes the old, never an edit in place. Triggers: adr, decision record, architecture decision, record this decision, why did we pick, supersede that decision."
argument-hint: "[<the decision>] | status <n> <state> | supersede <n> <slug> \"<Title>\" | list"
---

# ADR

Record **decisions worth not re-deriving** into the shared library's **Decisions**
section — **one numbered page per decision** under `~/teach-me/library/docs/decisions/`,
children of the Decisions nav section (sibling of Bugs/Plans/Reminders). `index.md` holds
only the rollup table, never bodies. Serve on the same port as `/teach-me` (8042) and
publish to the SIT hub like daily does.

The point: the *reasoning* behind a call evaporates when the session ends, and six weeks
later somebody — often you — re-opens the same question with less evidence than you had.
An ADR has to let a cold session act **and** know which claims to re-check, so verified
facts and assumptions are separated on the page rather than blended into prose.

Four verbs:

- **add** (default) — write a new ADR from the conversation.
- **status \<n\> \<state\>** — move an ADR between Proposed / Accepted / Rejected / Deprecated.
- **supersede \<n\> \<slug\> "\<Title\>"** — write a NEW ADR that replaces `<n>`, and cross-link both.
- **list** — print the record in chat, newest first (no rebuild).

## Step 0 — ensure the library + Decisions section exist

```bash
for d in ~/.claude/skills/teach-me ~/work/git/configs/.agents/skills/teach-me; do
  [ -f "$d/scripts/ensure_library.sh" ] && TM="$d" && break
done
[ -n "$TM" ] && bash "$TM/scripts/ensure_library.sh" || echo "install the teach-me skill first"
python3 ~/.claude/skills/adr/scripts/ensure_decisions.py   # index + nav section (idempotent)
```

Keep `$TM` — its `serve_library.sh` / `publish_sit.sh` / `open_site.sh` are reused below.

## Step 1 — scaffold the page (add)

First check you are not re-deciding something already recorded:
`ls ~/teach-me/library/docs/decisions/` and read any ADR that touches the same system.
If one does and the new call **reverses** it, use `supersede` instead of `add`.

```bash
python3 ~/.claude/skills/adr/scripts/ensure_decisions.py new <slug> "<Title>" <YYYY-MM-DD>
```

Allocates the next number, scaffolds `docs/decisions/NNNN-<slug>.md`, adds the nav row in
numeric order. Numbers are **never reused**, even for a rejected or deleted ADR.

Title states the decision, not the problem — "Two independent Alloy consumer groups on
MiddleServiceLog", not "How should we consume Kafka". Someone scanning the nav should be
able to tell what was decided without opening the page.

## Step 2 — author it

Fill the header table, then the sections inside `<!-- adr:start -->` … `<!-- adr:end -->`:

```markdown
## Context

What forced the decision. The constraint, the measurement, the incident, the ask. Quote
the decisive number or line verbatim. A reader who disagrees with the decision should be
able to point at the sentence in here they disagree with.

## Decision

What we will do, in the imperative. Concrete enough to build against — name the
components, fields, values.

## Options considered

| Option | Why not |
| --- | --- |
| <the one not taken> | <the specific thing that rules it out> |

The chosen one gets a row too, with why it wins. An ADR with one option is a note, not a
decision record.

## Consequences

What this makes true — good and bad, both. Include what it costs, what it forecloses,
and what now has to be operated that didn't before.

## Verified vs assumed

| Claim | Standing |
| --- | --- |
| <fact> | :material-check-decagram: Verified — <how> |
| <belief> | :material-help-circle-outline: Assumed — <what would settle it> |

## Revisit if

- <the condition that would make this the wrong call>
```

Writing rules (house style, same spirit as daily/buggy/reminder):

- **The verified-vs-assumed table is the point of the page.** Anything not actually
  observed goes in the assumed row with the check that would settle it. A cold session
  reads that table first to know what to re-verify before acting.
- **Evidence is quoted verbatim, shortest decisive form.** A paraphrase is not evidence.
- Status icons are `:material-*:` shortcodes, **never raw Unicode emoji** — the library's
  `tools/lint_readability.py` gate rejects raw emoji. Use
  `:material-lightbulb-outline:` Proposed, `:material-check-decagram:` Accepted,
  `:material-file-replace-outline:` Superseded, `:material-close-circle-outline:` Rejected,
  `:material-archive-outline:` Deprecated.
- Two more gate rules bite this page shape specifically, so write for them rather than
  fixing afterwards: **bold ≤10% of prose words** (an ADR tempts you to bold every claim —
  promote the recurring ones to `###` headings instead, and let the status icon carry the
  emphasis in the verified-vs-assumed table), and **table cells ≤25 words** (the index
  rollup's one-line summary is the usual offender; the depth belongs on the ADR page).
- **Proposed vs Accepted is honest, not aspirational.** If the shape is agreed but it is
  gated on a measurement, a partition count or another team's sign-off, it is Proposed,
  and *what would accept it* goes in **Revisit if**.
- Hyperlink every reference — MRs `[proj!N](url)`, board items, other ADRs
  (`[ADR-0003](0003-slug.md)`), source files at `path:line`.
- One decision per ADR. A decision that only makes sense given another gets its own page
  and links to it.
- **Never rewrite an ADR to say something else.** Fixing a typo or adding a link is fine;
  changing the decision is a `supersede`. The reasoning that turned out wrong is the part
  worth keeping.

Then refresh the index rollup inside `<!-- adrs:start/end -->` — numeric order, one row each:

```markdown
| [ADR-0001](0001-slug.md) | <Title> | :material-check-decagram: Accepted | 2026-08-06 | <one-line what it decided> |
```

and the index TL;DR: `N decisions — a accepted, b proposed, c superseded`.

For **status \<n\> \<state\>**: edit that ADR's Status row and the index row, nothing else.

For **supersede \<n\>**: scaffold the new ADR, set its **Supersedes** to `[ADR-<n>](…)`,
set the old one's Status to `:material-file-replace-outline: Superseded` and its
**Superseded by** to the new one, and update both index rows. The old page keeps its body.

## Step 3 — mirror it into the code repo

The library page is the readable, shared, cross-repo record. A decision that **constrains
how code in a repo gets written** also belongs *in that repo*, where a reviewer meets it
in an MR and a cold `grep` finds it without knowing the library exists. A decision about
process, scheduling or people is library-only — skip this step.

**Find the repo's existing convention before writing anything.** Never introduce a new
directory or a new header format alongside one that exists:

```bash
git -C <repo> ls-tree -r --name-only origin/master \
  | grep -iE '(^|/)(adr|adrs|decisions?|rfcs?)/' | head
```

- **One directory** → use it, and copy its header format from the newest file in it.
- **More than one** (it happens — `adr/` and `docs/adr/` both exist in configs, both
  numbered `0001`) → pick the one whose newest file has the **most recent commit**, say
  in your report which you picked and that the repo has a collision, and do **not** create
  a third. Consolidating them is separate work with its own MR.
- **None** → `docs/adr/`, house format from Step 2.

Numbering is **per repo**, from that repo's own sequence — it will not match the library's
number, and that is fine. Cross-link instead:

- repo ADR header gains a row pointing at the library page;
- library page's **Tracking** row gains the repo path and, once open, the MR.

Land it as its **own docs-only branch and MR**, off `origin/master`, in a worktree —
never folded into an unrelated feature branch, even the one the decision is about. The
feature MR cites the ADR; it does not carry it, because the decision outlives that branch
and often has to merge first.

```bash
worktree <repo> docs/adr-<slug>      # the user's zsh worktree function
# write the file, then:
git -C <worktree> add docs/adr/NNNN-<slug>.md
git -C <worktree> commit -m "docs(adr): <title in imperative>"
```

**Stop there and report the path.** Pushing the branch and opening the MR is an
outward-facing action — confirm with the user first.

## Step 4 — build · serve · publish · open

```bash
cd ~/teach-me/library && uv run zensical build                      # fix until clean
python3 tools/lint_readability.py docs/decisions/*.md               # gate — fix, never baseline
bash "$TM/scripts/serve_library.sh" 8042                            # no-ops if already up
```

A clean `zensical build` does **not** mean the page passes — the readability gate is a
separate run, and it is the one that catches over-bolding and fat table cells.

Publish to the SIT hub in the background (never block): run
`bash "$TM/scripts/publish_sit.sh"` via Bash with `run_in_background: true`.

```bash
bash "$TM/scripts/open_site.sh" 8042 decisions/<NNNN-slug>/
```

Report the URL `http://127.0.0.1:8042/decisions/<NNNN-slug>/`, the number and title, and
note the SIT copy is refreshing in the background.

## Examples

- `/adr` after a design conversation → records the call, the options weighed, and which
  facts were measured versus assumed.
- `/adr we consume MiddleServiceLog with two consumer groups, not one fan-out` — writes
  it up with the backpressure reasoning that forced it.
- `/adr status 3 accepted` — the partition count came back, the gate cleared.
- `/adr supersede 1 alloy-single-consumer "Collapse back to one Alloy consumer"` — new
  ADR replaces ADR-0001, both cross-linked, ADR-0001 kept readable.
- `/adr list` — prints the record in chat, newest first.
