#!/usr/bin/env python3
"""Idempotent scaffold for the Plans section of the teach-me library.

  ensure_plans.py                                  -> overview page + Plans nav section
  ensure_plans.py cat <slug> <Title>               -> a subcategory (nav-cat group)
  ensure_plans.py plan <cat-slug> <slug> <Title>   -> plan page + nav row under that cat

Plans are one page each under docs/plans/, grouped in the nav by subcategory —
the `# nav-cat` idiom Tutorials uses. index.md holds only the rollup, never a plan.

Why a whole page per plan (unlike /reminder, which is an entry per topic page): a
plan is a document you read top-to-bottom — stages, hazards, verification, rollback
— not a list item. The subcategory is what keeps the nav navigable as they pile up.
"""
import pathlib
import re
import sys

LIB = pathlib.Path.home() / "teach-me/library"
DOCS = LIB / "docs/plans"
TOML = LIB / "zensical.toml"

INDEX = """---
icon: lucide/map
---

# Plans

!!! abstract "TL;DR"
    No active plans.

How a piece of work gets from where it is to done: the stage order and why it's that
order, what gates each stage, the hazards worth naming up front, and what "done" means
per stage. Grouped by area in the left nav. Filed by the `/publish-plan` skill.

A plan here is **live** — it gets rewritten when reality moves, and superseded plans say
so at the top rather than being deleted.

## Plans

<!-- plans:start -->
<!-- plans:end -->
"""

PLAN = """---
icon: lucide/map
---

# {title}

!!! abstract "TL;DR"
    _one line: what this plan gets you, and where it currently stands_

| Field | Value |
| --- | --- |
| **Status** | Draft |
| **Updated** | {date} |
| **Next action** | _the single next thing_ |
| **Blocked on** | _who/what, or nothing_ |

<!-- plan:start -->
<!-- plan:end -->
"""

NAV_SECTION = (
    '  { "Plans" = [\n'
    '    { "Overview" = "plans/index.md" },\n'
    "    # >>> plans\n"
    "    # <<< plans\n"
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
    if "# >>> plans" in toml:
        print("nav section exists")
        return
    # Anchor after the Reminders section (Plans sits with the other working sections,
    # before Bundles). Fall back to Daily if Reminders isn't installed yet.
    for anchor in (r'(\{ "Reminders" = \[.*?\n  \] \},\n)', r'(\{ "Daily" = \[.*?\n  \] \},\n)'):
        m = re.search(anchor, toml, flags=re.S)
        if m:
            TOML.write_text(toml[: m.end(1)] + NAV_SECTION + toml[m.end(1) :])
            print("nav section added")
            return
    raise SystemExit("could not find a Reminders or Daily nav block to anchor Plans after")


def _nav_block(toml: str):
    b = re.search(r"( *# >>> plans\n)(.*?)( *# <<< plans\n)", toml, flags=re.S)
    if not b:
        raise SystemExit("no '# >>> plans' nav block — run ensure_plans.py (no args) first")
    return b


def _check_slug(slug: str, what: str) -> None:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", slug):
        raise SystemExit(f"bad {what} {slug!r} — kebab-case, e.g. pe-2333-v251-rollout")


# One nav-cat group, open marker → close marker. `(?:.*\n)*?` so an EMPTY group
# (freshly created, no plans yet) still matches — an earlier cut required a line
# between the markers, so adding a second cat silently DROPPED the empty first one.
CAT_RE = r'( *\{ "[^"]+" = \[  # nav-cat  # cat:%s\n)((?:.*\n)*?)( *\] \},  # /nav-cat\n)'


def ensure_cat(slug: str, title: str) -> None:
    """A subcategory is nav-only (a nav-cat group); it has no page of its own."""
    _check_slug(slug, "cat slug")
    toml = TOML.read_text()
    b = _nav_block(toml)
    if f"# cat:{slug}\n" in b.group(2):
        print("cat exists")
        return
    cat = f'    {{ "{title}" = [  # nav-cat  # cat:{slug}\n    ] }},  # /nav-cat\n'
    cats = re.findall(CAT_RE % "[a-z0-9-]+", b.group(2))
    cats = ["".join(c) for c in cats]
    cats.append(cat)
    cats.sort(key=lambda c: re.search(r'"([^"]+)"', c).group(1).lower())
    TOML.write_text(toml[: b.end(1)] + "".join(cats) + toml[b.start(3) :])
    print(f"cat added: {title}")


def ensure_plan(cat_slug: str, slug: str, title: str) -> None:
    _check_slug(cat_slug, "cat slug")
    _check_slug(slug, "plan slug")
    from datetime import date

    # Validate the cat BEFORE scaffolding — bailing after the write left an orphan
    # page with no nav row pointing at it.
    toml = TOML.read_text()
    b = _nav_block(toml)
    m = re.search(CAT_RE % re.escape(cat_slug), b.group(2))
    if not m:
        raise SystemExit(f"no cat {cat_slug!r} — run: ensure_plans.py cat {cat_slug} '<Title>'")

    page = DOCS / f"{slug}.md"
    if page.exists():
        print("plan page exists")
    else:
        DOCS.mkdir(parents=True, exist_ok=True)
        page.write_text(PLAN.format(title=title, date=date.today().isoformat()))
        print(f"scaffolded {page}")

    if f'"plans/{slug}.md"' in m.group(2):
        print("nav row exists")
        return
    rows = [line + "\n" for line in m.group(2).splitlines() if line.strip()]
    rows.append(f'        {{ "{title}" = "plans/{slug}.md" }},\n')
    rows.sort(key=str.lower)
    inner = m.group(1) + "".join(rows) + m.group(3)
    block = b.group(2)[: m.start()] + inner + b.group(2)[m.end() :]
    TOML.write_text(toml[: b.end(1)] + block + toml[b.start(3) :])
    print(f"nav row added: {title} (under {cat_slug})")


def main() -> None:
    ensure_index()
    ensure_nav_section()
    a = sys.argv[1:]
    if len(a) == 3 and a[0] == "cat":
        ensure_cat(a[1], a[2])
    elif len(a) == 4 and a[0] == "plan":
        ensure_plan(a[1], a[2], a[3])
    elif a:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
