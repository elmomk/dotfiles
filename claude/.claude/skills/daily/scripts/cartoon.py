#!/usr/bin/env python3
"""cartoon.py — emit a date-rotating "cartoon of the day" block, fetched live.

Rotates through 5 ORIGINAL webcomic sources (one per day, by date ordinal % 5) and
fetches that source's *most recent* strip at runtime, so the image is hosted by the
comic's own origin — not re-hosted by an aggregator. A date's first successful pick is
cached (see CACHE_DIR), so repeated runs that day — e.g. a morning then an evening daily —
render the identical strip even if the source publishes a new one in between. Output is
delimited by <!-- cartoon:start --> / <!-- cartoon:end --> so the daily skill can replace it.

Sources (all checked live):
  - xkcd               JSON API   https://xkcd.com/info.0.json
  - turnoff.us         RSS        https://turnoff.us/feed.xml
  - Work Chronicles    RSS        https://workchronicles.com/feed/
  - Poorly Drawn Lines RSS        https://poorlydrawnlines.com/feed/
  - SMBC               RSS        https://www.smbc-comics.com/comic/rss

Dropped: Dilbert (dilbert.com defunct), CommitStrip (no new strips since 2022),
Sysadminotaur (Devolutions blog exposes only logos/marketing images, not the strip),
MonkeyUser (comic image is JS-rendered — absent from both the static HTML and the feed).

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


def src_poorlydrawnlines():
    return _rss_latest("https://poorlydrawnlines.com/feed/", "poorlydrawnlines.com")


def src_smbc():
    return _rss_latest("https://www.smbc-comics.com/comic/rss", "smbc-comics.com")


# Rotation order (index = date.toordinal() % 5).
PROVIDERS = [src_xkcd, src_turnoff, src_workchronicles, src_poorlydrawnlines, src_smbc]
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
        if r[1] and not _BAD_IMG.search(r[1]):  # ignore an empty/stale-bad cached image
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
    return (
        f"{START}\n"
        "## 🗞️ Cartoon of the day\n\n"
        f"[![{title}]({img}){{ width=560 }}]({page})\n\n"
        f"*[{title}]({page}) — via {credit}*\n"
        f"{END}"
    )


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else None
    d = dt.date.fromisoformat(arg) if arg else dt.date.today()
    print(block(d))
