#!/usr/bin/env python3
"""cartoon.py — emit a date-rotating "cartoon of the day" block, fetched live.

THE PAGE IS READ AT WORK, BY COLLEAGUES, AND IS PUBLISHED TO A SHARED INTERNAL HUB.
Every source here must be safe for that audience on *every* strip it has ever run —
not merely usually. This script fetches whatever a feed published most recently and
embeds it unreviewed, so a source's worst strip is the one that matters. When in doubt
about a source, leave it out; see BANNED_HOSTS below.

Rotates through 3 ORIGINAL webcomic sources (one per day, by date ordinal % 3) and
fetches that source's *most recent* strip at runtime, so the image is hosted by the
comic's own origin — not re-hosted by an aggregator. A date's first successful pick is
cached (see CACHE_DIR), so repeated runs that day — e.g. a morning then an evening daily —
render the identical strip even if the source publishes a new one in between. Output is
delimited by <!-- cartoon:start --> / <!-- cartoon:end --> so the daily skill can replace it.

Sources (all checked live, all workplace-safe):
  - xkcd               JSON API   https://xkcd.com/info.0.json
  - turnoff.us         RSS        https://turnoff.us/feed.xml
  - Work Chronicles    RSS        https://workchronicles.com/feed/

Removed for not-safe-for-work content (2026-07-22): SMBC (smbc-comics.com) — routinely
runs sexual and crude strips, and one reached a published daily page; Poorly Drawn Lines
(poorlydrawnlines.com) — same class of risk. Both are permanently barred by BANNED_HOSTS,
which is enforced on the live pick AND on the per-date cache, so neither can return via a
new provider, a fallthrough, or a stale cache entry.

Also dropped, for being broken rather than unsafe: Dilbert (dilbert.com defunct),
CommitStrip (no new strips since 2022), Sysadminotaur (Devolutions blog exposes only
logos/marketing images, not the strip), MonkeyUser (comic image is JS-rendered — absent
from both the static HTML and the feed).

If the day's source can't be fetched, the next sources in rotation are tried, then a
static fallback. Stdlib only. Usage: cartoon.py [YYYY-MM-DD]   (default: today)
"""
import datetime as dt
import html
import json
import os
import re
import sys
import urllib.request

START, END = "<!-- cartoon:start -->", "<!-- cartoon:end -->"
UA = "Mozilla/5.0 (daily-skill cartoon fetcher)"
TIMEOUT = 15


def _get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return r.read().decode("utf-8", "replace")


def _first_item(xml):
    m = re.search(r"<item\b.*?</item>", xml, re.S | re.I)
    return m.group(0) if m else ""


def _tag(block, tag):
    m = re.search(rf"<{tag}\b[^>]*>(.*?)</{tag}>", block, re.S | re.I)
    if not m:
        return ""
    t = m.group(1).strip()
    t = re.sub(r"^<!\[CDATA\[|\]\]>$", "", t).strip()
    return html.unescape(t)


# Reject logos, avatars, icons, SVGs, and template placeholders — these are what a
# blog/feed surfaces instead of the actual strip, and rendering one looks broken.
_BAD_IMG = re.compile(
    r"(logo|/icons?/|avatar|gravatar|sprite|spacer|placeholder|headlineimagetemplate|\.svg(?:[?#]|$))",
    re.I,
)

# Hosts barred for not-safe-for-work content. This is a *permanent* bar, not a rotation
# tweak: removing a provider function alone is not enough, because a stale per-date cache
# entry or a future well-meaning re-add would bring the source straight back. Checked
# against every candidate URL — image URL, page URL and credit — on the live pick, on the
# cache read, and once more before the block is emitted.
BANNED_HOSTS = ("smbc-comics.com", "poorlydrawnlines.com")


def _is_banned(*urls):
    return any(h in (u or "").lower() for u in urls for h in BANNED_HOSTS)


def _first_image(block):
    """First plausible *comic* image URL in an RSS item / HTML chunk (origin-hosted),
    skipping logos, avatars, icons, and template placeholders."""
    b = html.unescape(block)  # content:encoded is escaped HTML
    for pat in (
        r'<meta[^>]+(?:property|name)="og:image"[^>]+content="([^"]+)"',
        r'<media:content[^>]+url="([^"]+)"',
        r'<enclosure[^>]+url="([^"]+)"[^>]*type="image',
        r'<img[^>]+src="([^"]+)"',
    ):
        for url in re.findall(pat, b, re.I):
            if url.startswith("http") and not _BAD_IMG.search(url):
                return url
    return ""


# --- providers: each returns (title, img_url, page_url, credit) or None ----------

def src_xkcd():
    d = json.loads(_get("https://xkcd.com/info.0.json"))
    return (f"xkcd #{d['num']}: {d['title']}", d["img"], f"https://xkcd.com/{d['num']}/", "xkcd.com")


def _rss_latest(feed_url, credit, page_host=""):
    item = _first_item(_get(feed_url))
    if not item:
        return None
    img = _first_image(item)
    if not img:
        return None
    title = _tag(item, "title") or credit
    link = _tag(item, "link") or feed_url
    return (title, img, link, credit)


def src_turnoff():
    return _rss_latest("https://turnoff.us/feed.xml", "turnoff.us")


def src_workchronicles():
    return _rss_latest("https://workchronicles.com/feed/", "workchronicles.com")


# Rotation order (index = date.toordinal() % len(PROVIDERS)).
PROVIDERS = [src_xkcd, src_turnoff, src_workchronicles]
FALLBACK = ("xkcd #327: Exploits of a Mom",
            "https://imgs.xkcd.com/comics/exploits_of_a_mom.png",
            "https://xkcd.com/327/", "xkcd.com")


# Per-date cache so morning/evening runs of the same date render the identical strip.
CACHE_DIR = os.path.expanduser(os.environ.get("DAILY_CARTOON_CACHE", "~/.cache/daily-cartoon"))
_FIELDS = ("title", "img", "page", "credit")


def _cache_get(date):
    try:
        with open(os.path.join(CACHE_DIR, f"{date.isoformat()}.json"), encoding="utf-8") as f:
            d = json.load(f)
        r = tuple(d[k] for k in _FIELDS)
        # Ignore an empty/stale-bad cached image, and never serve a cached pick from a
        # banned host — a cache written before the ban must not outlive it.
        if r[1] and not _BAD_IMG.search(r[1]) and not _is_banned(r[1], r[2], r[3]):
            return r
    except (OSError, ValueError, KeyError):
        pass  # missing/corrupt cache → just re-pick
    return None


def _cache_put(date, r):
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(os.path.join(CACHE_DIR, f"{date.isoformat()}.json"), "w", encoding="utf-8") as f:
            json.dump(dict(zip(_FIELDS, r)), f)
    except OSError:
        pass  # cache is best-effort; never fail the run over it


def _select(date):
    """Live source selection: today's source first, then fall through on failure.
    Returns (result, is_fallback)."""
    n = len(PROVIDERS)
    start = date.toordinal() % n
    for i in range(n):
        prov = PROVIDERS[(start + i) % n]
        try:
            r = prov()
            if r and r[1] and not _BAD_IMG.search(r[1]):  # reject logo/placeholder hits
                if _is_banned(r[1], r[2], r[3]):
                    print(f"[cartoon] {prov.__name__} returned a banned host — skipped",
                          file=sys.stderr)
                    continue
                return r, False
        except Exception as e:  # noqa: BLE001 - best-effort, try next source
            print(f"[cartoon] {prov.__name__} failed: {e}", file=sys.stderr)
    return FALLBACK, True


def pick(date):
    """Stable per-date pick: a date's first real selection is cached and reused, so a
    morning and an evening run on the same date agree. The FALLBACK is never cached, so a
    transient outage in the morning can still recover to a real comic later that day."""
    cached = _cache_get(date)
    if cached:
        return cached
    r, is_fallback = _select(date)
    if not is_fallback:
        _cache_put(date, r)
    return r


def block(date):
    title, img, page, credit = pick(date)
    if _is_banned(img, page, credit):  # last line of defence before it reaches a page
        title, img, page, credit = FALLBACK
    return (
        f"{START}\n"
        "## :material-newspaper-variant-outline: Cartoon of the day\n\n"
        f"[![{title}]({img}){{ width=560 }}]({page})\n\n"
        f"*[{title}]({page}) — via {credit}*\n"
        f"{END}"
    )


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else None
    d = dt.date.fromisoformat(arg) if arg else dt.date.today()
    print(block(d))
