---
name: teach-me
description: >-
  Explain a concept, system, codebase, decision, or body of work using a structured
  teaching method — diagrams, concrete worked examples, before/after comparisons, and
  why-first prose — delivered either as a rich in-chat answer (small topics) or a
  built-and-served Zensical documentation site (substantial ones). Use this whenever the
  user asks you to explain, teach, document, write up, walk through, break down, or "help
  me understand / explain in more detail" something, or says "teach me", "explain it like
  I'm…", "make docs for", "turn this into a doc/site", "write it up", or "/teach-me" —
  even if they don't name the skill. Prefer this over an ad-hoc prose answer whenever the
  topic has moving parts, a flow, a decision tree, an incident timeline, or a before/after
  worth showing.
---

# teach-me

> **Write the output normally — caveman does not apply here.** The explanation is read by
> other people, and compression is the opposite of teaching. Full sentences, articles and
> connectives intact, whatever length the content needs. Caveman/compressed modes govern
> chat replies, not artifacts: if one is active, keep it for the conversation around the
> work and write the explanation itself in normal prose.

Turn an explanation into something that actually *teaches*. The value isn't the medium —
it's the method: lead with the gist, show the shape with a diagram, ground every concept
before its rules, and prove it with a concrete worked example. This skill encodes that
method and the tooling to deliver it as a documentation site when the topic earns one.

## Decide the tier first

Pick based on how much structure the explanation wants — not on how the user phrased it:

- **In-chat answer** — a single concept, a short function, one gotcha; the explanation
  fits in a couple of sections with maybe one table or ASCII sketch. Don't spin up a
  website to explain a regex.
- **Zensical site** — multiple moving parts, a pipeline/architecture, a decision tree, an
  incident, a before/after, or "document / write up / make docs for X". Anything that
  benefits from several linked pages, real diagrams, and persistence.

When unsure, ask one quick question ("want this as a quick rundown here, or a little doc
site I can keep?") rather than guessing. If the user explicitly says "site"/"docs"/"write
it up", go straight to site mode.

## The teaching method (both tiers)

These are the patterns that make an explanation land. Apply the ones the topic needs —
they're tools, not a checklist to exhaust.

1. **Lead with the gist.** Open with the whole thing in one paragraph before any detail,
   so the reader has a frame to hang everything on. (In a site: an `!!! abstract` callout.)
2. **Progressive disclosure.** Shallow → deep. An overview that links out; each page/section
   goes one concept deep. The reader should be able to stop early and still have learned
   the shape.
3. **Show the shape before the prose.** A diagram of the flow/architecture/timeline up
   front beats three paragraphs describing it. Reach for a flowchart (processes, decision
   trees) or a sequence diagram (timelines, "who did what when").
4. **Ground concepts before rules.** Define what things *are* before explaining how they
   interact. Most confusion is a missing referent — when someone doesn't get a rule, it's
   usually because an input in that rule was never pinned down. Name the nouns first.
5. **Prove it with a concrete worked example.** Walk one real case through with actual
   values, in a trace table, not abstract placeholders. "Given X=1, Y=2 → here's each
   step" teaches what a general statement can't.
6. **Show before/after side by side.** When something changed or there are two ways to do
   it, put them adjacent (content tabs in a site, two labeled blocks in chat) so the
   difference is visible, not described.
7. **Use a decision/truth table for branching logic.** When behavior forks on a condition,
   a table keyed on the discriminating condition is clearer than nested prose.
8. **Explain the why, always.** Every "it does X" gets a "because Y". Smart readers
   remember reasons, not rote steps — and reasons let them generalize past your example.
9. **Be honest about edges.** A short caveats/limitations note builds trust and pre-empts
   the reader's "but what about…".
10. **Close with the mental model.** End with the one-sentence takeaway the reader should
    walk away repeating.

### Applying it in-chat

Use Markdown the terminal renders: headings, tables, fenced code, and **ASCII diagrams**
(mermaid does *not* render in the terminal — save real diagrams for a site). Still lead
with the gist, ground the nouns, and include a worked-example trace table. Keep it tight.

## Site mode — one library, a section per topic

Site tier does **not** spin up a new site (and a new server) per topic. There is **one
Zensical library** at `~/teach-me/library/`, served by **one server** on a fixed port.
Each topic is a section under the **Tutorials** umbrella: a subdirectory
`docs/tutorials/<topic>/` with its own pages, surfaced as a nested nav block (inside the
`Tutorials` section) and a row on the landing page. New explanations *add a section* to the
library. Full mechanics and Markdown-feature syntax (including nested nav) live in
[references/zensical.md](references/zensical.md) — read it before authoring your first
section so you use admonitions, content tabs, and mermaid correctly.

Workflow:

1. **Add the topic.** `bash scripts/add_topic.sh <topic-slug> "Topic Title" "One-line desc"`
   (idempotent). On first use it scaffolds the library with the **house-style `zensical.toml`**
   (locked theme: Inter/JetBrains Mono, light/dark toggle, curated features, mermaid +
   admonitions + tabs — no comment cruft), a landing `docs/index.md`, and the `Tutorials`
   section (`docs/tutorials/index.md`). Every run creates
   `docs/tutorials/<topic-slug>/index.md` from the starter overview. Don't hand-roll the
   config or re-derive the look.
2. **Plan the section.** Sketch the section's pages before writing: an `index.md` overview
   plus one page per concept, in reading order. One idea per page keeps each short.
3. **Author** `docs/tutorials/<topic-slug>/*.md` using the method above (give pages a
   frontmatter `icon:`). Then **wire it in**: nest a nav block for the topic *inside* the
   `Tutorials` section of `zensical.toml`, between the `# >>> tutorials` / `# <<< tutorials`
   markers (pages referenced as `tutorials/<topic-slug>/page.md` — see the reference), and
   add a **card** to the right area group in `docs/tutorials/index.md`.

    !!! danger "Two nav rules that are invisible until they bite"
        **The topic's `index.md` goes in the nav as a bare string** — `"tutorials/<slug>/index.md",`
        — never `{ "Overview" = "tutorials/<slug>/index.md" }`. The bare string makes it the
        section's index page, so the sidebar shows the **topic title**. The `{ "Overview" = … }`
        form labels it "Overview", and with 39 topics the sidebar becomes 39 identical
        "Overview" rows. That happened here and was fixed 2026-07-17.

        **Cards go on `docs/tutorials/index.md`, not the landing page.** `docs/index.md` links
        the eight *areas*; it is not a topic list. It used to be a 39-row table whose
        "one-line summary" cells had grown to **175 words** — 2,390 words on the first page a
        reader meets. Keep a card to **one line**; the depth belongs on the topic's own page,
        which is where the reader who clicked is going anyway.

    A card looks like this (icon = the area's icon; areas come from `.nav-categories.json`):

    ```markdown
    -   :material-cube-outline:{ .lg .middle } __Topic Title__

        ---

        One line. What you'll learn, in a clause.

        [:octicons-arrow-right-24: Read](tutorials/<slug>/index.md)
    ```
   The block is auto-grouped into sidebar categories from
   `docs/tutorials/.nav-categories.json` (slug lists, ordered; the file rsyncs with
   docs/): add the new slug to a category there and run
   `python3 scripts/sync_topics_nav.py --regroup`, or leave it unmapped — ungrouped
   topics stay visible at the top of the section until categorized. Write the topic's
   nav chunk flat; never hand-edit the `# nav-cat` wrapper lines (the script owns them).
4. **Stamp, lint, then build.**

   ```bash
   TM=~/.claude/skills/teach-me                     # this skill's dir — stamp.py lives here
   cd ~/teach-me/library
   python3 "$TM/scripts/stamp.py" docs/tutorials/<topic-slug>/index.md   # every page you rewrote
   python3 tools/lint_readability.py    # readability gate — exit 1 means fix the page
   uv run zensical build                # flags broken links / missing pages
   ```

   Note the `$TM` prefix: after `cd ~/teach-me/library`, a bare `scripts/…` would resolve to
   the *library's* scripts dir, not this skill's. Same convention as `record_gif.sh`.

   The stamp (`<!-- ts:start -->`, idempotent) tells a reader how old the explainer is.
   An explainer that describes a system as it stood in April is not wrong so much as
   *undateable* — and Zensical has no `last-updated` support ([backlog #18](https://github.com/zensical/backlog/issues/18),
   open, no date), so it goes in the content. Re-stamp any page whose content you revised;
   leave the others alone so the date keeps meaning something.

   Fix until both are clean ("No issues found"). The gate enforces the budgets this method
   already implies — ≤250w paragraphs, ≤10% bold in prose, ≤4 links/100w in prose, no raw
   Unicode emoji (use `:material-*:`). It exists because those rules were stated everywhere
   and measured nowhere. `tools/readability-baseline.txt` lists pages that already violated
   when the gate landed: it is a **debt list that only shrinks** — never add a new page to it.
5. **Serve**: `bash scripts/serve_library.sh 8042` — a normal foreground command; the
   server detaches into its own session and survives the Claude session (no
   `run_in_background`). The script **checks first** — if the library server already
   answers on that port it no-ops. It serves `site/` straight from disk with
   `Cache-Control: no-cache`, so whatever step 4 built is exactly what the browser gets
   on its next (re)load — tell the user to refresh any tab they already had open.
   **Run only one server**, and never `pkill` by name pattern — the script replaces a
   stale server by exact PID itself when needed.
6. **Open** `bash scripts/open_site.sh 8042 tutorials/<topic-slug>/` to deep-link straight to
   the new section. Then tell the user the URL and the section's page list.

   Note (headless dev box): port convention — **8042 is this box's live server**; the
   user's browser reaches it through the dev-server SSH helper's `-L 8042` forward. The
   laptop keeps a warm-standby copy of the library on **8043**, refreshed by the laptop
   browser-bridge's *sync-on-view* (rsync `docs/` → merge tutorials nav via
   sync_topics_nav.py → regen daily nav → rebuild) whenever a `:8042` URL passes through
   it. So always open via open_site.sh — the bridge hop keeps the standby fresh. If the
   page won't load, the SSH tunnel is down (this box's `.serve.log` records the user's
   page hits when it's healthy).

7. **Publish to the SIT hub** (background) so teammates can read the same site on the shared
   internal gateway under **`/teach-me/`** (path-based — reachable by the gateway IP, no DNS;
   `publish_sit.sh` prints the exact `http://<gw-ip>/teach-me/`). Don't block the local serve —
   fire it and move on: run `bash scripts/publish_sit.sh` via the Bash tool with
   `run_in_background: true`. It bakes the just-built `site/` into an nginx image, pushes it to
   the registry, applies the idempotent Deployment/Service/HTTPRoute, and rolls the pod (~1–2 min;
   you're notified on completion). Tell the user the SIT copy is refreshing. If it reports a GAR
   `403 uploadArtifacts denied`, the one-time `project_iam` writer grant (a configs MR) isn't
   applied yet — surface that and continue.

### Default section structure

Follow this page arc for a topic unless it clearly wants something else — it mirrors the
reader's path and is the shape good explanations converge on. The scaffolded
`docs/tutorials/<topic>/index.md` already sets up the overview; create the rest as needed:

| Page (under `docs/tutorials/<topic>/`) | Role |
| --- | --- |
| `index.md` | **Section overview** — the one-paragraph gist, a "big picture" diagram, a table of what the section's pages cover, and a `!!! tip` linking them. (Scaffolded for you.) |
| `the-problem.md` | **Why it exists / what breaks** without it — motivates the rest. |
| mechanism page(s) | **How it works**, step by step. Split into multiple pages only if there are genuinely distinct sub-mechanisms (e.g. `leader-election.md` + `log-replication.md`). |
| `walkthrough.md` | **Worked example** — one real case traced through with concrete values. |
| `mental-model.md` | **The takeaway** — the one-sentence model, plus honest caveats. |

Conventions:

- Name pages for what the reader wants to understand (`the-problem.md`, `walkthrough.md`),
  not for document sections (`section-2.md`).
- Add a grounding page (like `building-blocks.md`) before the mechanism pages when the
  topic has several terms that the rules depend on — define the nouns first.
- Adapt freely: a small section might fold problem + mechanism into one page; a big one
  might add a safety/edge-cases page. The arc is a default, not a cage.

### Terminal-demo GIFs

An optional tool, not a checklist item. Do **not** add decorative closer GIFs — no
"GIF of the day" block at the bottom of a page.

- **Terminal-demo GIF.** When a page teaches a *workflow* (a CLI flow, a build, a failure
  reproducing), show it instead of describing it: record with
  `bash scripts/record_gif.sh docs/tutorials/<topic-slug>/gifs/<name>.gif -- "<command>"`
  (one-shot; pass a `.tape` file instead of `-- <command>` for multi-step scripted demos —
  vhs tape syntax: Type/Enter/Sleep lines like the one-shot template in the script). Run it
  from `~/teach-me/library` so the GIF lands inside `docs/`, then embed with
  `![what it shows](gifs/<name>.gif)`. zensical copies non-md files in `docs/` into the
  built site. Toolchain (vhs/ttyd/ffmpeg) is installed via mise; the script tells you the
  `mise use` line if it's missing. Keep demos short (< ~15s) and only record commands that
  are safe to re-run.

## Before you call it done

Check the explanation against its purpose — would a newcomer who read only the overview
get the shape, and would someone who read it all be able to *reconstruct* the idea, not
just recognize it? Concretely: gist is up top; every concept's nouns are defined before
its rules; at least one real worked example with values; the why is stated, not just the
what. For a site: `python3 tools/lint_readability.py` **and** `zensical build` are both
clean, and the served pages render (diagrams included).

Then one honesty check, because it is the failure mode this library actually had: **did you
reach for a container, or just write more prose?** Depth is not the enemy — undifferentiated
prose is. A set of parallel things is a table. A branch is a decision table. A before/after is
content tabs. A flow is mermaid. The tail of a long explanation is a `???` collapsible. The
daily logs here ran to 2,384 median words using **zero** tables-of-threads, **zero** mermaid
and **zero** content tabs, while the tutorials used 647 code fences, 187 diagrams and 178 tabs
— and the tutorials are the half people can actually read.
