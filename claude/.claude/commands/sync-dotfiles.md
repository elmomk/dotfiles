Mirror my curated dotfiles subset into the shared-dotfiles repo, scan for secrets, then offer to commit/push.

## Usage

Invoked as `/sync-dotfiles`. Wraps the manual `sync.sh` mirror script so a copy is one command.

- Source of truth: `~/dotfiles` (github.com/elmomk/dotfiles) — keep editing there.
- Destination: `~/work/git/shared-dotfiles/momoyang/` (internal GitLab, `platform-engineering/shared-dotfiles`).
- The mirror is an **allowlist** (`MAP` in `sync.sh`) plus a secret filter — only listed paths are copied. To share a new file, add a `"<path under ~/dotfiles>|<path under momoyang/>"` line to the manifest first.

## Tool

`~/work/git/shared-dotfiles/momoyang/sync.sh` — rsyncs the manifest from `~/dotfiles` into `momoyang/`, vendors `cc-track` and live `~/.config/nvim`, then greps the result for secret patterns. Runs from any cwd (resolves dest from its own location). Honors `DOTFILES=` to override the source.

## Workflow

1. **Locate the repo** — `REPO=~/work/git/shared-dotfiles`. If missing, tell the user and stop (don't clone silently).

2. **Run the sync** from the repo:
   ```bash
   cd "$REPO" && ./momoyang/sync.sh
   ```
   Capture stdout — it lists each `ok:`/`skip:`/`BLOCKED` item and ends with a secret-scan verdict.

3. **Surface the secret scan** — the script prints either `clean: no secret patterns found.` or `⚠ POSSIBLE SECRETS …`. If it flagged anything, **stop** and show the user the offending lines; do not commit. The script's regex misses RFC1918 IPs, so also grep the changed files for hardcoded IPs:
   ```bash
   git -C "$REPO" diff --name-only -- 'momoyang/**' | xargs -r grep -nE '([0-9]{1,3}\.){3}[0-9]{1,3}' 2>/dev/null
   ```
   Hardcoded hosts/IPs should come from `~/.secrets.json`, not be committed.

4. **Show the diff** — `git -C "$REPO" status --short` and `git -C "$REPO" diff --stat`. If nothing changed, report "already in sync" and stop.

5. **Offer to commit/push** — ask the user to confirm. On yes:
   - Stage only the changed `momoyang/**` paths.
   - Commit with a conventional message summarizing what was synced (imperative mood). End the body with the standard `Co-Authored-By` trailer.
   - Push to the current branch's upstream (a `feat/momoyang-*` branch, **never** `master`). If the branch was rewritten, use `--force-with-lease`.
   - Print the MR-create URL that GitLab returns; do **not** open an MR unless the user asks.

## Notes

- Secrets are double-guarded (manifest allowlist + `SECRET_RX` + rsync `--exclude`). Still review the diff before committing.
- `master` has no `momoyang/` dir yet, so a full MR from the feature branch is the entire initial contribution — flag that if the user asks to open the MR.
