#!/usr/bin/env bash
# homedisk-scan.sh — READ-ONLY. Reports home-disk usage on this dev box and the
# size of every reclaim candidate, marking which are BUSY (in active use by a
# running Claude session / build / editor) so nothing live gets suggested for
# deletion. Touches nothing.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_ROOT="${WORK_ROOT:-$HOME/work}"
# shellcheck source=lib-busy.sh
source "$HERE/lib-busy.sh"

hr() { printf '%.0s─' {1..60}; echo; }
gb() { awk -v k="$1" 'BEGIN{printf "%.1f GB", k/1024/1024}'; }

echo "== Home disk =="
df -hT "$HOME" | awk 'NR==1 || NR==2'
echo
echo "Home usage: $(du -sxh "$HOME" 2>/dev/null | cut -f1)"
hr

echo "Building live-process map (Claude sessions / builds / editors)…" >&2
build_busy_roots
echo "== Active worktrees (will be SKIPPED by reclaim) =="
if [ "${#BUSY_ROOTS[@]}" -eq 0 ]; then
  echo "  (none detected)"
else
  printf '  %s\n' "${BUSY_ROOTS[@]}"
fi
hr

# category <name> <find-expr...> : sum size, split busy vs free
category() {
  local name="$1"; shift
  local total=0 busy=0 free=0 sz d
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    sz=$(du -sx "$d" 2>/dev/null | cut -f1); [ -z "$sz" ] && continue
    total=$((total+sz))
    if is_busy "$d"; then busy=$((busy+sz)); else free=$((free+sz)); fi
  done < <(find "$WORK_ROOT" -maxdepth 6 -type d "$@" -prune 2>/dev/null)
  printf "%-18s total %-10s reclaimable %-10s (busy/skipped %s)\n" \
    "$name" "$(gb $total)" "$(gb $free)" "$(gb $busy)"
}

echo "== Reclaim candidates under $WORK_ROOT =="
category "rust (target/)"      -name target
category "node_modules"        -name node_modules
category ".terragrunt-cache"   -name .terragrunt-cache
hr

echo "== Other home caches =="
for d in "$HOME/.cargo" "$HOME/.rustup" "$HOME/go" "$HOME/.cache" \
         "$HOME/.yarn" "$HOME/.npm" "$HOME/.terraform.d"; do
  [ -d "$d" ] && printf "%-22s %s\n" "${d#$HOME/}" "$(du -sxh "$d" 2>/dev/null | cut -f1)"
done
hr

echo "== Worktree inventory =="
for repo in "$WORK_ROOT/configs" "$WORK_ROOT/idp/selfservice" "$WORK_ROOT/idp/devportal"; do
  [ -d "$repo" ] || continue
  n=$(git -C "$repo" worktree list 2>/dev/null | wc -l)
  printf "%-28s %s worktrees\n" "${repo#$WORK_ROOT/}" "$n"
done
echo
echo "(Run homedisk-reclaim.sh with category flags to reclaim; it re-checks"
echo " busy state at delete time and always skips active worktrees.)"
