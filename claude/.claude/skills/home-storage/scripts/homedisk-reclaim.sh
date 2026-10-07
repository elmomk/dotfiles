#!/usr/bin/env bash
# homedisk-reclaim.sh — non-interactive home-disk reclaim for this dev box.
# Acts ONLY on categories passed as flags; refuses if none are given.
# NEVER touches a directory that a live Claude session / build / editor is
# using: every deletion re-checks busy state at delete time and skips it.
#
# Usage:
#   homedisk-reclaim.sh [--dry-run] [--include-busy] CATEGORY...
# Categories:
#   rust           all target/ under ~/work        (next build = full rebuild)
#   node-modules   all node_modules under ~/work   (yarn/npm install restores)
#   terragrunt     all .terragrunt-cache dirs       (re-inits on next run)
#   go             go clean -cache                  (re-download)
#   caches         ~/.cache/{uv,ms-playwright,trivy,puppeteer}
#   worktrees      git worktree prune + report removable merged worktrees
#   all            every auto-regenerating category (NOT worktrees)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_ROOT="${WORK_ROOT:-$HOME/work}"
# shellcheck source=lib-busy.sh
source "$HERE/lib-busy.sh"

DRY=0; INCLUDE_BUSY=0; declare -a CATS=()
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --include-busy) INCLUDE_BUSY=1 ;;   # override guard; use with care
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    rust|node-modules|terragrunt|go|caches|worktrees|all) CATS+=("$a") ;;
    *) echo "unknown arg: $a" >&2; exit 2 ;;
  esac
done
if [ "${#CATS[@]}" -eq 0 ]; then
  echo "refusing to run with no categories. pass e.g. 'rust node-modules' (see --help)." >&2
  exit 2
fi
[[ " ${CATS[*]} " == *" all "* ]] && CATS=(rust node-modules terragrunt go caches)

used_kb() { du -sx "$HOME" 2>/dev/null | cut -f1; }
BEFORE=$(used_kb)
echo "Home used before: $(awk -v k="$BEFORE" 'BEGIN{printf "%.1f GB", k/1024/1024}')"

echo "Mapping live processes…" >&2
build_busy_roots
[ "$INCLUDE_BUSY" -eq 1 ] && echo "!! --include-busy: busy guard DISABLED for this run" >&2

SKIPPED=0
# rm_dir <dir> : delete unless busy (or --dry-run)
rm_dir() {
  local d="$1"
  if [ "$INCLUDE_BUSY" -eq 0 ] && is_busy "$d"; then
    echo "  SKIP (busy)  $d"; SKIPPED=$((SKIPPED+1)); return
  fi
  if [ "$DRY" -eq 1 ]; then
    echo "  would rm     $d ($(du -sxh "$d" 2>/dev/null | cut -f1))"
  else
    echo "  rm           $d ($(du -sxh "$d" 2>/dev/null | cut -f1))"
    rm -rf "$d"
  fi
}

reclaim_find() {  # <label> <find name>
  echo "== $1 =="
  while IFS= read -r d; do [ -n "$d" ] && rm_dir "$d"; done \
    < <(find "$WORK_ROOT" -maxdepth 6 -type d -name "$2" -prune 2>/dev/null)
}

for c in "${CATS[@]}"; do
  case "$c" in
    rust)         reclaim_find "rust target/"      target ;;
    node-modules) reclaim_find "node_modules"      node_modules ;;
    terragrunt)   reclaim_find ".terragrunt-cache" .terragrunt-cache ;;
    go)
      echo "== go build cache =="
      if [ "$DRY" -eq 1 ]; then echo "  would run: go clean -cache"; else go clean -cache 2>/dev/null && echo "  go cache cleaned"; fi ;;
    caches)
      echo "== ~/.cache selected =="
      for d in "$HOME/.cache/uv" "$HOME/.cache/ms-playwright" "$HOME/.cache/trivy" "$HOME/.cache/puppeteer"; do
        [ -d "$d" ] && rm_dir "$d"
      done ;;
    worktrees)
      echo "== worktrees (report only — no auto-remove) =="
      for repo in "$WORK_ROOT/configs" "$WORK_ROOT/idp/selfservice" "$WORK_ROOT/idp/devportal"; do
        [ -d "$repo" ] || continue
        echo "  -- ${repo#$WORK_ROOT/} --"
        if [ "$DRY" -eq 1 ]; then git -C "$repo" worktree prune --dry-run -v 2>/dev/null | sed 's/^/  /'
        else git -C "$repo" worktree prune -v 2>/dev/null | sed 's/^/  prune: /'; fi
        # list clean + merged worktrees as removal candidates (never auto-rm)
        git -C "$repo" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r wt; do
          [ "$wt" = "$repo" ] && continue
          if is_busy "$wt"; then echo "  KEEP (busy)     $wt"; continue; fi
          if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
            echo "  KEEP (dirty)    $wt"; continue
          fi
          br=$(git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null)
          if git -C "$repo" branch --merged 2>/dev/null | grep -qx "  $br"; then
            echo "  candidate (merged, clean): git -C ${repo#$WORK_ROOT/} worktree remove $wt"
          else
            echo "  KEEP (unmerged) $wt  [$br]"
          fi
        done
      done ;;
  esac
done

AFTER=$(used_kb)
echo
echo "Home used after:  $(awk -v k="$AFTER" 'BEGIN{printf "%.1f GB", k/1024/1024}')"
echo "Reclaimed:        $(awk -v b="$BEFORE" -v a="$AFTER" 'BEGIN{printf "%.1f GB", (b-a)/1024/1024}')"
[ "$SKIPPED" -gt 0 ] && echo "Skipped $SKIPPED busy dir(s) — re-run later to reclaim them once idle."
[ "$DRY" -eq 1 ] && echo "(dry-run: nothing was deleted)"
