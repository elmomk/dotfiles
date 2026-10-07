---
name: report
description: "Publish a technical INVESTIGATION as a report in the shared teach-me library, under its own Reports nav section — same site/server as /teach-me, /daily, /buggy, /adr, /publish-plan and /draw-design. Two shapes: a standalone investigation is one page; a PROGRAMME chased down several legs gets a page per leg plus an index that reconciles where they agree and where they contradict each other. Every report carries an explicit verified-vs-assumed split, the beliefs that were overturned and what killed them (retractions are kept, never deleted), and the method including its positive controls. Use whenever a multi-day or multi-agent investigation produces an answer somebody will act on: 'report', '/report', 'write up the investigation', 'publish the findings', 'what did we find', 'turn this into a report', 'publish the programme', 'add a leg'. Triggers: report, investigation report, write up the investigation, publish the findings, findings report, programme report, investigation legs, retractions."
argument-hint: "[<the investigation>] | programme <slug> \"<Title>\" | leg <prog-slug> <leg-slug> \"<Title>\" | status <slug> <state> | rollup | retire <slug> | list"
---

# Report

> **Write the page in normal prose — caveman and other compressed modes do not apply
> here.** The report is read by other people, some of them weeks later with none of your
> context. Full sentences, articles and connectives intact, whatever length the content
> needs. If a compressed mode is active, keep it for the chat around the work and write
> the page itself normally.

Publish an **investigation** into the shared library's **Reports** section, under
`~/teach-me/library/docs/reports/` — sibling of Designs/Decisions/Bugs/Plans. Serve on
port 8042 like `/teach-me` and publish to the SIT hub like `/daily`. `index.md` holds the
rollup only, never a report body — same rule as `/buggy`.

The point: an investigation's *answer* is the cheap half. The expensive half is knowing
which claims were measured, which were assumed, and which were believed for two days and
then killed by a single command. That half evaporates first, and it is the half that
stops the next session re-running the same wrong reasoning.

Two shapes:

- **standalone** — one investigation, one page.
- **programme** — one question chased down several legs at once. An index page for the
  programme plus one page per leg, because the legs share findings and contradict each
  other in places, and only the index can reconcile that: no single leg saw the others'
  evidence.

Not this skill:

- `/aar` — one incident that already happened, reviewed blamelessly. A report investigates
  a question; an AAR reviews an event.
- `/buggy` — defects, listed per system. A report that turns up defects files them there
  and links to them.
- `/adr` — the decision an investigation leads to, numbered and immutable.
- `/publish-plan` — what to do about the answer, in stages.

Verbs: **add** (default), **programme \<slug\>**, **leg \<prog-slug\> \<leg-slug\>**,
**status \<slug\> \<state\>**, **rollup**, **retire \<slug\>**, **list**.

## Step 0 — ensure the library + Reports section exist

```bash
for d in ~/.claude/skills/teach-me ~/work/git/configs/.agents/skills/teach-me; do
  [ -f "$d/scripts/ensure_library.sh" ] && TM="$d" && break
done
[ -n "$TM" ] && bash "$TM/scripts/ensure_library.sh" || echo "install the teach-me skill first"
python3 ~/.claude/skills/report/scripts/ensure_reports.py   # index + nav section (idempotent)
```

Keep `$TM` — its `serve_library.sh` / `publish_sit.sh` / `open_site.sh` are reused below.

## Step 1 — scaffold the right shape

`ls ~/teach-me/library/docs/reports/` first — re-running on an existing slug updates that
report rather than forking a second page about the same question.

```bash
# standalone investigation
python3 ~/.claude/skills/report/scripts/ensure_reports.py report <slug> "<Title>" <YYYY-MM-DD>

# a programme, then one call per leg (the programme must exist first — the script
# refuses rather than orphaning a page no nav row points at)
python3 ~/.claude/skills/report/scripts/ensure_reports.py programme <prog-slug> "<Title>" <YYYY-MM-DD>
python3 ~/.claude/skills/report/scripts/ensure_reports.py leg <prog-slug> <leg-slug> "<Title>" <YYYY-MM-DD>
```

All idempotent. Top-level nav entries sort newest first (each row carries a `# date:`
marker); legs keep the order you add them, because leg order is the narrative you chose.

To take a report or programme out of the library — a superseded investigation, or one folded
into another:

```bash
python3 ~/.claude/skills/report/scripts/ensure_reports.py retire <slug>
```

It removes the nav entry, which is what actually makes a page invisible, and moves the pages
out of `docs/` into `.retired/<slug>-<date>/`, where they stop building and start returning
404 but are still on disk. **Nothing is deleted**: a fold that turns out wrong has to be
recoverable, and `rm` inside a publishing tool is a footgun. It refuses while any page under
`docs/` still links to the slug, so repoint the rollup and any cross-links first — retiring
something still linked leaves a dead link rather than a clean absence.

**Fold, do not re-voice.** When one report absorbs another, move the other's pages verbatim
and change only what would otherwise break: the programme back-link label and any link that
no longer resolves. It is someone else's measured work and it should read as theirs, with
their `Investigators` row intact. Compressing it into your own prose loses the detail that
made it worth keeping and silently takes credit for it.

Title states **what was found**, not what was looked at — "GMP drop is blocked on the
prod WIF audience, not on quota", not "GMP investigation". Someone scanning the nav
should learn the answer without opening the page.

## Step 2 — author it

Body goes inside `<!-- report:start -->` … `<!-- report:end -->` (a programme index uses
`<!-- programme:start/end -->`). Keep the header table truthful — it feeds the rollup.

### The three required sections

These are requirements, not suggestions. A report missing any of them is a status update,
and a status update did not need a permanent page.

**1 · Verified vs assumed, explicitly split.** Every claim says which it is. An unmeasured
thing is named as unmeasured, with the check that would settle it and who could run it.

```markdown
| Claim | Standing | Basis, or what would settle it |
| --- | --- | --- |
| The prod audience is built from `cluster.name` | :material-check-decagram: Verified | Read from the live ConfigMap |
| The same holds on the two AWS clusters | :material-help-circle-outline: Assumed | Same read against those hubs — platform team has access |
```

Never let a verified row carry a claim that is merely *consistent with* what you saw. If
you inferred it, it is assumed, and the row says what the inference rests on.

**2 · What was believed, and what overturned it.** Retractions are kept, not deleted. One
block per retraction — the claim as it was actually believed, what killed it, who held it,
and what is true instead:

```markdown
### :material-close-octagon-outline: <the belief, stated as it was believed>

| Field | Value |
| --- | --- |
| **Believed until** | <YYYY-MM-DD> |
| **Held by** | <the leg, page, agent or source that asserted it> |
| **Standing now** | :material-cancel: Retracted |

**What killed it**

​```
<the shortest decisive line, verbatim>
​```

**What is true instead** — one or two sentences.
```

"Held by" names the leg, page, agent or document that asserted the claim — a person only
when they signed their name to it. The point is letting a reader find every other place
the wrong claim was propagated, not assigning fault.

A page that quietly shows only the final answer throws away the expensive half. If the
investigation produced no retractions, say so explicitly — it is a real and unusual
result, and silence reads as "we did not check".

**3 · Method, including the positive control.** How each thing was measured. An absence is
worth nothing without a control proving the check can see:

```markdown
| Question | How it was measured | Positive control |
| --- | --- | --- |
| Are the probes present at all? | `find … -name 'probe-*.yaml'` | The same find returns the SIT probes at depth 7 |
```

"X is absent" alone is not a finding; it is an untested tool. Every claimed absence owes a
control that returned something you already knew was there. If you never ran one, the row
says **no control** and the claim moves to assumed.

### The rest of the page

- **What we set out to answer** — the question as it was actually asked, and what turns on it.
- **The answer** — what is true, stated so a cold reader can act.
- **Open questions** — what is still unmeasured and who could measure it.

A programme index adds two sections the legs cannot write:

- **Where the legs agree** — findings more than one leg reached independently. Say which
  legs. Two legs quoting one shared source is not agreement, it is one measurement.
- **Where the legs contradict each other** — the contradiction, which leg holds which
  side, and what would resolve it. An index showing no contradictions either had none or
  did not look; say which.

### Writing rules (house style, same spirit as /adr and /buggy)

- **Evidence is quoted verbatim, shortest decisive form.** A paraphrase is not evidence.
- Status and standing icons are `:material-*:` shortcodes, **never raw Unicode emoji** —
  the library's `tools/lint_readability.py` gate rejects raw emoji. Use
  `:material-check-decagram:` verified, `:material-help-circle-outline:` assumed,
  `:material-close-octagon-outline:` overturned, `:material-cancel:` retracted,
  `:material-progress-clock:` in progress, `:material-flask-outline:` method.
- Two gate rules bite this page shape specifically: **bold ≤10% of prose words** (a report
  tempts you to bold every finding — promote the recurring ones to `###` headings and let
  the icons carry emphasis in tables), and **table cells ≤25 words** (a retraction does not
  fit in a cell, which is exactly why retractions are blocks rather than rows).
- Hyperlink every reference — MRs `[proj!N](url)`, pipelines, board items, other reports,
  ADRs, source files at `path:line`.
- **Numbers, not adjectives.** "14 of 339 RootSyncs" outranks "several".
- **Never rewrite a report to say something else.** Correcting a typo or adding a link is
  fine; a changed conclusion is a new retraction block plus a rewritten answer, so the
  page shows the move. Deleting the old claim is the failure mode this section exists for.

Then refresh the rollups:

- the report's TL;DR — the answer in one to three sentences, not what was done. **Write the
  first sentence to stand alone**, because the rollup uses it verbatim;
- the index `## The reports` list — **generated, never hand-edited**:

```bash
python3 ~/.claude/skills/report/scripts/ensure_reports.py rollup
```

  It rebuilds the block from the nav, so a programme another session added while you were
  writing survives, and it reads each row's status, summary and counts from the page itself.
  The counts are the reason it is derived rather than typed: both counts in this section's
  first published rollup were wrong, because a writer transcribed them from a summary
  instead of counting the page.

  It counts `:material-check-decagram: Verified` rows, `:material-help-circle-outline:` rows
  and `### :material-close-octagon-outline:` retraction headings. **So a retraction written
  as a bullet is not counted** — give every retraction its own block, the way the required
  section above specifies, or the page will under-report itself;
- the index TL;DR, which is still yours to write: `N reports — <the one that matters most>`.

For **status \<slug\> \<state\>**: edit that report's Status row and its index line, nothing
else. States: `:material-progress-clock: In progress`, `:material-check-decagram: Concluded`,
`:material-pause-circle-outline: Parked`, `:material-cancel: Superseded`.

## Step 3 — build · gate · serve · publish

Check nobody else is mid-build first. `zensical build` is site-wide, so another writer's
publish can re-bake your page from a half-written source:

```bash
pgrep -af 'zensical|publish_sit' | grep -v "$$" | grep -vE 'claude --settings|zsh -c source'
```

**That pattern matches your own session.** This skill's own text names both binaries, so a
Claude process carrying it in its argv shows up as a hit — filter the `claude` and shell
lines out before concluding anything, or you will wait forever on yourself.

```bash
python3 "$TM/scripts/stamp.py" ~/teach-me/library/docs/reports/<slug>.md   # or <prog>/<leg>.md
cd ~/teach-me/library
python3 tools/lint_readability.py                # gate — exit 1 = fix it, never baseline it
uv run zensical build                            # fix until clean
bash "$TM/scripts/serve_library.sh" 8042         # no-ops if already up
```

A clean `zensical build` does **not** mean the page passes: the readability gate is a
separate run and it is the one that catches over-bolding and fat table cells.

Publish to the SIT hub with `bash "$TM/scripts/publish_sit.sh"` via Bash with
`run_in_background: true` — always. It builds an image, pushes to GAR and rolls a
Deployment; it takes minutes and nothing downstream depends on it. Do not poll it, do not
`tail` its log to confirm it, do not wait for its notification before doing the next thing.
It reports its own exit status when it lands.

## Step 4 — verify by FETCHING, not by reading

This is the step that is usually skipped and it is the only one that proves anything.

**A page missing from the `nav` array is invisible.** Writing the file is not publishing;
`ensure_reports.py` adds the nav entry, and a page hand-added without one renders to disk
and is reachable by nobody.

**Verify by fetching the built page, never by reading the source file.** A patched source
that was never rebuilt looks identical on disk and is invisible to readers. Fetch both:

```bash
curl -s -o /dev/null -w 'local=%{http_code}\n' http://127.0.0.1:8042/reports/<slug>/
curl -s http://<hub-host>/teach-me/reports/<slug>/ | grep -c '<phrase unique to the page>'
```

- **A SIT fetch can return 503 for roughly twelve seconds** while the load balancer
  reprograms after the rollout. **Retry it; do not diagnose it.** A `kubectl rollout status`
  that goes green would let you call this published — it is not published until a fetch
  returns the content.
- **`ping` lies on this box.** ICMP is blocked and HTTP is fine, so an unreachable-looking
  host is usually reachable. Fetch a URL to test reachability, never `ping`.
- **Grep for a phrase from the correction, not from the claim.** A report quotes retracted
  claims verbatim inside the blocks that retract them, so grepping for the old claim
  matches your own quotation of it and "confirms" the wrong version is live. Pick a phrase
  that exists only in the new text.
- **Never hand-edit a shared block — run `rollup`.** "Read the block first, then add to it"
  sounds like the fix and is not, and the reason is worth knowing. On this section's first
  day two sessions published into it seconds apart and one programme vanished from the
  rollup. The obvious diagnosis was that the second writer had not looked. It had: it read
  the index while the rollup was still empty, and the other programme landed between that
  read and its write. **The exposure is the window between reading and writing, which on a
  box running several sessions is routinely long enough, so reading first does not close
  it.** The nav survived the same second because `ensure_reports.py` splits it, inserts one
  entry and leaves the rest untouched — same file, same writer, same moment, scripted insert
  safe and hand edit not. Regenerate the rollup from the nav with `rollup` instead of
  editing it, and the class of loss goes away rather than being discouraged.

- **A verification step is itself a claim, and a negative result needs a positive control
  before you believe it.** Two false alarms came out of publishing this section, and neither
  would have been caught by looking harder. A grep of the built HTML for an icon shortcode
  returned zero, which reads exactly like broken rendering; the same grep against a page live
  for weeks also returned zero, because icons render as `twemoji` spans. A check that new
  pages appeared in the home page's navigation found none of them; the control showed the
  home page carries no deep links at all. A check for a published sentence returned zero
  because the page's source wraps its prose and `grep` is line-based, so the phrase was
  there but never on one line. In every case the check was broken and the page was
  fine, and in both cases the broken check was indistinguishable from a real defect. Before
  reporting that a fetch proves something absent, run the same check against something you
  know is present.

```bash
bash "$TM/scripts/open_site.sh" 8042 reports/<slug>/
```

Report both URLs and what each fetch returned — the status code and the phrase you matched
— plus one line on what the report concluded, and note the SIT copy is refreshing in the
background if the publish had not landed by then.

## Examples

- `/report` after a long investigation → writes it up as one page, with what was measured
  split from what was assumed and every overturned belief kept.
- `/report programme gmp-platform-exit "Leaving GMP: what actually blocks it"` — opens the
  programme index.
- `/report leg gmp-platform-exit rke "RKE leg — the collector estate on RKE"` — adds a leg
  under it.
- `/report status gmp-platform-exit concluded` — moves it out of In progress.
- `/report list` — prints each report's status, answer and retraction count in chat.

## Notes

**The rollup is generated now, and the argument for it is worth keeping.** The nav and the
`index.md` rollup carry the same information, but for the section's first day only the nav was
generated. That asymmetry was measured, not theorised: two sessions published seconds apart,
the nav merged both cleanly because the tool inserts one entry and leaves the rest alone, and
the hand-maintained rollup lost an entry outright.

The first diagnosis — that the second writer had failed to read before writing — was wrong,
and the correction is the interesting part. It *had* read; the other programme landed between
its read and its write. So "read the shared block first" was already satisfied and the entry
was still lost, because the exposure is the window between reading and writing rather than the
reading. Only writing the block from the nav closes it.

The counts settled the second half. A generator has to get the verified, assumed and retracted
numbers from somewhere, which looked like the obstacle and was really the reason: both counts
in the first published rollup were wrong, because a writer transcribed them from a summary
instead of counting the page. Deriving them makes them facts about the page rather than a
writer's memory of it — and the first run of the generator immediately caught a page whose
retractions were written as bullets and were therefore under-counted.

What is still hand-written, deliberately: the index TL;DR, which is a judgement about which
report matters most today, and every page's own prose. Generate what can drift; write what
requires an opinion.
