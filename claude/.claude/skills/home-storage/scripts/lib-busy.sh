#!/usr/bin/env bash
# lib-busy.sh — shared "is this worktree in active use?" detection.
# Sourced by homedisk-scan.sh and homedisk-reclaim.sh. Never disrupts a
# directory that a live process (Claude session, cargo/node build, editor,
# shell) is working inside.
#
# A worktree is BUSY if ANY of the following is true:
#   1. A running process owned by $USER has its cwd at-or-under the worktree.
#   2. lsof reports an open file under the worktree (a build writing target/,
#      an rust-analyzer holding files, etc.).
#   3. The worktree's target/ or node_modules/ was modified within
#      $HOMEDISK_BUSY_MTIME_MIN minutes (default 45) — an in-flight build the
#      process scan might momentarily miss.
#
# Exposes:
#   build_busy_roots        -> populates BUSY_ROOTS[] (one worktree/dir root per line)
#   is_busy <dir>           -> return 0 if <dir> is inside any busy root
#   worktree_root <dir>     -> echo the git worktree top-level for <dir> (or <dir>)

HOMEDISK_BUSY_MTIME_MIN="${HOMEDISK_BUSY_MTIME_MIN:-45}"
WORK_ROOT="${WORK_ROOT:-$HOME/work}"

declare -a BUSY_ROOTS=()

worktree_root() {
  local d="$1"
  git -C "$d" rev-parse --show-toplevel 2>/dev/null || echo "$d"
}

# Collect the set of directories that are "live" right now.
build_busy_roots() {
  local -A seen=()
  local p target real root

  # 1. cwd of every process we own.
  for p in /proc/[0-9]*; do
    real="$(readlink "$p/cwd" 2>/dev/null)" || continue
    [ -z "$real" ] && continue
    case "$real" in
      "$WORK_ROOT"|"$WORK_ROOT"/*) ;;
      *) continue ;;
    esac
    seen["$real"]=1
  done

  # 2. Open files under $WORK_ROOT (build outputs, editor buffers, analyzers).
  #    List all open file paths for our processes and filter by prefix — do
  #    NOT use `lsof +D` (it stat-walks the entire 100 GB+ tree).
  if command -v lsof >/dev/null 2>&1; then
    while IFS= read -r real; do
      [ -z "$real" ] && continue
      case "$real" in "$WORK_ROOT"/*) ;; *) continue ;; esac
      [ -d "$real" ] || real="$(dirname "$real")"
      seen["$real"]=1
    done < <(lsof -w -u "$USER" -Fn 2>/dev/null | sed -n 's/^n//p' | sort -u)
  fi

  # 3. Recently-modified build dirs (in-flight builds).
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    seen["$target"]=1
  done < <(find "$WORK_ROOT" -maxdepth 6 -type d \( -name target -o -name node_modules \) \
              -prune -mmin "-${HOMEDISK_BUSY_MTIME_MIN}" 2>/dev/null)

  BUSY_ROOTS=()
  for real in "${!seen[@]}"; do
    root="$(worktree_root "$real")"
    # $WORK_ROOT is the bare container holding every worktree, not a worktree
    # itself, so a cwd or open file sitting exactly there says nothing about
    # which worktree is in use — keeping it would mark the entire tree busy and
    # make every category unreclaimable. Activity *inside* a worktree still
    # resolves to that worktree, and in-flight builds are caught by rule 3.
    [ "$root" = "$WORK_ROOT" ] && continue
    BUSY_ROOTS+=("$root")
  done
  # de-dup
  if [ "${#BUSY_ROOTS[@]}" -gt 0 ]; then
    mapfile -t BUSY_ROOTS < <(printf '%s\n' "${BUSY_ROOTS[@]}" | sort -u)
  fi
}

# is_busy <dir> : true if <dir> is the same as, inside, or contains a busy root.
is_busy() {
  local dir="$1" root
  local wt; wt="$(worktree_root "$dir")"
  for root in "${BUSY_ROOTS[@]}"; do
    # busy if the candidate's worktree is at/under a busy root,
    # or a busy root is at/under the candidate dir.
    case "$root" in
      "$wt"|"$wt"/*) return 0 ;;
    esac
    case "$wt" in
      "$root"|"$root"/*) return 0 ;;
    esac
    case "$root" in
      "$dir"|"$dir"/*) return 0 ;;
    esac
  done
  return 1
}
