#!/usr/bin/env python3
"""sync_topics_nav.py — merge + category-group the tutorials nav block.

The teach-me library exists on two machines: the dev box authors topics (and wires
them into ITS zensical.toml between the `# >>> tutorials` / `# <<< tutorials`
markers), while the laptop keeps a warm-standby copy. browser-bridge's sync-on-view
rsyncs docs/ across, but zensical.toml is per-machine — so without this merge,
topics created on the dev box never appear in the laptop's left nav.

Storage/merge format is FLAT: one bracket-balanced `{ "Title" = [ ...pages ] }`
chunk per topic, keyed by the `tutorials/<slug>/` in its page paths. To keep the
sidebar uncrowded, the written block is additionally GROUPED into categories from
`docs/tutorials/.nav-categories.json` ({"Category": ["slug", ...], ...}, ordered).
Category wrapper lines are tagged with `# nav-cat` / `# /nav-cat` trailing comments
so this script can deterministically flatten them back to chunks on the next run —
never parse the grouping heuristically, never hand-edit the wrapper lines.
Topics missing from the mapping stay ungrouped at the TOP of the block (visible —
new topics surface until they're categorized). The mapping file lives under docs/
so the rsync carries it to the laptop; if it's absent the block is written flat.

Merge semantics (unchanged):
  - topic in both        → source block wins (picks up added/renamed pages)
  - topic only local     → kept (local-only authoring survives)
  - topic only in source → appended

Usage: sync_topics_nav.py <source-zensical.toml>   # merge source topics, then regroup
       sync_topics_nav.py --regroup                # regroup the local block only
Honors $TEACHME_HOME (default: ~/teach-me); local toml = $TEACHME_HOME/library/zensical.toml.
"""
import json
import os
import pathlib
import re
import sys

HOME = os.path.expanduser("~")
LIB = pathlib.Path(os.environ.get("TEACHME_HOME", os.path.join(HOME, "teach-me"))) / "library"
TOML = LIB / "zensical.toml"
MAPPING = LIB / "docs" / "tutorials" / ".nav-categories.json"
START, END = "# >>> tutorials", "# <<< tutorials"
CAT_OPEN, CAT_CLOSE = "# nav-cat", "# /nav-cat"
SLUG_RE = re.compile(r"tutorials/([A-Za-z0-9._-]+)/")
STEP = "    "  # one nav nesting level


def marker_span(lines, path):
    try:
        s = next(i for i, l in enumerate(lines) if START in l)
        e = next(i for i, l in enumerate(lines) if END in l)
    except StopIteration:
        sys.exit(f"[teach-me] tutorials markers not found in {path}")
    return s, e


def flatten(lines):
    """Strip category wrapper lines (tagged # nav-cat / # /nav-cat) and their indent."""
    out, depth = [], 0
    for line in lines:
        stripped = line.rstrip("\n").rstrip()
        if stripped.endswith(CAT_CLOSE):
            depth = max(0, depth - 1)
            continue
        if stripped.endswith(CAT_OPEN):
            depth += 1
            continue
        if depth and line.startswith(STEP * depth):
            line = line[len(STEP) * depth :]
        out.append(line)
    return out


def chunks(lines):
    """Split flat block lines into per-topic chunks by bracket depth."""
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


def load_mapping():
    if not MAPPING.exists():
        return {}
    try:
        mapping = json.loads(MAPPING.read_text())
    except json.JSONDecodeError as err:
        print(f"[teach-me] WARNING: {MAPPING.name} invalid ({err}) — writing flat nav", file=sys.stderr)
        return {}
    return {cat: list(slugs) for cat, slugs in mapping.items()}


def regroup(topics, indent):
    """Emit ungrouped topics first (visible), then one tagged group per category."""
    mapping = load_mapping()
    categorized = {s for slugs in mapping.values() for s in slugs}
    out = []
    for slug, chunk in topics.items():
        if slug not in categorized:
            out.extend(chunk)
    emitted = set()
    for cat, slugs in mapping.items():
        present = [s for s in slugs if s in topics and s not in emitted]
        if not present:
            continue
        emitted.update(present)
        out.append(f'{indent}{{ "{cat}" = [  {CAT_OPEN}\n')
        for s in present:
            out.extend(STEP + l if l.strip() else l for l in topics[s])
        out.append(f"{indent}] }},  {CAT_CLOSE}\n")
    return out


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: sync_topics_nav.py <source-zensical.toml> | --regroup")
    if not TOML.exists():
        sys.exit(f"[teach-me] local zensical.toml not found at {TOML}")

    local = TOML.read_text().splitlines(keepends=True)
    ls, le = marker_span(local, TOML)
    indent = local[ls][: local[ls].index(START)]
    local_topics = chunks(flatten(local[ls + 1 : le]))

    changed = []
    if sys.argv[1] != "--regroup":
        src_path = pathlib.Path(sys.argv[1])
        if not src_path.exists():
            sys.exit(f"[teach-me] source toml not found: {src_path}")
        src = src_path.read_text().splitlines(keepends=True)
        ss, se = marker_span(src, src_path)
        src_topics = chunks(flatten(src[ss + 1 : se]))
        merged = {}
        for slug, block in local_topics.items():
            pick = src_topics.pop(slug, None)
            if pick is not None and pick != block:
                changed.append(slug)
                block = pick
            merged[slug] = block
        for slug, block in src_topics.items():  # source-only topics
            changed.append(slug)
            merged[slug] = block
        local_topics = merged

    new = local[: ls + 1] + regroup(local_topics, indent) + local[le:]
    if "".join(new) != "".join(local):
        TOML.write_text("".join(new))
        what = f"merged: {', '.join(changed)}; " if changed else ""
        n_cat = len(load_mapping())
        print(f"[teach-me] topic nav written ({what}{len(local_topics)} topics, {n_cat} categories)")
    else:
        print("[teach-me] topic nav already up to date")


if __name__ == "__main__":
    main()
