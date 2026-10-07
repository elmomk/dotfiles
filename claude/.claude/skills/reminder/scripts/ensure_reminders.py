#!/usr/bin/env python3
"""Idempotent scaffold for the Reminders section of the teach-me library.

  ensure_reminders.py                       -> overview page + Reminders nav section
  ensure_reminders.py topic <slug> <Title>  -> per-topic page + nav row (alphabetized)

Reminders are grouped one page per topic under docs/reminders/; index.md only
holds the rollup (TL;DR + topic list), never entries.
"""
import pathlib
import re
import sys

LIB = pathlib.Path.home() / "teach-me/library"
DOCS = LIB / "docs/reminders"
TOML = LIB / "zensical.toml"

INDEX = """---
icon: lucide/alarm-clock
---

# Reminders

!!! abstract "TL;DR"
    No open reminders 🎉

Work that still needs to happen, parked so any future session can pick it up cold. Each
topic has its own page (left nav); entries say what's left, the context a cold start
needs, and the first step. Filed by the `/reminder` skill; entries move to their page's
Done list when closed.

## Topics

<!-- topics:start -->
<!-- topics:end -->
"""

TOPIC = """---
icon: lucide/alarm-clock
---

# {title}

!!! abstract "TL;DR"
    No open reminders 🎉

<!-- reminders:start -->
<!-- reminders:end -->

## Done

<!-- done:start -->
<!-- done:end -->
"""

NAV_SECTION = (
    '  { "Reminders" = [\n'
    '    { "Overview" = "reminders/index.md" },\n'
    "    # >>> reminders\n"
    "    # <<< reminders\n"
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
    if "# >>> reminders" in toml:
        print("nav section exists")
        return
    old = '  { "Reminders" = "reminders/index.md" },\n'
    if old in toml:  # migrate the pre-topics single-page form
        TOML.write_text(toml.replace(old, NAV_SECTION, 1))
        print("nav migrated to section form")
        return
    m = re.search(r'(\{ "Daily" = \[.*?\n  \] \},\n)', toml, flags=re.S)
    if not m:
        raise SystemExit("could not find the Daily nav block to anchor Reminders after")
    TOML.write_text(toml[: m.end(1)] + NAV_SECTION + toml[m.end(1) :])
    print("nav section added after Daily")


def ensure_topic(slug: str, title: str) -> None:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", slug):
        raise SystemExit(f"bad slug {slug!r} — kebab-case, e.g. scrum-suite")
    page = DOCS / f"{slug}.md"
    if page.exists():
        print("topic page exists")
    else:
        page.write_text(TOPIC.format(title=title))
        print(f"scaffolded {page}")

    toml = TOML.read_text()
    block = re.search(r"( *# >>> reminders\n)(.*?)( *# <<< reminders\n)", toml, flags=re.S)
    if not block:
        raise SystemExit("no '# >>> reminders' nav block — run ensure_reminders.py (no args) first")
    if f'"reminders/{slug}.md"' in block.group(2):
        print("nav row exists")
        return
    rows = [line + "\n" for line in block.group(2).splitlines() if line.strip()]
    rows.append(f'    {{ "{title}" = "reminders/{slug}.md" }},\n')
    rows.sort(key=str.lower)  # rows differ only from the title on — alphabetical by title
    TOML.write_text(toml[: block.end(1)] + "".join(rows) + toml[block.start(3) :])
    print(f"nav row added: {title}")


def main() -> None:
    ensure_index()
    ensure_nav_section()
    if len(sys.argv) == 4 and sys.argv[1] == "topic":
        ensure_topic(sys.argv[2], sys.argv[3])
    elif len(sys.argv) != 1:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
