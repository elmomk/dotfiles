# WIP

> **Not `/publish-plan`.** A plan is the **route** — stage order, gates, hazards, rollback —
> and it outlives the work. A WIP page is the **resume point**: where the work actually
> stopped, the exact commands to pick it back up cold, and what was left in a temporary
> state. Plans are rewritten as reality moves; WIP pages are **deleted when the work lands**.
>
> If you find yourself writing stage order and rationale, that belongs in a plan. If you
> find yourself writing "run this, then check that, and don't forget the push rule is still
> off" — that's WIP.

> **Write the page normally — caveman does not apply here.** The page is read by other
> people, and by you in three weeks with no memory of today. Full sentences. Caveman and
> other compressed modes govern chat replies, not artifacts.

> **Write the page in a background agent, not in the foreground.** Page-writing is a long
> run of edits plus stamp/lint/build/serve/publish, and inline it floods the transcript and
> interrupts whatever the user is actually doing. Do the investigation and report the
> findings in chat; then hand the writing off. See **Delegation** below — this is the
> default for every verb except `list`.

Publish an in-flight work stream to the library's **WIP** section — one page per stream
under `~/teach-me/library/docs/wip/`, flat (no subcategories), sibling of Plans. Serve on
8042 and publish to the SIT hub exactly like `/daily`.

Four verbs:

- **write** (default) — create or refresh the WIP page for the work in hand.
- **update `<slug>`** — refresh a known page against live state.
- **done `<slug>`** — the work landed: delete the page, drop its nav row, remove its
  rollup line. Do **not** leave finished WIP around; that's what Plans and Daily are for.
- **list** — print each page's Status / Resume-here / Waiting-on in chat (no rebuild).

## Delegation — run the write in the background

`write`, `update` and `done` all end in the same long tail: many edits, then stamp, lint,
build, serve and publish. That belongs in a background agent. `list` is a single cheap read —
run it inline.

**Split the work this way:**

1. **Foreground — establish the facts.** Verify live state yourself (step 1 below) and report
   what you found in chat. This is the part the user wants to see and react to.
2. **Background — write the page.** Spawn an **Agent** with `run_in_background: true` and
   `subagent_type: general-purpose`, then carry on. Report the URL when it lands.

**The delegation prompt must carry the facts, not the task of finding them.** A subagent that
re-derives state will re-run every check, take three times as long, and can reach a *different*
answer than the one you just reported — which is worse than not delegating at all. So write
into the prompt:

- every verified value, verbatim: SHAs, MR states, approvals, measurements, timestamps;
- an explicit "do NOT re-verify these — record them" instruction;
- exactly which files and which sections to touch, and which to leave alone (naming the
  marker blocks it must not enter, e.g. `lhf`, `recap`, `cartoon`);
- "write in normal prose, not the active compressed chat style";
- the environment traps it will otherwise hit — the `/usr/bin` PATH strip in worktree shells,
  the transient `dial tcp … i/o timeout` on gitlab.com that must be retried serially rather
  than diagnosed, and the rule never to export `GITLAB_TOKEN` for gitlab.com calls;
- "report back only: files changed, gate/build result, published URL".

**Never run two page-writers at once on the same library.** They will race on `zensical build`
and on the nav files. If an agent is already writing, continue it with **SendMessage** rather
than spawning a second one.

## The one rule that matters

**Everything a reader needs to act must be copy-pasteable in a single click.** The library
renders a copy button on every fenced block, so:

- Every command goes in its **own fenced block**, and is **self-contained** — absolute
  paths, required `export`s inline, no `cd` assumed, no `$` prompt prefixes (they get
  copied too and break the paste).
- Never write "run the mirror script" — write the invocation.
- Context that a human will paste elsewhere (a fresh session, an MR comment, a ticket)
  goes in a ```text fence, not in prose. Prose can't be copied cleanly.
- Leave **no placeholders** inside a paste block. `<your-token>` is fine; `TODO` and
  `...` are not — a block that can't be pasted as-is has failed at its only job.

## Step 0 — ensure the library + WIP section

```bash
for d in ~/.claude/skills/teach-me ~/work/git/configs/.agents/skills/teach-me; do
  [ -f "$d/scripts/ensure_library.sh" ] && TM="$d" && break
done
[ -n "$TM" ] && bash "$TM/scripts/ensure_library.sh" || echo "install the teach-me skill first"
python3 ~/.claude/skills/wip/scripts/ensure_wip.py            # index + nav section (idempotent)
python3 ~/.claude/skills/wip/scripts/ensure_wip.py page <slug> "<Title>"
```

Keep `$TM` — its `serve_library.sh` / `publish_sit.sh` / `open_site.sh` are reused below.

## Step 1 — verify before you write

A WIP page whose "resume here" command is stale is worse than no page: it will be pasted
blind. Before writing, actually check:

- Does the script at that path still exist? `ls` it.
- Do the MR/pipeline/job states you're about to assert still hold? Read them live.
- Is the thing you left in a temporary state **still** in that state? A push rule you
  cleared may have been restored by someone else.
- Scripts written into a session scratchpad (`/tmp/claude-*/…`) are **session-scoped and
  will vanish**. Copy them somewhere durable and reference the durable path. Never
  publish a `/tmp` path as a resume command.

## Step 2 — write the page

Body goes inside `<!-- wip:start -->` … `<!-- wip:end -->`. Keep the header table
(`Status` · `Updated` · `Resume here` · `Waiting on`) truthful — it feeds the rollup.

Sections, in this order (drop what doesn't apply — don't pad):

```markdown
## Resume in one paste     ← a ```text block: what the work is, where it stopped,
                             what is VERIFIED vs assumed, the next concrete step.
                             Written to be pasted into a cold session verbatim.
## State right now         ← table: piece | state | evidence. Done vs half-done.
## Run this next           ← ordered steps, each its own self-contained fenced block
## Scripts                 ← durable paths, one line each on what it does + its guards
## Left in a temporary state ← what a human must put back. "Nothing" is a valid answer.
## Traps                   ← the env gotchas needed to run the commands at all
## Ready-to-paste comments ← MR/ticket text in ```text fences, inside ??? collapsibles
## Done means              ← falsifiable exit criteria; when they hold, delete the page
```

Writing rules:

- **Separate verified from assumed, every time.** "Verified 2026-07-21 by X" or "assumed,
  not checked". A WIP page is where someone resumes without re-deriving, so an
  unmarked assumption gets inherited as fact.
- **Say why something is parked**, not just that it is. "Blocked on the configs migration"
  is actionable; "blocked" is not.
- **Temporary state is the highest-value section.** Cleared push rules, parked CI,
  disabled runners, open worktrees, running background agents, half-rotated secrets.
  This is what actually bites, and it's invisible from the code.
- **Traps earn their place.** Only list what's needed to run the commands on this page
  (a PATH strip, a CLI that picks the wrong host, an env var that must be set).
- Hyperlink every MR/pipeline/job/ticket — same rule as `/daily`.

Then refresh the rollups:

- the page's TL;DR — one line: what's half-done + the command that resumes it;
- the index `## In flight` list (inside `<!-- wip:start/end -->`):
  `- **[<Title>](<slug>.md)** — <Status> · resume: <one-line> · waiting on: <who>`;
- the index TL;DR: `N in flight — nearest resume: **<the next command>**`.

## Step 3 — build · serve · publish · open

```bash
python3 "$TM/scripts/stamp.py" ~/teach-me/library/docs/wip/<slug>.md
cd ~/teach-me/library
python3 tools/lint_readability.py                       # readability gate — exit 1 = fix it
uv run zensical build                                   # fix until clean
bash "$TM/scripts/serve_library.sh" 8042                # no-ops if already up
```

The readability gate rejects >250-word paragraphs, >10% bolded prose words, raw Unicode
emoji (use `:material-*:`) and an over-long TL;DR lede. Fenced blocks are exempt, so a
long paste block is fine — reshape *prose* into tables and collapsibles rather than
trimming the copy-paste content.

Publish to the SIT hub in the background (never block): `bash "$TM/scripts/publish_sit.sh"`
via Bash with `run_in_background: true`.

```bash
bash "$TM/scripts/open_site.sh" 8042 wip/<slug>/
```

Report `http://127.0.0.1:8042/wip/<slug>/` + one line on what changed, and note the SIT
copy is refreshing in the background.

## Notes

- **Delete aggressively.** The value of this section is that everything in it is live. A
  finished WIP page that lingers turns the section into another archive nobody trusts.
  On `done`, remove the page, the nav row and the rollup line in one pass.
- If the thing you're writing has no next command — only a decision to be made — it's a
  `/reminder` or a plan open-question, not WIP.
- Keep the slug stable; it's the `update`/`done` handle and the published URL.
