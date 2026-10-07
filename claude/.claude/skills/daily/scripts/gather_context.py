#!/usr/bin/env python3
"""gather_context.py — collect raw activity signal for a daily log.

Pulls, best-effort, from three local sources over a time window:
  - git    : commits by the user across known repos (git log, author-filtered)
  - gitlab : merge requests touched by the user (glab, per-repo)
  - memory : claude-memory entries (the per-project store under ~/.claude/projects, with
             the `hooks` binary for keyword search and legacy ~/.memory as a fallback)

Jira is NOT gathered here — it lives behind the Atlassian MCP, which is queried by
Claude (the skill) directly, not by this script.

Each source is independently wrapped: a failure logs to stderr and yields an empty
section rather than aborting the run. Output is a single JSON object on stdout.

Usage:
  gather_context.py --since 2026-05-31 [--until 2026-06-01] [--repos "<glob> ..."]

Dates are ISO (YYYY-MM-DD) or any string git/glab accept. --until is exclusive-ish
(passed straight to git --until / used as the upper bound for memory).
"""
import argparse
import datetime as dt
import glob
import json
import os
import re
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
MEMORY_BIN = os.path.join(HOME, "work/git/claude-memory/bin/hooks")
PROJECTS_DIR = os.path.join(HOME, ".claude/projects")
LEGACY_MEMORY_DIR = os.path.join(HOME, ".memory")
GLAB_CANDIDATES = [
    "glab",
    os.path.join(HOME, ".local/share/mise/installs/asdf-mise-plugins-mise-glab/1.91.0/bin/glab"),
]
DEFAULT_REPO_GLOBS = [
    os.path.join(HOME, "work/git/*"),
    os.path.join(HOME, "work/idp/*"),
    os.path.join(HOME, "git/*"),
]

# Auto-saved memory is dominated by prompt-injection-flag entries (the assistant logging
# that it refused an injection). They carry no work signal — drop them from the daily.
NOISE_MARKERS = (
    "prompt injection",
    "summarize this conversation turn",
    "not following it",
    "is there something real i can help",
    "fabricated `h:`",
    "fabricated h:",
)
DATE_FILE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---\n?", re.S)


def is_noise(text):
    t = text.lower()
    return any(m in t for m in NOISE_MARKERS)


def log(msg):
    print(f"[gather] {msg}", file=sys.stderr)


def run(cmd, cwd=None, timeout=30):
    """Run a command, return (rc, stdout, stderr). Never raises."""
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except Exception as e:  # noqa: BLE001 - best-effort by design
        return 1, "", str(e)


def find_glab():
    for c in GLAB_CANDIDATES:
        if os.path.sep in c:
            if os.path.exists(c):
                return c
        elif shutil.which(c):
            return c
    return None


def discover_repos(globs):
    repos = []
    for g in globs:
        for path in glob.glob(g):
            if os.path.isdir(os.path.join(path, ".git")):
                repos.append(path)
    return sorted(set(repos))


def repo_author_emails(repo, overrides):
    """Emails to match commits against in this repo.

    Overrides (from --author / $DAILY_AUTHOR) win. Otherwise use the repo's OWN
    configured identity — run with cwd=repo so per-repo and `includeIf` gitconfig
    (e.g. work repos using you@work.example.com) resolve correctly, instead of the
    home-dir default.
    """
    if overrides:
        return overrides
    rc, out, _ = run(["git", "config", "user.email"], cwd=repo)
    return [out.strip()] if rc == 0 and out.strip() else []


def gather_git(repos, since, until, overrides):
    """Commits authored by the user in [since, until) per repo."""
    out = {}
    for repo in repos:
        emails = repo_author_emails(repo, overrides)
        cmd = [
            "git", "log",
            f"--since={since}",
            "--no-merges",
            "--pretty=format:%h%x09%ad%x09%s",
            "--date=short",
        ]
        if until:
            cmd.append(f"--until={until}")
        # git ORs multiple --author patterns, covering identities across repos.
        for email in emails:
            cmd.append(f"--author={email}")
        rc, stdout, stderr = run(cmd, cwd=repo)
        if rc != 0:
            log(f"git: {os.path.basename(repo)}: {stderr.strip()[:120]}")
            continue
        lines = [l for l in stdout.splitlines() if l.strip()]
        if not lines:
            continue
        commits = []
        for l in lines:
            parts = l.split("\t", 2)
            if len(parts) == 3:
                commits.append({"sha": parts[0], "date": parts[1], "subject": parts[2]})
        if commits:
            out[os.path.basename(repo)] = commits
    return out


def gitlab_hosts(glab):
    """Hosts glab is authenticated to, so a self-hosted instance addressed by IP/hostname
    (no literal 'gitlab' in the remote URL) is still recognised as a GitLab repo."""
    if not glab:
        return set()
    rc, out, err = run([glab, "auth", "status"], cwd=HOME)
    return set(re.findall(r"Logged in to (\S+)", out + "\n" + err))


def gather_gitlab(repos, since, glab, until=None):
    """MRs authored/assigned/reviewed by the user, updated within [since, until), per repo
    with a gitlab remote. glab (1.91) has no --updated-after and lists only open MRs by
    default, so we pull ALL states (-A) ordered by updated_at desc and filter the window
    client-side — this is what catches MRs *merged* today, not just open ones."""
    if not glab:
        log("gitlab: glab not found, skipping")
        return {}
    hosts = gitlab_hosts(glab)  # e.g. self-hosted GitLab reachable only by IP
    out = {}
    for repo in repos:
        rc, remote, _ = run(["git", "remote", "-v"], cwd=repo)
        if rc != 0:
            continue
        low = remote.lower()
        if "gitlab" not in low and not any(h.lower() in low for h in hosts):
            continue
        seen, mrs = set(), []
        for flag in ("--author=@me", "--assignee=@me", "--reviewer=@me"):
            rc, stdout, stderr = run(
                [glab, "mr", "list", flag, "-A", "-o", "updated_at", "-S", "desc",
                 "-P", "100", "-F", "json"],
                cwd=repo,
            )
            if rc != 0:
                log(f"gitlab: {os.path.basename(repo)} {flag}: {stderr.strip()[:120]}")
                continue
            try:
                items = json.loads(stdout) if stdout.strip() else []
            except json.JSONDecodeError:
                continue
            for mr in items:
                upd = (mr.get("updated_at") or "")[:10]
                if until and upd >= until:
                    continue          # updated after the window — skip
                if upd < since:
                    break             # desc-ordered: nothing further qualifies
                key = (mr.get("project_id"), mr.get("iid"))
                if key in seen:
                    continue
                seen.add(key)
                created = (mr.get("created_at") or "")[:10]
                mrs.append({
                    "iid": mr.get("iid"),
                    "title": mr.get("title"),
                    "state": mr.get("state"),
                    "draft": mr.get("draft") or mr.get("work_in_progress"),
                    "web_url": mr.get("web_url"),
                    "updated_at": mr.get("updated_at"),
                    "created_at": mr.get("created_at"),
                    # opened *within* the window vs merely touched — lets the daily say
                    # "opened today" only when it's true.
                    "created_in_window": bool(created) and created >= since
                    and (not until or created < until),
                })
        if mrs:
            out[os.path.basename(repo)] = mrs
    return out


def project_memory_dir(cwd=None):
    """Locate the claude-memory store for the current project. Returns (path, exists).

    Claude Code keeps per-project memories in ~/.claude/projects/<encoded-cwd>/memory/,
    where <encoded-cwd> is the working directory with every non-alphanumeric character
    replaced by '-'. Derived, not hardcoded, so this works from any project — but a
    worktree or subdirectory has no store of its own, so walk up to the nearest ancestor
    that does. When nothing matches, return the cwd-derived path anyway with exists=False
    so the caller can report *which* directory it looked for.
    """
    path = os.path.abspath(cwd or os.getcwd())
    derived = None
    while True:
        candidate = os.path.join(PROJECTS_DIR, re.sub(r"[^a-zA-Z0-9]", "-", path), "memory")
        if derived is None:
            derived = candidate
        if os.path.isdir(candidate):
            return candidate, True
        parent = os.path.dirname(path)
        if parent == path:  # reached the filesystem root
            return derived, False
        path = parent


def _memory_entry(path):
    """(header, body) for one memory file: 'name — description' from its YAML frontmatter
    (falling back to the filename) and the markdown that follows."""
    text = open(path, encoding="utf-8", errors="replace").read()
    name = os.path.splitext(os.path.basename(path))[0]
    desc, body = "", text
    m = FRONTMATTER_RE.match(text)
    if m:
        body = text[m.end():]
        for line in m.group(1).splitlines():  # top-level keys only; metadata is indented
            if line.startswith("name:"):
                name = line.split(":", 1)[1].strip().strip("\"'") or name
            elif line.startswith("description:"):
                desc = line.split(":", 1)[1].strip().strip("\"'")
    return (f"{name} — {desc}" if desc else name), body.strip()


def _memory_from_store(mem_dir):
    """Read the per-project memory store: one markdown file per memory plus a MEMORY.md
    index over them. These memories are topical and undated — unlike the legacy per-day
    files there is nothing to window-filter on, and the daily uses them for standing
    context and stated next-steps rather than as windowed activity. Returns
    (kept_entries, dropped_count).
    """
    kept, dropped = [], 0
    for path in sorted(glob.glob(os.path.join(mem_dir, "*.md"))):
        if os.path.basename(path) == "MEMORY.md":
            continue  # index over the other files, not a memory itself
        try:
            header, body = _memory_entry(path)
        except OSError as e:
            log(f"memory: {os.path.basename(path)}: {e}")
            continue
        if not body:
            continue
        if is_noise(body):
            dropped += 1
            continue
        kept.append(f"### {header}\n{body}")
    return kept, dropped


def _memory_from_files(mem_dir, since, until):
    """Read <mem_dir>/<date>.md within the window, split into entries, drop noise.

    Memory files are per-day, named YYYY-MM-DD.md; entries are '### HH:MM [project]'
    blocks with a <!-- session ... --> metadata line. There's no keyword to FTS-search
    on for a daily, so we read by date and filter out the prompt-injection-flag entries
    that otherwise dominate the store. Returns (kept_entries, dropped_count).
    """
    kept, dropped = [], 0
    for path in sorted(glob.glob(os.path.join(mem_dir, "*.md"))):
        stem = os.path.splitext(os.path.basename(path))[0]
        if not DATE_FILE_RE.match(stem) or stem < since or (until and stem >= until):
            continue
        try:
            text = open(path, encoding="utf-8", errors="replace").read()
        except OSError as e:
            log(f"memory: {stem}: {e}")
            continue
        for chunk in re.split(r"(?m)^#{2,3} ", text)[1:]:
            lines = chunk.splitlines()
            header = lines[0].strip()
            if header.lower().startswith("session"):  # grouping header, not an entry
                continue
            body = "\n".join(l for l in lines[1:] if not l.lstrip().startswith("<!--")).strip()
            if not body:
                continue
            if is_noise(body):
                dropped += 1
                continue
            kept.append(f"### {stem} {header}\n{body}")
    return kept, dropped


def gather_memory(since, until, query="", limit=40):
    """claude-memory signal for the daily.

    With a keyword `query`, use the FTS-backed `hooks search`. Without one (the daily
    default), read the per-project memory store under ~/.claude/projects — the store Claude
    Code actually writes — falling back to the legacy per-day ~/.memory files where that is
    all a box has. An empty `hooks search ""` is NOT used, since it errors with
    `fts5: syntax error near ""`.

    `source` always names the directory read and whether it existed, and an empty read is
    reported as `empty` with a reason: a zero-length result must never be mistakable for a
    healthy one. An empty store is legitimate, so this stays best-effort and never aborts.
    """
    if query and os.path.exists(MEMORY_BIN):
        rc, stdout, stderr = run(
            [MEMORY_BIN, "search", query, "--since", since, "--limit", str(limit)],
            timeout=45,
        )
        if rc == 0 and stdout.strip():
            return {"source": f"hooks:{MEMORY_BIN}", "query": query, "text": stdout.strip()}
        log(f"memory: hooks search '{query}' rc={rc} {stderr.strip()[:120]}")

    mem_dir, found = project_memory_dir()
    label = "project-store"
    if not found and os.path.isdir(LEGACY_MEMORY_DIR):
        mem_dir, found, label = LEGACY_MEMORY_DIR, True, "legacy-files"
    source = f"{label}:{mem_dir}:{'exists' if found else 'MISSING'}"

    if not found:
        log(f"memory: EMPTY — {mem_dir} does not exist, nothing was read")
        return {"source": source, "dir": mem_dir, "dir_exists": False, "entries": 0,
                "empty": True, "empty_reason": f"{mem_dir} does not exist", "text": ""}
    try:
        kept, dropped = (_memory_from_files(mem_dir, since, until) if label == "legacy-files"
                         else _memory_from_store(mem_dir))
    except Exception as e:  # noqa: BLE001
        log(f"memory: read of {mem_dir} failed: {e}")
        return {"source": f"{source}:ERROR", "dir": mem_dir, "dir_exists": True, "entries": 0,
                "empty": True, "empty_reason": f"read of {mem_dir} failed: {e}", "text": ""}
    if not kept:
        log(f"memory: EMPTY — {mem_dir} exists but yielded no entries "
            f"({dropped} dropped as noise)")
    text = "\n\n".join(kept)
    return {
        "source": source,
        "dir": mem_dir,
        "dir_exists": True,
        "entries": len(kept),
        "truncated": len(text) > 8000,  # `entries` counts more than `text` carries
        "dropped_noise": dropped,
        "empty": not kept,
        "empty_reason": "" if kept else
                        f"{mem_dir} exists but yielded no usable memories "
                        f"({dropped} dropped as noise)",
        "text": text[:8000],
    }


def main():
    ap = argparse.ArgumentParser()
    today = dt.date.today()
    ap.add_argument("--since", default=str(today - dt.timedelta(days=1)))
    ap.add_argument("--until", default="")
    ap.add_argument("--repos", default="", help="space-separated repo path globs (overrides defaults)")
    ap.add_argument("--author", default=os.environ.get("DAILY_AUTHOR", ""),
                    help="comma-separated author email(s) to match (default: each repo's own git config user.email)")
    ap.add_argument("--query", default="",
                    help="keyword for memory FTS search; empty (default) reads memory files by date and strips noise")
    args = ap.parse_args()

    globs = args.repos.split() if args.repos.strip() else DEFAULT_REPO_GLOBS
    repos = discover_repos(globs)
    overrides = [e.strip() for e in args.author.split(",") if e.strip()]
    glab = find_glab()
    log(f"window {args.since} -> {args.until or 'now'}; {len(repos)} repos; "
        f"author={overrides or 'per-repo git config user.email'}")

    bundle = {
        "window": {"since": args.since, "until": args.until or None},
        "author": overrides or "per-repo (git config user.email)",
        "git": gather_git(repos, args.since, args.until, overrides),
        "gitlab": gather_gitlab(repos, args.since, glab, args.until),
        "memory": gather_memory(args.since, args.until, args.query),
    }
    json.dump(bundle, sys.stdout, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
