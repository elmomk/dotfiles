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

# 4. Serve — ONE server for the whole library, via the Bash tool with run_in_background.
#    serve_library.sh checks the port first: if a server is already up it no-ops (live-reload
#    picks up the new section), otherwise it starts one. Don't start a second by hand.
bash <skill>/scripts/serve_library.sh 8042

# 5. Open (WSL/mac/linux aware) — deep-link straight to the new section.
bash <skill>/scripts/open_site.sh 8042 tutorials/<topic-slug>/   # → …/tutorials/<topic-slug>/
```

`zensical serve` rebuilds on file change, so you can edit pages while it runs. Never
`pkill -f "zensical serve"` to "clean up" — the pattern matches the killing command's own
line and kills the server you just started; stop a specific server by its task/PID instead.

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
    { "Overview" = "tutorials/index.md" },
    # >>> tutorials
    { "OAuth 2.0 + PKCE" = [
        { "Overview"               = "tutorials/oauth-pkce/index.md" },
        { "Why PKCE exists"        = "tutorials/oauth-pkce/the-problem.md" },
        { "The flow, step by step" = "tutorials/oauth-pkce/the-flow.md" },
        { "Worked example"         = "tutorials/oauth-pkce/walkthrough.md" },
    ] },
    { "Raft consensus" = [
        { "Overview"        = "tutorials/raft/index.md" },
        { "Leader election" = "tutorials/raft/leader-election.md" },
    ] },
    # <<< tutorials
  ] },
]
```

Add a new topic by appending another `{ "Topic Title" = [ … ] }` block **between the
`# >>> tutorials` / `# <<< tutorials` markers** (and a row to the landing table in
`docs/index.md`). Intra-topic links stay relative (`the-flow.md`), so a topic's pages keep
working as long as they live together under `docs/tutorials/<topic>/`.

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
