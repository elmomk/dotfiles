#!/usr/bin/env python3
"""Idempotent scaffold for the Bugs section of the teach-me library.

  ensure_bugs.py                             -> overview page + Bugs nav section
  ensure_bugs.py system <slug> <Title>       -> per-system page + nav row (alphabetized)

Bugs are grouped one page per system under docs/bugs/; index.md only holds the
rollup (TL;DR + severity counts + system list), never entries.

Why per-system pages rather than a page per bug (unlike /publish-plan): a bug is a
finding you scan in a list — symptom, evidence, fix — not a document you read
top-to-bottom. Bugs also cluster by the thing that's broken, so the system page is
what you actually open when that system misbehaves again.
"""
import pathlib
import re
import sys

LIB = pathlib.Path.home() / "teach-me/library"
DOCS = LIB / "docs/bugs"
TOML = LIB / "zensical.toml"

INDEX = """---
icon: lucide/bug
---

# Bugs

!!! abstract "TL;DR"
    No open bugs

Defects found while investigating something else — the ones that would otherwise
evaporate when the session ends. Each system has its own page (left nav); entries carry
the symptom, the shortest decisive evidence, the mechanism, blast radius, and the fix.
Filed by the `/buggy` skill; entries move to their page's Fixed list when closed.

Severity is about consequence, not effort:

| | Meaning |
| --- | --- |
| :material-fire: **P1** | Breaks work for someone right now, or fails in a way nothing catches |
| :material-alert: **P2** | Silently wrong or degraded — the system lies rather than stops |
| :material-information-outline: **P3** | Noise, latent risk, or wasted effort; no user impact today |

## Systems

<!-- systems:start -->
<!-- systems:end -->
"""

SYSTEM = """---
icon: lucide/bug
---

# {title}

!!! abstract "TL;DR"
    No open bugs

<!-- bugs:start -->
<!-- bugs:end -->

## Fixed

<!-- fixed:start -->
<!-- fixed:end -->
"""

NAV_SECTION = (
    '  { "Bugs" = [\n'
    '    { "Overview" = "bugs/index.md" },\n'
    "    # >>> bugs\n"
    "    # <<< bugs\n"
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
    if "# >>> bugs" in toml:
        print("nav section exists")
        return
    # Bugs sits with the other working sections. Anchor after Plans, falling back
    # through Reminders to Daily so this works on a library missing the later ones.
    for anchor in (
        r'(\{ "Plans" = \[.*?\n  \] \},\n)',
        r'(\{ "Reminders" = \[.*?\n  \] \},\n)',
        r'(\{ "Daily" = \[.*?\n  \] \},\n)',
    ):
        m = re.search(anchor, toml, flags=re.S)
        if m:
            TOML.write_text(toml[: m.end(1)] + NAV_SECTION + toml[m.end(1) :])
            print("nav section added")
            return
    raise SystemExit("could not find a Plans, Reminders or Daily nav block to anchor Bugs after")


def ensure_system(slug: str, title: str) -> None:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", slug):
        raise SystemExit(f"bad slug {slug!r} — kebab-case, e.g. litellm-proxy")
    page = DOCS / f"{slug}.md"
    if page.exists():
        print("system page exists")
    else:
        DOCS.mkdir(parents=True, exist_ok=True)
        page.write_text(SYSTEM.format(title=title))
        print(f"scaffolded {page}")

    toml = TOML.read_text()
    block = re.search(r"( *# >>> bugs\n)(.*?)( *# <<< bugs\n)", toml, flags=re.S)
    if not block:
        raise SystemExit("no '# >>> bugs' nav block — run ensure_bugs.py (no args) first")
    if f'"bugs/{slug}.md"' in block.group(2):
        print("nav row exists")
        return
    rows = [line + "\n" for line in block.group(2).splitlines() if line.strip()]
    rows.append(f'    {{ "{title}" = "bugs/{slug}.md" }},\n')
    rows.sort(key=str.lower)  # rows differ only from the title on — alphabetical by title
    TOML.write_text(toml[: block.end(1)] + "".join(rows) + toml[block.start(3) :])
    print(f"nav row added: {title}")


def main() -> None:
    ensure_index()
    ensure_nav_section()
    if len(sys.argv) == 4 and sys.argv[1] == "system":
        ensure_system(sys.argv[2], sys.argv[3])
    elif len(sys.argv) != 1:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
