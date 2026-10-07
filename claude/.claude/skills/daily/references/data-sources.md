# Daily data sources

The daily log is synthesized from four sources over a time **window**. Three are gathered
by `scripts/collect.sh` (→ `gather_context.py`) and returned as one JSON bundle; work-tracking
tickets are read from the GitLab SaaS board via `scripts/board_links.py`. Every source is best-effort: a failure is logged
to stderr and that section comes back empty rather than aborting the run.

## The window

- **Evening recap of day D**: `--since <D> --until <D+1>` (i.e. all of D up to now).
- **Morning of day D**:
  - the "Since <PREV_WORKDAY>" recap covers `--since <PREV_WORKDAY> --until <D>` — but only
    if no recap already exists for the previous workday (see the reuse rule in SKILL.md).
  - "today's plan" is derived from *current* open work (open/draft MRs, in-progress/assigned
    board tickets in the current iteration, stated next-steps in memory), not from a time window.

`PREV_WORKDAY` is the most recent weekday strictly before D (Mon→Fri, skipping the weekend).

## git (`gather_git`)

`git log --since … [--until …] --author=<email> --no-merges` across discovered repos.
Repos are auto-discovered from `~/work/git/*` and `~/git/*` (any dir with a `.git`), or from
`$DAILY_REPOS` / `--repos "<glob> ..."`. Output: per-repo list of `{sha, date, subject}`.

**Author is resolved per-repo**, not globally: `git config user.email` is run with
`cwd=<repo>` so per-repo and `includeIf` gitconfig apply (e.g. work repos commit as
`you@work.example.com` while personal repos use `salomob@gmail.com`). A single home-dir email
would miss the work commits. Override with `--author "a@x,b@y"` (comma-separated, git ORs
them) or `$DAILY_AUTHOR` when commits span identities a repo's config doesn't list.

## GitLab (`gather_gitlab`)

`glab mr list` per repo on a recognised GitLab remote, for `--author=@me`, `--assignee=@me`,
and `--reviewer=@me`. glab 1.91 has no `--updated-after` and lists only **open** MRs by
default, so we pass `-A -o updated_at -S desc -P 100` (all states, newest-updated first) and
filter the `[since, until)` window **client-side** on `updated_at` — this is what catches MRs
*merged* in the window, not just open ones. Results are deduped per repo by `(project_id, iid)`.

A "gitlab remote" is any remote whose host contains `gitlab` **or** matches a host `glab` is
authenticated to (from `glab auth status`) — so a self-hosted instance addressed only by IP
(e.g. `git@<internal-gitlab-host>:…`) is still recognised. `glab` is found on `PATH` or at the mise
install path. Output: per-repo list of
`{iid, title, state, draft, web_url, updated_at, created_at, created_in_window}`, where
`created_in_window` is true only when the MR was *opened* during the window (vs merely
touched) — so the daily can say "opened today" truthfully.

## claude-memory (`gather_memory`)

Reads the **per-project memory store** Claude Code actually writes:
`~/.claude/projects/<encoded-cwd>/memory/`, where `<encoded-cwd>` is the working directory
with every non-alphanumeric character replaced by `-`. The path is derived from the cwd, not
hardcoded; a worktree or subdirectory has no store of its own, so the reader walks up to the
nearest ancestor that does. Each memory is a markdown file with YAML frontmatter
(`name`, `description`, `metadata.type`); `MEMORY.md` is the index over them and is skipped.
These memories are **topical and undated**, so the whole store is read — there is nothing to
window-filter on, and the daily uses them for standing context and stated next-steps rather
than as windowed activity.

With `--query <kw>`, the FTS-backed `hooks` binary at `~/work/git/claude-memory/bin/hooks` is
tried first. The legacy per-day `~/.memory/<date>.md` files are read only when no project
store exists for the tree.

Output: `{source, dir, dir_exists, entries, truncated, dropped_noise, empty, empty_reason,
text}`. **`source` names the directory read and whether it existed** (e.g.
`project-store:/home/…/memory:exists` or `…:MISSING`), and an empty read sets `empty: true`
with an `empty_reason` and logs `memory: EMPTY — …` to stderr. An empty store is legitimate,
so the run still exits 0 — but it can no longer be mistaken for a healthy read.

## Work-tracking tickets — GitLab SaaS board (`scripts/board_links.py`)

Work tracking moved off Jira onto the **GitLab SaaS board** on 2026-07-06:
`<board-group>/tasks-n-docs` (on gitlab.com; id is `SAAS_PROJECT` in `scripts/board_links.py`),
where each ticket is an issue titled `PE-1234: …`. Sprints are GitLab **iterations** (e.g. S30);
the Developer-Portal OKR is **epic #11**. Jira (`atlassian.site` in `~/.work.json`) is legacy — kept
only as a *link fallback* for keys not yet mirrored onto the board. This is the same board
`mr-board-refresh` reads.

`scripts/board_links.py` resolves keys against the board with `glab` (no Jira, no MCP); output
is tab-separated:

- **Discovery (plan):** `board_links.py --mine` → my open assigned board issues as
  `KEY  web_url  status  summary` — the in-progress/assigned work for today's plan, links
  included. Board-native items with no PE-key come back as `#<iid>`.
- **Linking (any key):** `board_links.py PE-1234 PE-5678 …` → `KEY  web_url  state`. Pass every
  PE-key that lands on the page (plan, merge, recap, lhf) to get its board link. A key that comes
  back `-` isn't on the board → fall back to `https://<atlassian.site>/browse/<KEY>`.

Auth: the script scrubs the internal `GITLAB_TOKEN`/`GITLAB_HOST` envs so `glab` uses its
gitlab.com `config.yml` PAT (the internal token would 401 against SaaS). Disambiguation: only an
issue whose title *starts* `PE-1234:` wins, so a ticket that merely references the key can't be
mistaken for it (e.g. a `PE-2320: PE-2275 …` title resolves as 2320, never 2275).

GitLab MRs are linked from the collector's `gitlab[*].web_url` as `[<project>!<iid>](<web_url>)`.
