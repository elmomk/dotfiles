# AAR (After-Action Review)

> **Write the AAR page in normal prose — caveman/compressed modes do not apply here.** The page
> is read by the team. Full sentences, whatever length the content needs. Blameless throughout:
> name systems and mechanisms, never individuals. (If a compressed mode is active, keep it for
> the chat around the work and write the page itself normally.)

Produce a **blameless After-Action Review** of an incident or near-miss as a page in the shared
teach-me library, under the **AAR** nav section — `~/teach-me/library/docs/aar/<slug>.md` —
written with the teach-me method (gist first, a mechanism diagram, tables over prose, refs
everywhere) and served on the same one site/server as `/teach-me` and `/daily` (port 8042).

An AAR answers five questions, in order: **what happened**, **the mechanism (how)**, **why it
happened (root cause + contributing factors)**, **why it stayed hidden (the detection gap)**,
and **how we prevent a recurrence (action items with owners/tickets)**. It is not a status
update and not a plan — it is a durable, teachable record of one failure and its lessons.

## When to use

- A production incident or degradation just got resolved and the mechanism is worth recording.
- A near-miss, or a surprising bug whose root cause teaches something reusable.
- The user says "AAR", "post-mortem", "write up what went wrong", "retro on the incident",
  "/AAR", or asks how an incident happened and how it could have been prevented.

Not for: routine work recaps (use `/daily`), forward-looking plans (use `/publish-plan`), or
teaching a concept with no incident behind it (use `/teach-me`).

## Gather the facts first

Pin these down before writing; if one is genuinely unknown, **say so** rather than inventing it
— an AAR lives or dies on accuracy:

1. **Impact** — what broke, who felt it, how long, severity, and anything it masked.
2. **Timeline** — introduced → detected → resolved, with dates. Mark unpinned points honestly.
3. **Mechanism** — the causal chain, step by step. This is the heart; draw it as a mermaid
   `flowchart`. Reconstruct it from the code, the fixing MR, and logs — not from memory alone.
4. **Root cause + contributing factors** — the one primary cause, then the factors that let it
   happen or made it worse.
5. **Detection gap** — why it wasn't caught sooner: what looked normal, what signal existed but
   nothing alerted on, and how it was actually found.
6. **Resolution** — the fix, the MR/version, and how it was verified (before/after evidence).
7. **What went well** — an AAR is blameless in both directions; credit what worked.
8. **Prevention** — concrete action items as a table (action · kind · status/owner/ticket),
   splitting already-done from proposed.

Sources: the fixing MR(s) and their diffs (`glab`), service logs before/after (signatures via
`kubectl logs`), git history, claude memory, and the incident's board tickets.

## Structure (the page)

Sections, in order: `## Impact`, `## Timeline`, `## What happened — the mechanism` (with the
mermaid diagram), `## Root cause and contributing factors`, `## Why it stayed hidden`,
`## Resolution`, `## What went well`, `## Prevention — action items`, `## Lessons`. Open with an
`!!! abstract "TL;DR"` gist (≤80 words) and a one-line note that the review is blameless. Prefer
tables for impact/timeline/action items — they scan and they clear the readability gate.

## Blameless

Describe systems and mechanisms, never people. "The cache write was tied to the request
future," not "so-and-so put the cache write in the wrong place." The goal is a record the whole
team can learn from without anyone bracing for blame.

## Publish (same site/server as /teach-me and /daily)

1. Ensure the library exists via teach-me's `ensure_library.sh` (in `~/.claude/skills/teach-me`
   or `~/work/git/configs/.agents/skills/teach-me`); keep `$TM` — its `scripts/` are reused below.
2. Write the page to `~/teach-me/library/docs/aar/<slug>.md`, and add a rollup row to
   `docs/aar/index.md` (create both on first run — the section self-bootstraps).
3. Wire the nav: in `~/teach-me/library/zensical.toml`, add (once) an `{ "AAR" = [ "aar/index.md",
   … ] }` entry with `# >>> aar` / `# <<< aar` markers around the page list (mirror the existing
   `bundles` / `reviews` blocks), then add the new page's `{ "Title" = "aar/<slug>.md" }` line
   between the markers.
4. Stamp: `python3 "$TM/scripts/stamp.py" ~/teach-me/library/docs/aar/<slug>.md --note "AAR"`.
5. Lint + build: `cd ~/teach-me/library && python3 tools/lint_readability.py && uv run zensical
   build` — fix until "No issues found". If the gate flags the page, **reshape, don't trim the
   facts** (threads → a table, narrative → a `??? abstract` collapsible).
6. Serve (one server): `bash "$TM/scripts/serve_library.sh" 8042`.
7. Publish to the SIT hub in the background: run `bash "$TM/scripts/publish_sit.sh"` via the Bash
   tool with `run_in_background: true` — never block the serve/open on it.
8. Open + report: `bash "$TM/scripts/open_site.sh" 8042 aar/<slug>/`, then give the local URL
   `http://127.0.0.1:8042/aar/<slug>/` and the team `http://<gw-ip>/teach-me/aar/<slug>/`
   (publish_sit prints the gateway IP).

## Examples

- `/AAR the schema-svc livelock` — write the incident up from the fixing MR + prod logs.
- `/AAR` — after resolving an incident in-session, use the session's own context as the source.
