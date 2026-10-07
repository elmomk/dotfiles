#!/usr/bin/env python3
"""Idempotent scaffold for the Decisions (ADR) section of the teach-me library.

  ensure_decisions.py                        -> overview page + Decisions nav section
  ensure_decisions.py next                   -> print the next free ADR number
  ensure_decisions.py new <slug> <Title> <YYYY-MM-DD>
                                             -> numbered ADR page + nav row (numeric order)

One page per decision under docs/decisions/, numbered NNNN-<slug>.md; index.md holds
only the rollup table, never bodies.

Why a page per decision rather than a page per area (unlike /buggy): an ADR is a
document you read top-to-bottom — context, options, decision, consequences — and it is
cited by its number from tickets, MRs and other ADRs. A stable number that resolves to
exactly one page is the whole point. Numbers are never reused, and a reversed decision
gets a NEW ADR that supersedes the old one rather than an edit in place.
"""
import pathlib
import re
import sys

LIB = pathlib.Path.home() / "teach-me/library"
DOCS = LIB / "docs/decisions"
TOML = LIB / "zensical.toml"

INDEX = """---
icon: lucide/gavel
---

# Decisions

!!! abstract "TL;DR"
    No decisions recorded yet

Architecture decision records — one page per decision, numbered and permanent. Each
carries the context that forced the call, the options weighed, the decision, its
consequences, and an explicit split between what was **verified** and what was
**assumed**. Filed by the `/adr` skill.

An ADR is never rewritten to say something else. A reversed call gets a new ADR that
supersedes the old one, and the old page stays readable — the reasoning that turned out
wrong is the part worth keeping.

| Status | Meaning |
| --- | --- |
| :material-lightbulb-outline: **Proposed** | Shape is decided; still gated on an answer, a measurement or a sign-off |
| :material-check-decagram: **Accepted** | In force — build against this |
| :material-file-replace-outline: **Superseded** | Replaced by a later ADR, linked from the header |
| :material-close-circle-outline: **Rejected** | Considered and declined; kept so it is not re-proposed |
| :material-archive-outline: **Deprecated** | No longer relevant — the thing it decided is gone |

## The record

<!-- adrs:start -->
<!-- adrs:end -->
"""

ADR = """---
icon: lucide/gavel
---

# ADR-{num} · {title}

<!-- ts:start -->
*Recorded {date}*
<!-- ts:end -->

| Field | Value |
| --- | --- |
| **Status** | :material-lightbulb-outline: Proposed |
| **Date** | {date} |
| **Deciders** | |
| **Supersedes** | — |
| **Superseded by** | — |
| **Tracking** | |

!!! abstract "TL;DR"
    <the decision itself, 1-3 sentences — what we will do, not why>

<!-- adr:start -->

## Context

## Decision

## Options considered

## Consequences

## Verified vs assumed

## Revisit if

<!-- adr:end -->
"""

NAV_SECTION = (
    '  { "Decisions" = [\n'
    '    { "Overview" = "decisions/index.md" },\n'
    "    # >>> decisions\n"
    "    # <<< decisions\n"
    "  ] },\n"
)


def ensure_index() -> None:
    page = DOCS / "index.md"
    if page.exists():
        print("index exists")
        return
    DOCS.mkdir(parents=True, exist_ok=True)
    page.write_text(INDEX)
    print(f"scaffolded {page}")


def ensure_nav_section() -> None:
    toml = TOML.read_text()
    if "# >>> decisions" in toml:
        print("nav section exists")
        return
    # Decisions sits with the other working sections. Anchor after Bugs, falling back
    # through Plans and Reminders to Daily so this works on a library missing the later ones.
    for anchor in (
        r'(\{ "Bugs" = \[.*?\n  \] \},\n)',
        r'(\{ "Plans" = \[.*?\n  \] \},\n)',
        r'(\{ "Reminders" = \[.*?\n  \] \},\n)',
        r'(\{ "Daily" = \[.*?\n  \] \},\n)',
    ):
        m = re.search(anchor, toml, flags=re.S)
        if m:
            TOML.write_text(toml[: m.end(1)] + NAV_SECTION + toml[m.end(1) :])
            print("nav section added")
            return
    raise SystemExit("could not find a Bugs, Plans, Reminders or Daily nav block to anchor Decisions after")


def next_number() -> str:
    used = [
        int(m.group(1))
        for p in DOCS.glob("[0-9][0-9][0-9][0-9]-*.md")
        if (m := re.match(r"(\d{4})-", p.name))
    ]
    return f"{max(used, default=0) + 1:04d}"


def ensure_adr(slug: str, title: str, date: str) -> None:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", slug):
        raise SystemExit(f"bad slug {slug!r} — kebab-case, e.g. alloy-kafka-split")
    existing = list(DOCS.glob(f"[0-9][0-9][0-9][0-9]-{slug}.md"))
    if existing:
        num = existing[0].name[:4]
        print(f"ADR exists: {existing[0]}")
    else:
        num = next_number()
        DOCS.mkdir(parents=True, exist_ok=True)
        page = DOCS / f"{num}-{slug}.md"
        page.write_text(ADR.format(num=num, title=title, date=date))
        print(f"scaffolded {page}")

    toml = TOML.read_text()
    block = re.search(r"( *# >>> decisions\n)(.*?)( *# <<< decisions\n)", toml, flags=re.S)
    if not block:
        raise SystemExit("no '# >>> decisions' nav block — run ensure_decisions.py (no args) first")
    if f'"decisions/{num}-{slug}.md"' in block.group(2):
        print("nav row exists")
        return
    rows = [line + "\n" for line in block.group(2).splitlines() if line.strip()]
    rows.append(f'    {{ "{num} · {title}" = "decisions/{num}-{slug}.md" }},\n')
    rows.sort()  # zero-padded numbers lead each row, so plain sort is numeric order
    TOML.write_text(toml[: block.end(1)] + "".join(rows) + toml[block.start(3) :])
    print(f"nav row added: {num} · {title}")


def main() -> None:
    ensure_index()
    ensure_nav_section()
    if len(sys.argv) == 2 and sys.argv[1] == "next":
        print(next_number())
    elif len(sys.argv) == 5 and sys.argv[1] == "new":
        ensure_adr(sys.argv[2], sys.argv[3], sys.argv[4])
    elif len(sys.argv) != 1:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
