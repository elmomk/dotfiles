#!/usr/bin/env python3
"""Idempotent scaffold for the Reports section of the teach-me library.

  ensure_reports.py                                       -> overview page + Reports nav section
  ensure_reports.py report <slug> <Title> <YYYY-MM-DD>    -> standalone report page + nav row
  ensure_reports.py programme <slug> <Title> <YYYY-MM-DD> -> programme index page + nav group
  ensure_reports.py leg <prog-slug> <leg-slug> <Title> <YYYY-MM-DD>
                                                          -> leg page + nav row inside that programme
  ensure_reports.py retire <slug>                         -> drop from the nav, move pages out of docs/

Investigation reports live under docs/reports/, in two shapes, because
investigations come in two shapes:

  - a STANDALONE investigation is one page, docs/reports/<slug>.md;
  - a PROGRAMME is one question chased down several legs at once, so it gets a
    directory: docs/reports/<slug>/index.md plus one page per leg. Legs share
    findings and contradict each other in places, and the programme index is the
    only page that can reconcile that, because no single leg saw the others'
    evidence.

index.md holds the rollup only, never a report body — same rule as /buggy's index.

Why not fold this into /aar or /buggy: an AAR reviews one incident that already
happened; a bug page lists defects in one system. An investigation report carries
what was MEASURED, what is still ASSUMED, and what was BELIEVED and then overturned.
The retractions are the expensive half of the work and neither of the other two
shapes has anywhere to put them.

Top-level nav rows are ordered newest first — an investigation is dated, and the
newest is the one people are reading — so every top-level row carries a `# date:`
marker for the sort. Legs inside a programme keep the order they were added: leg
order is the investigator's narrative, not something to alphabetize.
"""
import pathlib
import re
import sys

LIB = pathlib.Path.home() / "teach-me/library"
DOCS = LIB / "docs/reports"
TOML = LIB / "zensical.toml"

INDEX = """---
icon: lucide/microscope
---

# Reports

!!! abstract "TL;DR"
    No investigations published yet

Technical investigations — the multi-day, multi-agent kind, where the answer arrives in
pieces and several of the pieces turn out to be wrong. A standalone investigation is one
page; a programme chased down several legs gets a page per leg and an index that
reconciles them. Filed by the `/report` skill.

Every report here carries three things a status update does not:

| | Why it is on the page |
| --- | --- |
| :material-check-decagram: **Verified vs assumed** | Each claim says which it is. An unmeasured thing is named as unmeasured |
| :material-close-octagon-outline: **Believed, then overturned** | Retractions are kept, never deleted — the claim, and the measurement that killed it |
| :material-flask-outline: **Method** | How each thing was measured, including the positive control |

An absence proves nothing on its own. "X is absent" earns its place only beside "and the
same query returns Y, which I know exists" — so the method section is where a reader
decides how much of the answer to trust.

## The reports

<!-- reports:start -->
<!-- reports:end -->
"""

# Standalone report and programme leg share one template: a leg is a standalone
# investigation that happens to have siblings, and the only structural difference
# is the row pointing back at the programme.
REPORT = """---
icon: lucide/microscope
---

# {title}

<!-- ts:start -->
*Investigated {date}*
<!-- ts:end -->

| Field | Value |
| --- | --- |
| **Question** | _the one question this had to answer_ |
| **Status** | :material-progress-clock: In progress |
| **Investigated** | {date} |
| **Investigators** | |{parent}
| **Confidence** | _what the answer is worth, in one clause_ |

!!! abstract "TL;DR"
    _the answer in 1-3 sentences: what is true, not what was done_

<!-- report:start -->

## What we set out to answer

_the question as it was actually asked, and what turns on the answer_

## The answer

_what is true, stated so a cold reader can act on it_

## Verified vs assumed

| Claim | Standing | Basis, or what would settle it |
| --- | --- | --- |
| _claim_ | :material-check-decagram: Verified | _how it was measured_ |
| _claim_ | :material-help-circle-outline: Assumed | _the check that would settle it, and who can run it_ |

## What was believed, and what overturned it

_one block per retraction; keep them, they are the expensive half_

## Method

| Question | How it was measured | Positive control |
| --- | --- | --- |
| _question_ | _the command or query_ | _the known-present thing the same check returned_ |

## Open questions

- _what is still unmeasured, and who could measure it_

<!-- report:end -->
"""

PARENT_ROW = '\n| **Programme** | [{title}](index.md) |'

PROGRAMME = """---
icon: lucide/microscope
---

# {title}

<!-- ts:start -->
*Opened {date}*
<!-- ts:end -->

| Field | Value |
| --- | --- |
| **Question** | _the one question the programme has to answer_ |
| **Status** | :material-progress-clock: In progress |
| **Opened** | {date} |
| **Legs** | _see the table below_ |
| **Confidence** | _what the combined answer is worth, in one clause_ |

!!! abstract "TL;DR"
    _the programme's answer so far, in 1-3 sentences_

<!-- programme:start -->

## The legs

| Leg | Question it owns | Status | Headline finding |
| --- | --- | --- | --- |
| _[Leg](leg-slug.md)_ | _its question_ | :material-progress-clock: In progress | _one line_ |

## Where the legs agree

_findings more than one leg reached independently — say which legs, since agreement
between two legs sharing one source is not agreement_

## Where the legs contradict each other

_the contradiction, which leg holds which side, and what would resolve it. A programme
index that shows no contradictions either had none or did not look_

## Verified vs assumed, across legs

| Claim | Leg | Standing | Basis, or what would settle it |
| --- | --- | --- | --- |
| _claim_ | _leg_ | :material-check-decagram: Verified | _how it was measured_ |

## What was believed, and what overturned it

_retractions that crossed legs, or that the programme owes as a whole_

## Method

_what is shared across the legs: the environment, the access, the tooling, and the
positive controls every leg relied on_

## Open questions

- _what is still unmeasured, and who could measure it_

<!-- programme:end -->
"""

NAV_SECTION = (
    '  { "Reports" = [\n'
    '    { "Overview" = "reports/index.md" },\n'
    "    # >>> reports\n"
    "    # <<< reports\n"
    "  ] },\n"
)

# One programme group in the nav, open marker line -> close marker line. The inner
# `(?:.*\n)*?` (rather than requiring a line) so a group that has lost its rows still
# matches — publish-plan's cut of this idiom silently dropped an empty group.
PROG_RE = r'( *\{ "[^"]+" = \[  # nav-prog  # prog:%s[^\n]*\n)((?:.*\n)*?)( *\] \},  # /nav-prog\n)'

DATE_RE = re.compile(r"# date:(\d{4}-\d{2}-\d{2})")
TITLE_RE = re.compile(r'"([^"]+)"')


def _check_slug(slug: str, what: str) -> None:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", slug):
        raise SystemExit(f"bad {what} {slug!r} — kebab-case, e.g. gmp-platform-exit")


def _check_date(date: str) -> None:
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", date):
        raise SystemExit(f"bad date {date!r} — YYYY-MM-DD")


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
    if "# >>> reports" in toml:
        print("nav section exists")
        return
    # Reports sits with the other written-artifact sections. Anchor after Designs,
    # falling back through the older siblings so this works on a library missing them.
    for anchor in (
        r'(\{ "Designs" = \[.*?\n  \] \},\n)',
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
    raise SystemExit("no Designs, Decisions, Bugs, Plans or Daily nav block to anchor Reports after")


def _nav_block(toml: str):
    b = re.search(r"( *# >>> reports\n)(.*?)( *# <<< reports\n)", toml, flags=re.S)
    if not b:
        raise SystemExit("no '# >>> reports' nav block — run ensure_reports.py (no args) first")
    return b


def _split_entries(body: str):
    """Top-level entries of the Reports nav block.

    A standalone report is one line; a programme is a `# nav-prog` group spanning
    several. Splitting them keeps the newest-first sort from shredding a group.
    """
    entries, buf = [], []
    for line in body.splitlines(keepends=True):
        if not line.strip():
            continue
        buf.append(line)
        if "# nav-prog" in buf[0] and "# /nav-prog" not in line:
            continue  # still inside the group
        entries.append("".join(buf))
        buf = []
    if buf:  # unterminated group — keep it rather than dropping the pages it names
        entries.append("".join(buf))
    return entries


def _entry_date(entry: str) -> str:
    m = DATE_RE.search(entry.splitlines()[0])
    return m.group(1) if m else "0000-00-00"  # undated hand-added rows sort last


def _entry_title(entry: str) -> str:
    m = TITLE_RE.search(entry)
    return m.group(1).lower() if m else ""


def _sorted(entries):
    """Newest first, then by title — two stable passes."""
    entries.sort(key=_entry_title)
    entries.sort(key=_entry_date, reverse=True)
    return entries


def _add_top_level(entry: str, present: str) -> None:
    """Insert a top-level nav entry (row or group), keeping the block newest-first."""
    toml = TOML.read_text()
    b = _nav_block(toml)
    if re.search(present, b.group(2)):
        print("nav entry exists")
        return
    entries = _sorted(_split_entries(b.group(2)) + [entry])
    TOML.write_text(toml[: b.end(1)] + "".join(entries) + toml[b.start(3) :])
    print("nav entry added")


def ensure_report(slug: str, title: str, date: str) -> None:
    _check_slug(slug, "report slug")
    _check_date(date)
    if (DOCS / slug).is_dir():
        raise SystemExit(f"{slug!r} is already a programme — add a leg instead of a standalone page")
    page = DOCS / f"{slug}.md"
    if page.exists():
        print("report page exists")
    else:
        DOCS.mkdir(parents=True, exist_ok=True)
        page.write_text(REPORT.format(title=title, date=date, parent=""))
        print(f"scaffolded {page}")
    _add_top_level(
        f'    {{ "{title}" = "reports/{slug}.md" }},  # date:{date}\n',
        re.escape(f'"reports/{slug}.md"'),
    )


def ensure_programme(slug: str, title: str, date: str) -> None:
    _check_slug(slug, "programme slug")
    _check_date(date)
    if (DOCS / f"{slug}.md").exists():
        raise SystemExit(f"{slug!r} is already a standalone report — pick another slug")
    page = DOCS / slug / "index.md"
    if page.exists():
        print("programme index exists")
    else:
        page.parent.mkdir(parents=True, exist_ok=True)
        page.write_text(PROGRAMME.format(title=title, date=date))
        print(f"scaffolded {page}")
    group = (
        f'    {{ "{title}" = [  # nav-prog  # prog:{slug}  # date:{date}\n'
        f'        "reports/{slug}/index.md",\n'
        f"    ] }},  # /nav-prog\n"
    )
    _add_top_level(group, rf"# prog:{re.escape(slug)}(?![\w-])")


def ensure_leg(prog: str, slug: str, title: str, date: str) -> None:
    _check_slug(prog, "programme slug")
    _check_slug(slug, "leg slug")
    _check_date(date)

    # Validate the programme BEFORE scaffolding — bailing after the write leaves an
    # orphan page with no nav row pointing at it, which is a page nobody can reach.
    toml = TOML.read_text()
    b = _nav_block(toml)
    m = re.search(PROG_RE % re.escape(prog), b.group(2))
    if not m:
        raise SystemExit(f"no programme {prog!r} — run: ensure_reports.py programme {prog} '<Title>' {date}")
    if not (DOCS / prog / "index.md").exists():
        raise SystemExit(f"programme {prog!r} is in the nav but docs/reports/{prog}/index.md is missing")

    page = DOCS / prog / f"{slug}.md"
    if page.exists():
        print("leg page exists")
    else:
        prog_title = TITLE_RE.search(m.group(1)).group(1)
        page.write_text(REPORT.format(title=title, date=date, parent=PARENT_ROW.format(title=prog_title)))
        print(f"scaffolded {page}")

    if f'"reports/{prog}/{slug}.md"' in m.group(2):
        print("nav row exists")
        return
    # Legs keep insertion order: leg order is the narrative the investigator chose.
    rows = m.group(2) + f'        {{ "{title}" = "reports/{prog}/{slug}.md" }},\n'
    inner = m.group(1) + rows + m.group(3)
    block = b.group(2)[: m.start()] + inner + b.group(2)[m.end() :]
    TOML.write_text(toml[: b.end(1)] + block + toml[b.start(3) :])
    print(f"nav row added: {title} (under {prog})")


def retire(slug: str) -> None:
    """Take a report or programme out of the library without destroying it.

    Removes its nav entry — which is what actually makes a page invisible — and moves
    its pages out of docs/ into .retired/<slug>-<date>/, where they no longer build and
    so return 404, but are still on disk. Nothing is deleted: a fold that turned out
    wrong has to be recoverable, and `rm` in a publishing tool is a footgun.

    Refuses while any page under docs/ still links to it, because retiring a page that
    is still linked leaves a dead link rather than a clean absence.
    """
    _check_slug(slug, "slug")
    src = DOCS / slug if (DOCS / slug).is_dir() else DOCS / f"{slug}.md"
    toml = TOML.read_text()
    b = _nav_block(toml)

    entries = _split_entries(b.group(2))
    keep = [e for e in entries if f"reports/{slug}/" not in e and f'"reports/{slug}.md"' not in e]
    if len(keep) == len(entries) and not src.exists():
        raise SystemExit(f"nothing to retire: no nav entry and no page for {slug!r}")

    # Inbound-link check, excluding the pages being retired themselves.
    inbound = []
    for page in DOCS.parent.rglob("*.md"):
        if src.exists() and (page == src or src in page.parents):
            continue
        if f"{slug}/" in page.read_text() or f"{slug}.md" in page.read_text():
            inbound.append(page.relative_to(DOCS.parent).as_posix())
    if inbound:
        raise SystemExit(f"still linked from: {', '.join(sorted(inbound))} — repoint those first")

    if len(keep) != len(entries):
        TOML.write_text(toml[: b.end(1)] + "".join(keep) + toml[b.start(3) :])
        print(f"nav entry removed: {slug}")
    if src.exists():
        from datetime import date

        dest = LIB / ".retired" / f"{slug}-{date.today().isoformat()}"
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            raise SystemExit(f"{dest} already exists — move or rename it first")
        src.rename(dest)
        print(f"moved out of docs/: {src} -> {dest}")


STATUS_RE = re.compile(r"^\|\s*\*\*Status\*\*\s*\|\s*(.+?)\s*\|\s*$", re.M)
TLDR_RE = re.compile(r'!!! abstract "TL;DR"\n((?:    .*\n)+)')
VERIFIED_RE = re.compile(r":material-check-decagram: Verified")
ASSUMED_RE = re.compile(r":material-help-circle-outline:")
RETRACTED_RE = re.compile(r"^### :material-close-octagon-outline:", re.M)


def _page_facts(path: pathlib.Path) -> dict:
    """Everything the rollup needs, read from the page itself.

    Counts are DERIVED rather than transcribed. Both counts in this section's first
    published rollup were wrong because a writer copied them from a summary instead of
    counting the page; a number read from the page cannot drift from it.
    """
    text = path.read_text()
    status = STATUS_RE.search(text)
    tldr = TLDR_RE.search(text)
    summary = ""
    if tldr:
        flat = " ".join(line.strip() for line in tldr.group(1).splitlines())
        summary = flat.split(". ")[0].rstrip(".").strip()
        if len(summary) > 150:  # first sentence can run long; keep the rollup scannable
            summary = summary[:147].rsplit(" ", 1)[0] + "…"
    return {
        "status": status.group(1) if status else ":material-progress-clock: In progress",
        "summary": summary or "_no TL;DR on the page_",
        "verified": len(VERIFIED_RE.findall(text)),
        "assumed": len(ASSUMED_RE.findall(text)),
        "retracted": len(RETRACTED_RE.findall(text)),
    }


def _rollup_line(title: str, href: str, path: pathlib.Path, indent: str) -> str:
    # The title is NOT bolded: a link is already emphasis, and bolding every row pushed
    # the index past the readability gate's 10% bold ceiling as soon as titles got long.
    f = _page_facts(path)
    return (
        f"{indent}- [{title}]({href}) — {f['status']} · {f['summary']} · "
        f"{f['verified']} verified / {f['assumed']} assumed / {f['retracted']} retracted\n"
    )


def rollup() -> None:
    """Regenerate the index rollup from the nav and the pages themselves.

    This exists because the nav and the rollup carried the same information but only the
    nav was generated. On this section's first day two sessions published seconds apart:
    the second had read the rollup before the first wrote, so "read the shared block
    first" was already satisfied and the entry was still lost. The exposure is the window
    between read and write, and the only thing that closes it is writing the block from
    the nav — which the tool merges one entry at a time — rather than from a snapshot a
    writer took earlier.
    """
    toml = TOML.read_text()
    b = _nav_block(toml)
    lines = []
    for entry in _sorted(_split_entries(b.group(2))):
        head = entry.splitlines()[0]
        title = TITLE_RE.search(head).group(1)
        if "# nav-prog" in head:
            prog = re.search(r"# prog:([a-z0-9-]+)", head).group(1)
            lines.append(_rollup_line(title, f"{prog}/index.md", DOCS / prog / "index.md", ""))
            for leg in entry.splitlines()[1:]:
                m = re.search(r'\{ "([^"]+)" = "reports/([^"]+)" \}', leg)
                if m:
                    lines.append(_rollup_line(m.group(1), m.group(2), DOCS / m.group(2), "    "))
        else:
            m = re.search(r'"reports/([^"]+)"', head)
            if m:
                lines.append(_rollup_line(title, m.group(1), DOCS / m.group(1), ""))

    page = DOCS / "index.md"
    text = page.read_text()
    block = re.search(r"(<!-- reports:start -->\n)(.*?)(<!-- reports:end -->)", text, flags=re.S)
    if not block:
        raise SystemExit("no '<!-- reports:start -->' block in docs/reports/index.md")
    page.write_text(text[: block.end(1)] + "".join(lines) + text[block.start(3) :])
    print(f"rollup regenerated: {len(lines)} row(s)")


def main() -> None:
    ensure_index()
    ensure_nav_section()
    a = sys.argv[1:]
    if len(a) == 1 and a[0] == "rollup":
        rollup()
    elif len(a) == 2 and a[0] == "retire":
        retire(a[1])
    elif len(a) == 4 and a[0] == "report":
        ensure_report(a[1], a[2], a[3])
    elif len(a) == 4 and a[0] == "programme":
        ensure_programme(a[1], a[2], a[3])
    elif len(a) == 5 and a[0] == "leg":
        ensure_leg(a[1], a[2], a[3], a[4])
    elif a:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
