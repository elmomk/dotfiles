#!/usr/bin/env python3
"""Idempotent scaffold for the Designs section of the teach-me library.

  ensure_designs.py                          -> overview page + Designs nav section
  ensure_designs.py new <slug> <Title> <YYYY-MM-DD>
                                             -> design page + nav row (alphabetical)

One page per design under docs/designs/, keyed by slug; index.md holds only the rollup
table, never bodies.

Why slug-keyed and not numbered (unlike /adr): a design page is LIVE. Re-running
/draw-design on the same slug rewrites it from current reality, so the page always shows
the design as it stands rather than as it was first drawn. An ADR is the opposite — it is
immutable and numbered, because its value is the reasoning at a point in time. Cite the
ADR for why, link the design for what.
"""
import pathlib
import re
import sys

LIB = pathlib.Path.home() / "teach-me/library"
DOCS = LIB / "docs/designs"
TOML = LIB / "zensical.toml"

INDEX = """---
icon: lucide/network
---

# Designs

!!! abstract "TL;DR"
    No designs drawn yet

Drawn designs — one page per design, diagram first, prose second. Each page carries the
whole design as a single mermaid diagram, a short walk through it, what it changes against
what exists today, and an explicit split between what was **verified** and what is still
**assumed**. Filed by the `/draw-design` skill.

These pages are live. Re-running the skill on the same design rewrites the page from
current reality rather than appending, so what you are reading is the design as it stands.
The reasoning behind a specific call belongs in a numbered ADR, which never changes; a
design page links to it.

| Status | Meaning |
| --- | --- |
| :material-pencil-outline: **Draft** | Being drawn; shape still moving |
| :material-lightbulb-outline: **Proposed** | Drawn and coherent, waiting on a decision or an answer |
| :material-check-decagram: **Agreed** | Build against this |
| :material-hammer-wrench: **Building** | Partly real; the diagram marks which edges exist |
| :material-file-replace-outline: **Superseded** | Replaced — the newer design is linked from the header |

## The designs

<!-- designs:start -->
<!-- designs:end -->
"""

DESIGN = """---
icon: lucide/network
---

# {title}

<!-- ts:start -->
*Drawn {date}*
<!-- ts:end -->

| Field | Value |
| --- | --- |
| **Status** | :material-pencil-outline: Draft |
| **Area** | |
| **Drawn** | {date} |
| **Tracking** | |
| **Decisions** | |

!!! abstract "TL;DR"
    <the design in 1-3 sentences — what the shape is, not why>

<!-- design:start -->

## The design

## How to read it

## The flow

## What it changes

## Verified vs assumed

## Open questions

<!-- design:end -->
"""

NAV_SECTION = (
    '  { "Designs" = [\n'
    '    { "Overview" = "designs/index.md" },\n'
    "    # >>> designs\n"
    "    # <<< designs\n"
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
    if "# >>> designs" in toml:
        print("nav section exists")
        return
    # Designs sits with the other working sections. Anchor after Decisions, falling back
    # through Bugs and Plans to Daily so this works on a library missing the later ones.
    for anchor in (
        r'(\{ "Decisions" = \[.*?\n  \] \},\n)',
        r'(\{ "Bugs" = \[.*?\n  \] \},\n)',
        r'(\{ "Plans" = \[.*?\n  \] \},\n)',
        r'(\{ "Daily" = \[.*?\n  \] \},\n)',
    ):
        m = re.search(anchor, toml, flags=re.S)
        if m:
            TOML.write_text(toml[: m.end(1)] + NAV_SECTION + toml[m.end(1) :])
            print("nav section added")
            return
    raise SystemExit("could not find a Decisions, Bugs, Plans or Daily nav block to anchor Designs after")


def ensure_design(slug: str, title: str, date: str) -> None:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", slug):
        raise SystemExit(f"bad slug {slug!r} — kebab-case, e.g. alloy-otlp-gateway")
    page = DOCS / f"{slug}.md"
    if page.exists():
        # Live page: leave the body alone, the skill rewrites it in place.
        print(f"design exists: {page}")
    else:
        DOCS.mkdir(parents=True, exist_ok=True)
        page.write_text(DESIGN.format(title=title, date=date))
        print(f"scaffolded {page}")

    toml = TOML.read_text()
    block = re.search(r"( *# >>> designs\n)(.*?)( *# <<< designs\n)", toml, flags=re.S)
    if not block:
        raise SystemExit("no '# >>> designs' nav block — run ensure_designs.py (no args) first")
    if f'"designs/{slug}.md"' in block.group(2):
        print("nav row exists")
        return
    rows = [line + "\n" for line in block.group(2).splitlines() if line.strip()]
    rows.append(f'    {{ "{title}" = "designs/{slug}.md" }},\n')
    rows.sort()
    TOML.write_text(toml[: block.end(1)] + "".join(rows) + toml[block.start(3) :])
    print(f"nav row added: {title}")


def main() -> None:
    ensure_index()
    ensure_nav_section()
    if len(sys.argv) == 5 and sys.argv[1] == "new":
        ensure_design(sys.argv[2], sys.argv[3], sys.argv[4])
    elif len(sys.argv) != 1:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
