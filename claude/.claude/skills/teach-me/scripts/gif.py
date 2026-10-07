#!/usr/bin/env python3
"""gif.py — emit a GIF embed block for teach-me / daily pages.

Two modes, both deterministic per seed and cached so repeated runs agree:

  gif.py <seed>                      # curated pick: hash(seed) rotates a built-in list
  gif.py <seed> --query "kubernetes" # topic-relevant: Giphy search (needs GIPHY_API_KEY)

<seed> is any string — a date (2026-07-02) for dailies, a topic slug (raft-consensus)
for tutorial sections. Search mode needs GIPHY_API_KEY in the env (load via bwu/direnv,
never hardcoded); without it, --query silently falls back to the curated list, so callers
can always pass --query and get *something*. A seed's first successful pick is cached
(GIF_CACHE dir) so morning/evening runs and rebuilds render the identical GIF.

Output is delimited by <!-- gif:start --> / <!-- gif:end --> so skills can replace the
block idempotently. Stdlib only.
"""
import hashlib
import json
import os
import sys
import urllib.parse
import urllib.request

START, END = "<!-- gif:start -->", "<!-- gif:end -->"
TIMEOUT = 15

# Curated fallback pool — stable media.giphy.com URLs, verified reachable.
CURATED = [
    ("JIX9t2j0ZTN9S", "cat, furiously typing"),
    ("13HgwGsXF0aiGY", "hacking in progress"),
    ("ZVik7pBtu9dNS", "high five — it shipped"),
    ("111ebonMs90YLu", "thumbs up"),
    ("3oKIPnAiaMCws8nOsE", "dev mood of the day"),
    ("l0MYt5jPR6QX5pnqM", "mind blown"),
    ("26tn33aiTi1jkl6H6", "celebration"),
    ("LmNwrBhejkK9EFP504", "that feeling when the build is green"),
    ("mCRJDo24UvJMA", "I have no idea what I'm doing"),
    ("yYSSBtDgbbRzq", "dev mood of the day"),
    ("5wWf7GR2nhgamhRnEuA", "deploying to production"),
    ("vISmwpBJUNYzukTnVx", "dev mood of the day"),
    ("QNFhOolVeCzPQ2Mx85", "works on my machine"),
]

CACHE_DIR = os.path.expanduser(os.environ.get("GIF_CACHE", "~/.cache/teachme-gif"))


def _cache_path(seed):
    return os.path.join(CACHE_DIR, hashlib.sha1(seed.encode()).hexdigest()[:16] + ".json")


def _cache_get(seed):
    try:
        with open(_cache_path(seed), encoding="utf-8") as f:
            d = json.load(f)
        return d["title"], d["img"], d["page"]
    except (OSError, ValueError, KeyError):
        return None


def _cache_put(seed, r):
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(_cache_path(seed), "w", encoding="utf-8") as f:
            json.dump(dict(zip(("title", "img", "page"), r)), f)
    except OSError:
        pass  # cache is best-effort


def curated_pick(seed):
    h = int(hashlib.sha1(seed.encode()).hexdigest(), 16)
    gid, title = CURATED[h % len(CURATED)]
    return (title, f"https://media.giphy.com/media/{gid}/giphy.gif",
            f"https://giphy.com/gifs/{gid}")


def giphy_search(seed, query, api_key):
    """Deterministic per seed: fetch top 25, pick by seed hash."""
    url = "https://api.giphy.com/v1/gifs/search?" + urllib.parse.urlencode(
        {"api_key": api_key, "q": query, "limit": 25, "rating": "g"})
    with urllib.request.urlopen(url, timeout=TIMEOUT) as r:
        data = json.load(r)["data"]
    if not data:
        return None
    h = int(hashlib.sha1(seed.encode()).hexdigest(), 16)
    g = data[h % len(data)]
    return (g.get("title") or query, g["images"]["original"]["url"], g["url"])


def pick(seed, query=None):
    cache_key = f"{seed}|{query or ''}"
    cached = _cache_get(cache_key)
    if cached:
        return cached
    r = None
    key = os.environ.get("GIPHY_API_KEY")
    if query and key:
        try:
            r = giphy_search(seed, query, key)
        except Exception as e:  # noqa: BLE001 - fall back to curated
            print(f"[gif] giphy search failed: {e}", file=sys.stderr)
    if r is None:
        r = curated_pick(seed)
    _cache_put(cache_key, r)
    return r


def block(seed, query=None):
    title, img, page = pick(seed, query)
    return (
        f"{START}\n"
        "## :material-movie-open-play: GIF of the day\n\n"
        f"[![{title}]({img}){{ width=420 }}]({page})\n\n"
        f"*[{title}]({page}) — via giphy.com*\n"
        f"{END}"
    )


if __name__ == "__main__":
    args = sys.argv[1:]
    query = None
    if "--query" in args:
        i = args.index("--query")
        query = args[i + 1]
        del args[i:i + 2]
    if not args:
        sys.exit("usage: gif.py <seed> [--query <topic>]")
    print(block(args[0], query))
