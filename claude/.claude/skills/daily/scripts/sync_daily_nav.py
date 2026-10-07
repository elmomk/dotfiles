#!/usr/bin/env python3
"""sync_daily_nav.py — regenerate the Daily nav block in the shared teach-me library.

The library's zensical.toml has a Daily section whose entries live between the marker
comments `# >>> daily` and `# <<< daily`. This script scans docs/daily/*.md, keeps the
date-named pages (YYYY-MM-DD.md), and rewrites the block NEWEST FIRST:

  - the newest $DAILY_NAV_VISIBLE dates (default 5) as direct entries, so the sidebar
    stays uncluttered;
  - everything older nested under one "Older" group, sub-grouped by month (YYYY-MM),
    months and dates both newest-first.

Nav-only: pages stay at docs/daily/<date>.md, so URLs never change. Nothing outside
the markers is touched. Multi-line nesting inside the inline table is valid TOML 1.0
(newlines are legal inside array values — the tutorials block relies on the same).

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
VISIBLE = int(os.environ.get("DAILY_NAV_VISIBLE", "5"))


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
    recent, older = dates[:VISIBLE], dates[VISIBLE:]
    block = [lines[s]]
    block += [f'{indent}{{ "{d}" = "daily/{d}.md" }},\n' for d in recent]
    if older:
        by_month: dict[str, list[str]] = {}
        for d in older:  # newest-first, so months and their dates stay newest-first
            by_month.setdefault(d[:7], []).append(d)
        block.append(f'{indent}{{ "Older" = [\n')
        for month, ds in by_month.items():
            block.append(f'{indent}    {{ "{month}" = [\n')
            block += [f'{indent}        {{ "{d}" = "daily/{d}.md" }},\n' for d in ds]
            block.append(f'{indent}    ] }},\n')
        block.append(f'{indent}] }},\n')
    block.append(lines[e])
    new = lines[:s] + block + lines[e + 1 :]
    TOML.write_text("".join(new))
    months = len({d[:7] for d in older})
    print(
        f"[daily] synced {len(dates)} daily entr{'y' if len(dates)==1 else 'ies'} into nav "
        f"({len(recent)} visible, {len(older)} under Older in {months} month group{'s' if months != 1 else ''})"
    )


if __name__ == "__main__":
    main()
