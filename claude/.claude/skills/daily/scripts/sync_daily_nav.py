#!/usr/bin/env python3
"""sync_daily_nav.py — regenerate the Daily nav block in the shared teach-me library.

The library's zensical.toml has a Daily section whose entries live between the marker
comments `# >>> daily` and `# <<< daily`. This script scans docs/daily/*.md, keeps the
date-named pages (YYYY-MM-DD.md), and rewrites the block with one entry per date,
NEWEST FIRST. Nothing outside the markers is touched.

Honors $TEACHME_HOME (default: ~/teach-me); library = $TEACHME_HOME/library.
Usage: sync_daily_nav.py
"""
import os
import pathlib
import re
import sys

HOME = os.path.expanduser("~")
LIB = pathlib.Path(os.environ.get("TEACHME_HOME", os.path.join(HOME, "teach-me"))) / "library"
TOML = LIB / "zensical.toml"
DAILY = LIB / "docs" / "daily"
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}\.md$")
START, END = "# >>> daily", "# <<< daily"


def main():
    if not TOML.exists():
        sys.exit(f"[daily] zensical.toml not found at {TOML}")
    dates = sorted(
        (p.stem for p in DAILY.glob("*.md") if DATE_RE.match(p.name)),
        reverse=True,
    )
    lines = TOML.read_text().splitlines(keepends=True)
    try:
        s = next(i for i, l in enumerate(lines) if START in l)
        e = next(i for i, l in enumerate(lines) if END in l)
    except StopIteration:
        sys.exit("[daily] daily markers not found in zensical.toml — is the library migrated?")
    indent = lines[s][: lines[s].index(START)]
    block = [lines[s]]
    block += [f'{indent}{{ "{d}" = "daily/{d}.md" }},\n' for d in dates]
    block.append(lines[e])
    new = lines[: s] + block + lines[e + 1 :]
    TOML.write_text("".join(new))
    print(f"[daily] synced {len(dates)} daily entr{'y' if len(dates)==1 else 'ies'} into nav")


if __name__ == "__main__":
    main()
