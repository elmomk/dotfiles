---
name: mr-summary
description: "Fetch live GitLab MR state as a compact table. Triggers: check MR, MR status, MR state. Args: proj:mr specs."
argument-hint: "<proj>:<mr> [<proj>:<mr>...] (e.g., 'sv:11 dp:10 cf:806 cf:808')"
---

# MR Summary

Fetches live state for a set of GitLab MRs and renders a compact table. Purpose-built for verifying a merge plan against actual GitLab state — memory-based summaries go stale fast.

## Files

- `mr-summary.py` — extracts the fields we care about from a single MR's JSON. Reads JSON on stdin.

## Project shorthand

| Short | Full path |
|---|---|
| `sv` | `platform-engineering/idp/selfservice` |
| `dp` | `platform-engineering/idp/devportal` |
| `cf` | `platform-engineering/configs` |

Accept either shorthand or a full `group/subgroup/project` path. If the user gives a bare number with no prefix, ask which project.

## Instructions

Don't delegate to a sub-agent — the fetches are fast and the model calling this skill needs to see the structured output to build the table.

### Token + binary

```bash
export GITLAB_TOKEN=$(jq -r '.gitlab.token' ~/.secrets.json)
GLAB=$(command -v glab)   # glab on PATH (mise shims); portable across machines
```

The env's `GITLAB_TOKEN` may be expired — the one in `~/.secrets.json` is the source of truth. If *that* also returns 401, tell the user to refresh (see `/daily` or cc-mem notes for the recipe).

### Fetch each MR

Single MR (key-value):

```bash
enc=$(echo "<project-path>" | sed 's|/|%2F|g')
$GLAB api "projects/$enc/merge_requests/<iid>" | python3 ~/.claude/skills/mr-summary/mr-summary.py
```

Batch (parallel-safe, use `--tsv`):

```bash
fetch() {
  local enc=$(echo "$1" | sed 's|/|%2F|g')
  $GLAB api "projects/$enc/merge_requests/$2" | python3 ~/.claude/skills/mr-summary/mr-summary.py --tsv
}

fetch platform-engineering/idp/selfservice 11 &
fetch platform-engineering/idp/devportal   10 &
fetch platform-engineering/configs        806 &
fetch platform-engineering/configs        808 &
wait
```

The `--tsv` row already contains `iid` and `web_url`, so rows are self-identifying — **do not** add an external `printf` prefix before the pipe. In parallel subshells the prefix write races the pipeline write and rows get interleaved. Each `--tsv` line is a single `print()` call, so it lands atomically under 4 KiB.

### Output

Render a markdown table with columns: `MR`, `State`, `Pipeline`, `Mergeable`, `Conflicts`, `Last Update`. Optionally add `Title` if the user wants more context. Use emoji for quick scanning:

- ✅ state=merged, pipeline=success, mergeable
- ⚠️ pipeline=manual / needs-rebase / stale (>3 days old on an open MR)
- ❌ pipeline=failed, has_conflicts=true, state=closed
- ⏳ pipeline=running/pending

After the table, briefly flag anything actionable: failed pipelines, stale MRs, conflicts, drafts, or discrepancies vs. whatever plan the user had in mind. Don't re-derive the merge order unless the user asks — just surface the state.

## Examples

- `/mr-summary sv:11 dp:10 cf:806 cf:808` — batch check 4 MRs
- `/mr-summary sv:11` — single MR deep-dive (use key-value output, not table)
- `/mr-summary platform-engineering/other/project:42` — full path when shorthand doesn't match

## Script flags

`mr-summary.py` reads MR JSON on stdin and prints:

- Default: key-value lines, human-readable
- `--tsv`: single tab-separated row (iid, title, state, source, merge, head_sha, pipeline, conflicts, updated, web_url) — useful when the caller is building its own table by piping many MRs through
