# Daily data sources

The daily log is synthesized from four sources over a time **window**. Three are gathered
by `scripts/collect.sh` (→ `gather_context.py`) and returned as one JSON bundle; Jira is
queried by Claude via the Atlassian MCP. Every source is best-effort: a failure is logged
to stderr and that section comes back empty rather than aborting the run.

## The window

- **Evening recap of day D**: `--since <D> --until <D+1>` (i.e. all of D up to now).
- **Morning of day D**:
  - the "Since <PREV_WORKDAY>" recap covers `--since <PREV_WORKDAY> --until <D>` — but only
    if no recap already exists for the previous workday (see the reuse rule in SKILL.md).
  - "today's plan" is derived from *current* open work (open/draft MRs, in-progress/assigned
    Jira in the active sprint, stated next-steps in memory), not from a time window.

`PREV_WORKDAY` is the most recent weekday strictly before D (Mon→Fri, skipping the weekend).

## git (`gather_git`)

`git log --since … [--until …] --author=<email> --no-merges` across discovered repos.
Repos are auto-discovered from `~/work/git/*` and `~/git/*` (any dir with a `.git`), or from
`$DAILY_REPOS` / `--repos "<glob> ..."`. Output: per-repo list of `{sha, date, subject}`.

**Author is resolved per-repo**, not globally: `git config user.email` is run with
`cwd=<repo>` so per-repo and `includeIf` gitconfig apply (e.g. work repos commit as
`momoyang@fmt.com.tw` while personal repos use `salomob@gmail.com`). A single home-dir email
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
(e.g. `git@10.2.11.139:…`) is still recognised. `glab` is found on `PATH` or at the mise
install path. Output: per-repo list of
`{iid, title, state, draft, web_url, updated_at, created_at, created_in_window}`, where
`created_in_window` is true only when the MR was *opened* during the window (vs merely
touched) — so the daily can say "opened today" truthfully.

## claude-memory (`gather_memory`)

The `hooks` binary at `~/work/git/claude-memory/bin/hooks`:
`hooks search "" --since <date> --limit 40` (empty query = recent entries). Falls back to
reading the newest few `~/.memory/*.md` files if the binary is absent or errors. Output:
`{source, text}`.

## Jira (Atlassian MCP — Claude-side, not in the script)

Claude queries `searchJiraIssuesUsingJql`:

- Recap (what moved): `assignee = currentUser() AND updated >= -1d ORDER BY updated DESC`
  (use `-3d` on a Monday so Friday's work is included).
- Today's plan (what's active): `assignee = currentUser() AND statusCategory != Done AND
  sprint in openSprints() ORDER BY priority DESC`.

Fold the returned issues (key, summary, status) into the relevant section, and **link each
key**: `[<KEY>](<base>/browse/<KEY>)`. Get `<base>` from `getAccessibleAtlassianResources`
(the `url` field = `https://<site>.atlassian.net`); call it once and reuse it for every issue.

GitLab MRs are linked from the collector's `gitlab[*].web_url` as `[<project>!<iid>](<web_url>)`.
