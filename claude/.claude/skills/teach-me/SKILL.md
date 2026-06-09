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
   add a row linking the section to the landing table in `docs/index.md`.
4. **Build.** `cd ~/teach-me/library && uv run zensical build` — fast; it flags broken
   links and missing pages. Fix until it reports "No issues found".
5. **Serve** the library with the Bash tool's `run_in_background` so it survives the turn:
   `bash scripts/serve_library.sh 8042`. The script **checks first** — if a server is
   already serving the library on that port it no-ops (live-reload picks up your new
   section), otherwise it starts `zensical serve` for you. **Run only one server**, and
   never `pkill -f "zensical serve"` (the pattern matches the killer's own command line and
   takes down the server you just started).
6. **Open** `bash scripts/open_site.sh 8042 tutorials/<topic-slug>/` to deep-link straight to
   the new section. Then tell the user the URL and the section's page list.

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

## Before you call it done

Check the explanation against its purpose — would a newcomer who read only the overview
get the shape, and would someone who read it all be able to *reconstruct* the idea, not
just recognize it? Concretely: gist is up top; every concept's nouns are defined before
its rules; at least one real worked example with values; the why is stated, not just the
what. For a site: `zensical build` is clean and the served pages render (diagrams included).
