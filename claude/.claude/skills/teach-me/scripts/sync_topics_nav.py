#!/usr/bin/env python3
"""sync_topics_nav.py — merge tutorial topic nav blocks from another zensical.toml.

The teach-me library exists on two machines: the dev box authors topics (and wires
them into ITS zensical.toml between the `# >>> tutorials` / `# <<< tutorials`
markers), while the laptop serves the site. browser-bridge's sync-on-view rsyncs
docs/ across, but zensical.toml is per-machine — so without this merge, topics
created on the dev box never appear in the laptop's left nav.

Merges the source toml's tutorials block into the local one, keyed by topic slug
(the `tutorials/<slug>/` in each block's page paths):
  - topic in both        → source block wins (picks up added/renamed pages)
  - topic only local     → kept (local-only authoring survives)
  - topic only in source → appended after the local blocks

Usage: sync_topics_nav.py <source-zensical.toml>
Honors $TEACHME_HOME (default: ~/teach-me); local toml = $TEACHME_HOME/library/zensical.toml.
"""
import os
import pathlib
import re
import sys

HOME = os.path.expanduser("~")
LIB = pathlib.Path(os.environ.get("TEACHME_HOME", os.path.join(HOME, "teach-me"))) / "library"
TOML = LIB / "zensical.toml"
START, END = "# >>> tutorials", "# <<< tutorials"
SLUG_RE = re.compile(r"tutorials/([A-Za-z0-9._-]+)/")


def marker_span(lines, path):
    try:
        s = next(i for i, l in enumerate(lines) if START in l)
        e = next(i for i, l in enumerate(lines) if END in l)
    except StopIteration:
        sys.exit(f"[teach-me] tutorials markers not found in {path}")
    return s, e


def chunks(lines):
    """Split the lines between the markers into per-topic blocks by bracket depth."""
    out, cur, depth = [], [], 0
    for line in lines:
        if not cur and not line.strip():
            continue
        cur.append(line)
        if not line.lstrip().startswith("#"):
            depth += line.count("{") + line.count("[") - line.count("}") - line.count("]")
        if cur and depth <= 0:
            out.append(cur)
            cur, depth = [], 0
    if cur:
        out.append(cur)
    return {slug_of(c): c for c in out if slug_of(c)}


def slug_of(chunk):
    m = SLUG_RE.search("".join(chunk))
    return m.group(1) if m else None


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: sync_topics_nav.py <source-zensical.toml>")
    src_path = pathlib.Path(sys.argv[1])
    if not src_path.exists():
        sys.exit(f"[teach-me] source toml not found: {src_path}")
    if not TOML.exists():
        sys.exit(f"[teach-me] local zensical.toml not found at {TOML}")

    local = TOML.read_text().splitlines(keepends=True)
    ls, le = marker_span(local, TOML)
    src = src_path.read_text().splitlines(keepends=True)
    ss, se = marker_span(src, src_path)

    local_topics = chunks(local[ls + 1 : le])
    src_topics = chunks(src[ss + 1 : se])

    merged, changed = [], []
    for slug, block in local_topics.items():
        pick = src_topics.pop(slug, None)
        if pick is not None and pick != block:
            changed.append(slug)
            block = pick
        merged.extend(block)
    for slug, block in src_topics.items():  # source-only topics
        changed.append(slug)
        merged.extend(block)

    new = local[: ls + 1] + merged + local[le:]
    if changed:
        TOML.write_text("".join(new))
        print(f"[teach-me] merged topic nav: {', '.join(changed)}")
    else:
        print("[teach-me] topic nav already up to date")


if __name__ == "__main__":
    main()
