#!/usr/bin/env python3
"""Stamp a generated page with when it was written.

Why this exists
---------------
Every page in this library is machine-generated, and several of them render state that is
true only at the moment of writing — a daily log's merge backlog, a bundle's live GitLab
status, a plan's "blocked on". A reader cannot tell a page written four minutes ago from one
written four weeks ago, and the two deserve very different trust.

Zensical has no `last-updated` support (upstream backlog #18 — open, no date), and the
filename only carries a date for `daily/`. So the stamp goes in the content.

Format: `Updated 2026-07-17 17:52 (+08:00)` — the offset is deliberate. This library is
published to a shared internal hub, so "17:52" alone is ambiguous to anyone not on this box.

Idempotent: re-running replaces the block rather than stacking a second one, so a morning
and an evening run on the same page agree. Matches the marker-block convention already used
by cartoon.py / gif.py / the daily skill.

Usage
-----
  stamp.py <page.md>                                  -> "Updated <now>"
  stamp.py <page.md> --note "evening run"             -> "Updated <now> · evening run"
  stamp.py <page.md> --label "Live GitLab state as of" -> custom label
  stamp.py <page.md> --print                          -> print the block, don't write
"""
from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import re
import sys

START, END = "<!-- ts:start -->", "<!-- ts:end -->"


def block(label: str, note: str | None, when: dt.datetime) -> str:
    stamp = when.strftime("%Y-%m-%d %H:%M")
    off = when.strftime("%z")
    off = f"{off[:3]}:{off[3:]}" if off else ""
    line = f"*{label} {stamp} ({off})*" if off else f"*{label} {stamp}*"
    if note:
        line = line[:-1] + f" · {note}*"
    return f"{START}\n{line}\n{END}"


def apply(text: str, blk: str) -> str:
    if START in text and END in text:
        return re.sub(re.escape(START) + r".*?" + re.escape(END), lambda _: blk, text, flags=re.S)

    # Insert directly after the H1 — the reader should see the age before the content.
    m = re.search(r"^#\s+.+$", text, flags=re.M)
    if m:
        i = m.end()
        return text[:i] + "\n\n" + blk + text[i:]

    # No H1 (unusual): fall back to after front matter, else the very top.
    fm = re.match(r"\A---\n.*?\n---\n", text, flags=re.S)
    i = fm.end() if fm else 0
    return text[:i] + blk + "\n\n" + text[i:]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("page")
    ap.add_argument("--label", default="Updated")
    ap.add_argument("--note", default=None)
    ap.add_argument("--print", dest="show", action="store_true")
    a = ap.parse_args()

    blk = block(a.label, a.note, dt.datetime.now().astimezone())
    if a.show:
        print(blk)
        return 0

    p = pathlib.Path(a.page).expanduser()
    if not p.exists():
        print(f"stamp: no such page: {p}", file=sys.stderr)
        return 1
    p.write_text(apply(p.read_text(encoding="utf-8"), blk), encoding="utf-8")
    print(f"stamped {p.name}: {blk.splitlines()[1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
