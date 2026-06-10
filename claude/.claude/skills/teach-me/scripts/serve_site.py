#!/usr/bin/env python3
"""serve_site.py — no-cache static server for the teach-me library's built site.

Serves $TEACHME_HOME/library/site on 127.0.0.1:<port>. Every response carries
`Cache-Control: no-cache`, forcing browsers to revalidate each navigation —
`zensical serve` sends only Last-Modified, which lets browsers heuristically
cache pages for hours, so after a new topic was added the left nav (baked into
every cached page) kept showing the old section list. Conditional requests
still get 304s, so revalidation stays cheap.

Serving straight from disk also means a fresh `zensical build` is visible on
the next refresh — no watcher or live-reload needed.

The `X-Teachme-Library` marker header lets serve_library.sh recognize this
server when probing the port.

Usage: serve_site.py [port]   (default 8042)
"""
import functools
import http.server
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8042
ROOT = os.path.join(
    os.environ.get("TEACHME_HOME", os.path.expanduser("~/teach-me")), "library", "site"
)


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        self.send_header("X-Teachme-Library", "1")
        super().end_headers()

    def log_message(self, fmt, *args):  # access log — handy for "is the browser even hitting us?"
        sys.stderr.write("%s - %s\n" % (self.log_date_time_string(), fmt % args))


if not os.path.isdir(ROOT):
    sys.exit(f"[teach-me] site dir not found: {ROOT} — run `zensical build` first")

server = http.server.ThreadingHTTPServer(
    ("127.0.0.1", PORT), functools.partial(Handler, directory=ROOT)
)
print(f"[teach-me] serving {ROOT} on http://127.0.0.1:{PORT}/", flush=True)
server.serve_forever()
