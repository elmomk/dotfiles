#!/usr/bin/env python3
"""Idempotent scaffold for the WIP section of the teach-me library.

  ensure_wip.py                          -> overview page + WIP nav section
  ensure_wip.py page <slug> <Title>      -> WIP page + nav row

One page per in-flight work stream, under docs/wip/. Flat — no subcategories.
WIP pages are few and short-lived, so the nav-cat machinery Plans needs would
just be ceremony here.

Why this is separate from Plans: a plan is the *route* (stage order, gates,
hazards, rollback) and it survives the work. A WIP page is the *resume point* —
where the work actually stopped, the exact commands to pick it back up, and what
was left in a temporary state. It is deleted when the work lands, not superseded.
"""
import pathlib
import re
import sys

LIB = pathlib.Path.home() / "teach-me/library"
DOCS = LIB / "docs/wip"
TOML = LIB / "zensical.toml"

INDEX = """---
icon: lucide/hammer
---

# WIP

!!! abstract "TL;DR"
    Nothing in flight.

Work that is **half-done right now**: where it stopped, the exact command to resume
it, and anything left in a temporary state that someone has to put back. Filed by the
`/wip` skill.

Distinct from [Plans](../plans/index.md): a plan is the route to done and it outlives
the work. A WIP page is a handoff note to your future self — it assumes the work is
mid-flight and optimises for restarting cold. When the work lands, the page goes away.

If you are picking something up after a break, read the **Resume here** row first, then
**Left in a temporary state**. Those two together are the whole point of the page.

## In flight

<!-- wip:start -->
<!-- wip:end -->
"""

PAGE = """---
icon: lucide/hammer
---

# {title}

!!! abstract "TL;DR"
    _one line: what is half-done, and the single command that resumes it_

| Field | Value |
| --- | --- |
| **Status** | In flight |
| **Updated** | {date} |
| **Resume here** | _the exact next command_ |
| **Waiting on** | _who/what, or nothing_ |

<!-- wip:start -->

## Resume in one paste

_Paste this whole block into a fresh session to restore context._

```text
(what the work is, where it stopped, what is verified vs assumed,
 the next concrete step, and anything left in a temporary state)
```

## Run this next

```bash
# self-contained: absolute paths, env included, safe to paste cold
```

## Left in a temporary state

_Anything a person has to put back. Empty is a valid answer — say so explicitly._

## Ready-to-paste comments

??? note "MR / ticket update"
    ```text
    (the comment text, ready to paste — no placeholders left in it)
    ```

## Done means

_Falsifiable exit criteria. When these hold, delete this page._

<!-- wip:end -->
"""

NAV_SECTION = (
    '  { "WIP" = [\n'
    '    { "Overview" = "wip/index.md" },\n'
    "    # >>> wip\n"
    "    # <<< wip\n"
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
    if "# >>> wip" in toml:
        print("nav section exists")
        return
    # WIP sits immediately after Plans — the two are read together, plan first for
    # the route, WIP for where it actually stopped. Fall back to Reminders, then
    # Daily, if the library predates Plans.
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
    raise SystemExit("could not find a Plans, Reminders or Daily nav block to anchor WIP after")


def _nav_block(toml: str):
    b = re.search(r"( *# >>> wip\n)(.*?)( *# <<< wip\n)", toml, flags=re.S)
    if not b:
        raise SystemExit("no '# >>> wip' nav block — run ensure_wip.py (no args) first")
    return b


def ensure_page(slug: str, title: str) -> None:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", slug):
        raise SystemExit(f"bad slug {slug!r} — kebab-case, e.g. saas-migration-selfservice")
    from datetime import date

    toml = TOML.read_text()
    b = _nav_block(toml)

    page = DOCS / f"{slug}.md"
    if page.exists():
        print("wip page exists")
    else:
        DOCS.mkdir(parents=True, exist_ok=True)
        page.write_text(PAGE.format(title=title, date=date.today().isoformat()))
        print(f"scaffolded {page}")

    if f'"wip/{slug}.md"' in b.group(2):
        print("nav row exists")
        return
    rows = [line + "\n" for line in b.group(2).splitlines() if line.strip()]
    rows.append(f'    {{ "{title}" = "wip/{slug}.md" }},\n')
    rows.sort(key=str.lower)
    TOML.write_text(toml[: b.end(1)] + "".join(rows) + toml[b.start(3) :])
    print(f"nav row added: {title}")


def main() -> None:
    ensure_index()
    ensure_nav_section()
    a = sys.argv[1:]
    if len(a) == 3 and a[0] == "page":
        ensure_page(a[1], a[2])
    elif a:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
