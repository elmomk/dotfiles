# Zensical reference

Zensical is a static-site generator from the Material for MkDocs team. The default
template ships every authoring feature this skill relies on (admonitions, content tabs,
mermaid, code highlighting), so you rarely touch the config beyond the nav and title.

## Mechanics (the whole lifecycle)

One library at `~/teach-me/library/`, one server. Each topic is a section under the
`Tutorials` umbrella at `docs/tutorials/<topic>/`.

```bash
# 1. Add a topic (idempotent) — scaffolds the library on first use, then creates
#    docs/<topic>/index.md from the starter overview.
bash <skill>/scripts/add_topic.sh <topic-slug> "Topic Title" "One-line description"

# 2. Author: write docs/<topic-slug>/*.md, add a nested nav block + a landing-page row.

# 3. Build (fast, ~0.3-0.8s; reports broken links/refs).
cd ~/teach-me/library && uv run zensical build

# 4. Serve — ONE server for the whole library; a normal foreground command (the server
#    detaches and survives the session). serve_library.sh checks the port first: if the
#    library server is already up it no-ops — it serves site/ from disk with no-cache
#    headers, so the latest build is always what a (re)load gets. Don't start a second.
bash <skill>/scripts/serve_library.sh 8042

# 5. Open (WSL/mac/linux aware) — deep-link straight to the new section.
bash <skill>/scripts/open_site.sh 8042 tutorials/<topic-slug>/   # → …/tutorials/<topic-slug>/
```

The server has no watcher — content changes go live by running `zensical build` (step 3);
the server picks the new files up from disk. Never `pkill` by name pattern to "clean up" —
stop a specific server by its PID (serve_library.sh handles replacing a stale one itself).

## Config: `zensical.toml`

TOML, not `mkdocs.yml`. `site_name` ("Explainers") is set when the library is scaffolded;
the field you edit per topic is `nav` — one **nested block per topic, inside the `Tutorials`
section**, with pages referenced by their `tutorials/<topic-slug>/page.md` path:

```toml
[project]
site_name = "Explainers"
site_description = "A library of teach-me explainers — one section per topic."

# A "Home" landing page, then the Tutorials section holding one nested block per topic.
# Without an explicit nav, Zensical derives it from the directory tree (alphabetical),
# which is rarely right.
nav = [
  { "Home" = "index.md" },
  { "Tutorials" = [
    "tutorials/index.md",
    # >>> tutorials
    { "OAuth 2.0 + PKCE" = [
        "tutorials/oauth-pkce/index.md",
        { "Why PKCE exists"        = "tutorials/oauth-pkce/the-problem.md" },
        { "The flow, step by step" = "tutorials/oauth-pkce/the-flow.md" },
        { "Worked example"         = "tutorials/oauth-pkce/walkthrough.md" },
    ] },
    { "Raft consensus" = [
        "tutorials/raft/index.md",
        { "Leader election" = "tutorials/raft/leader-election.md" },
    ] },
    # <<< tutorials
  ] },
]
```

## Dating a generated page — the `ts` block

Every page here is machine-written, and several render state that is true only at the moment
of writing (a daily's merge backlog, a bundle's GitLab status, a plan's "blocked on"). A
reader cannot tell a page written four minutes ago from one written four weeks ago, and the
two deserve very different trust. Zensical has **no `last-updated` support**
([backlog #18](https://github.com/zensical/backlog/issues/18) — open, no date), so the stamp
lives in the content.

One helper, one convention, used by `/daily`, `/teach-me` and `/publish-plan`:

```bash
python3 <teach-me>/scripts/stamp.py <page.md> [--note "evening run"] [--label "Live GitLab state as of"]
```

```markdown
<!-- ts:start -->
*Updated 2026-07-17 17:52 (+08:00) · evening run*
<!-- ts:end -->
```

Rules that matter:

- **Immediately after the H1**, never at the foot. Age is the first thing a reader needs, not
  a footnote they reach after already trusting the page. (One skill used to stamp at the
  bottom; it doesn't now.)
- **Always carry the UTC offset.** This library is published to a shared internal hub — a bare
  `17:52` is ambiguous to everyone not on this box.
- **Idempotent.** Re-running replaces the block, so a morning and an evening run on the same
  page agree instead of stacking two stamps.
- **Only re-stamp what you rewrote.** Stamping an untouched page makes the date a lie.

!!! danger "A topic's `index.md` MUST be a bare string, never `{ "Overview" = … }`"
    A **bare string** as a section's first entry makes it that section's *index page*
    (`navigation.indexes`), so the sidebar labels it with the **section title** —
    "OAuth 2.0 + PKCE". Writing `{ "Overview" = "tutorials/oauth-pkce/index.md" }` instead
    labels it **"Overview"**, and with 39 topics the sidebar becomes 39 identical
    "Overview" rows with the topic names nowhere on screen. This actually happened here
    (fixed 2026-07-17) and it is invisible until `navigation.tabs` is on.

    Same rule for the section overviews: `"tutorials/index.md"`, not
    `{ "Overview" = "tutorials/index.md" }`.

    Why it matters beyond tidiness: nav depth is only expensive when labels are ambiguous
    (Larson & Czerwinski 1998; Miller & Remington 2004) — an uninformative label multiplies
    the cost of every wrong guess.

Add a new topic by appending another `{ "Topic Title" = [ … ] }` block **between the
`# >>> tutorials` / `# <<< tutorials` markers**, and a card to the grid in
`docs/tutorials/index.md` (grouped by its area from `.nav-categories.json`) — the landing
page `docs/index.md` links areas, not individual topics. Intra-topic links stay relative
(`the-flow.md`), so a topic's pages keep working as long as they live together under
`docs/tutorials/<topic>/`.

## Authoring features (Material-style Markdown)

Pages are Markdown. Optional per-page frontmatter sets a nav icon:

```markdown
---
icon: lucide/git-merge
---
# Page title
```

### Admonitions — signpost the reading

```markdown
!!! abstract "The one-paragraph version"
    The whole thing in a nutshell, before any detail.

!!! danger "The silent part"
    The trap / failure mode the reader must not miss.

!!! success "Why this is better"
    The payoff.

??? example "Collapsed by default — click to expand"
    Use the `???` form for deep detail that would clutter the main flow.
```

Types: `abstract` (summary), `tip` (navigation/next-steps), `note`/`info`,
`warning`/`danger` (gotchas), `success` (payoff), `question` (anticipated Q),
`quote` (the closing mental model). `???` makes any of them collapsible.

### Content tabs — before/after, this-way/that-way

```markdown
=== "Today (wholesale)"

    ```bash
    rm -rf dir/ && cp render/* dir/
    ```

=== "Fix (3-way)"

    ```bash
    python3 merge.py --base … --ours … --theirs …
    ```
```

Indent tab bodies by 4 spaces. Great for side-by-side comparison without scrolling.

### Mermaid — show the shape before the prose

Fenced ```mermaid blocks render client-side. Use the right diagram for the job:

- **flowchart** — pipelines, architecture, decision trees.
- **sequenceDiagram** — timelines, incidents, request/response, "who did what when".

```markdown
​```mermaid
sequenceDiagram
    participant A as MR (stale)
    participant M as master
    A->>M: merge — reverts sibling ❌
​```
```

Keep node labels short; use `<br/>` for line breaks. Quote labels containing
punctuation: `A["text: with punctuation"]`.

### Tables — decision/truth tables

Plain GitHub-flavored Markdown tables. Ideal for "given condition X → do Y" logic and
for tracing a worked example value-by-value.

## Troubleshooting

- **`uv` missing** — it's the project's Python tool; install via mise or `pipx`. Never
  `pip install` into system Python.
- **Browser doesn't open on WSL** — `open_site.sh` uses `explorer.exe`, which exits
  non-zero even on success; that's normal. Fall back to `localhost:<port>` in the browser.
- **Build error / broken link** — `zensical build` names the file and reference. Most
  often a nav entry points at a page you haven't created yet.
- **mermaid not rendering** — it renders in the browser, not in `zensical build` output;
  check the served page, not the build log.
