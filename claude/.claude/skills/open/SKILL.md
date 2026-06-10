---
name: open
description: "Open any link or GitLab MR in the browser using the same launcher as the daily/teach-me skills (open-url → laptop browser-bridge over the SSH tunnel, then explorer.exe / open / xdg-open). Triggers: open, open link, open url, open this, open MR, open the MR, open in browser."
argument-hint: "<url | project!iid | project:iid | iid | (blank=current branch MR)> (e.g., 'cf:806', 'platform-engineering/configs!806', 'https://…')"
---

# Open

Resolve the argument to a URL and open it in the browser via the **same logic as
`/daily`** — the shared `open-url` launcher (which forwards to a laptop-side
`browser-bridge` over the SSH reverse tunnel on a headless dev-server, then falls
back to `explorer.exe` / `open` / `xdg-open`).

## How to run

Pass the argument straight to the bundled script:

```bash
bash "$(dirname "$0")/scripts/open-link.sh" "<arg>"   # or use the absolute skill path
```

The script (`scripts/open-link.sh`) handles every form:

| Argument | Resolves to |
|---|---|
| `https://…` / `http://…` | opened as-is |
| `<project>!<iid>` or `<project>:<iid>` | `http://$GITLAB_HOST/<project>/-/merge_requests/<iid>` |
| `<iid>` (bare number) | same, with `<project>` from the current repo's git remote |
| *(blank)* | the open MR for the current git branch (via `gl-mr find`) |

`<project>` accepts the mr-summary shorthand (`sv`, `dp`, `cf`) or a full
`group/subgroup/project` path.

## Notes

- Needs `GITLAB_HOST` in the env for MR references — it's loaded from the kernel
  keyring by `bwu` (and hydrated into every shell), so a single `bwu` per boot is
  enough. Raw URLs need nothing.
- If the browser doesn't actually open on a headless dev-server, `browser-bridge`
  isn't running (or is on the wrong loopback) on the laptop — the URL is still
  printed so it can be opened manually. See the open-url / browser-bridge tooling.
- Don't delegate to a sub-agent; this is a single fast command and the caller
  should see the resolved URL.
