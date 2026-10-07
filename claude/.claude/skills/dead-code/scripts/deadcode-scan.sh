#!/usr/bin/env bash
# Dead-code scan: generic reference-graph analysis, plus whichever native
# per-language tools happen to be installed. Read-only — never edits or deletes.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYZE="$HERE/deadcode-analyze.py"

ROOT="."
JSON=0
NATIVE=1
FETCH=0
declare -a PASSTHRU=()

usage() {
  cat <<'USAGE'
usage: deadcode-scan.sh [PATH] [options]

  --json                emit machine-readable JSON (generic layer only)
  --no-native           skip the native-tool layer
  --fetch               refresh remote refs before the staleness check
  --min-confidence C    low | medium | high   (default: low)
  --lang L              restrict to rust|ts|python|go|shell|hcl|kcl|jsonnet
  --path P              only report findings under this prefix (whole tree still
                        indexed for references); repeatable
  --exclude P           never report findings under this prefix — vendored trees,
                        deprecated dirs; still indexed for references; repeatable
  --limit N             cap the number of findings
  --ignore-test-refs    treat references from tests as soft
  --no-orphans          skip whole-file orphan detection
  --no-allowlist        also consider suppressed entrypoint names

Every option after PATH is forwarded to deadcode-analyze.py.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --json) JSON=1; PASSTHRU+=("--json"); shift ;;
    --no-native) NATIVE=0; shift ;;
    --fetch) FETCH=1; shift ;;
    --min-confidence|--lang|--path|--exclude|--limit) PASSTHRU+=("$1" "$2"); shift 2 ;;
    --ignore-test-refs|--no-orphans|--no-allowlist) PASSTHRU+=("$1"); shift ;;
    -*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) ROOT="$1"; shift ;;
  esac
done

[ -d "$ROOT" ] || { echo "not a directory: $ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd)"

# ------------------------------------------------------------------- freshness
# "Nothing references X" is a claim about the tree in front of you. On a checkout
# weeks behind its remote it says nothing about master. Reported on stderr so it
# is visible in both human and --json mode without breaking the JSON.
freshness() {
  git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || return 0
  [ "$FETCH" -eq 1 ] && git -C "$ROOT" fetch -q origin 2>/dev/null

  local head short date base behind dirty
  short="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)" || return 0
  date="$(git -C "$ROOT" log -1 --format=%cd --date=short 2>/dev/null)"
  base="$(git -C "$ROOT" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)"
  [ -n "$base" ] || base="origin/master"
  git -C "$ROOT" rev-parse --verify -q "$base" >/dev/null 2>&1 || base=""
  behind=0
  [ -n "$base" ] && behind="$(git -C "$ROOT" rev-list --count "HEAD..$base" 2>/dev/null || echo 0)"
  dirty="$(git -C "$ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

  { printf 'checkout  %s (%s)' "$short" "$date"
    [ "$behind" -gt 0 ] && printf ' — %s commits behind %s' "$behind" "$base"
    [ "$dirty" -gt 0 ] && printf ' — %s uncommitted file(s)' "$dirty"
    printf '\n'
    if [ "$behind" -gt 0 ] || [ "$dirty" -gt 0 ]; then
      printf 'WARNING   these findings describe THIS tree, not %s.\n' "${base:-the remote}"
      printf '          A symbol dead here may have gained callers upstream. Scan a\n'
      printf '          fresh worktree before deleting anything:\n'
      printf '            git worktree add --detach /tmp/scan %s\n' "${base:-origin/master}"
    fi
  } >&2
}
freshness

# ---------------------------------------------------------------- generic layer
python3 "$ANALYZE" "$ROOT" "${PASSTHRU[@]+"${PASSTHRU[@]}"}"
rc=$?

# JSON mode stays parseable: no native section appended.
[ "$JSON" -eq 1 ] && exit $rc
[ "$NATIVE" -eq 0 ] && exit $rc

# ----------------------------------------------------------------- native layer
# Only tools already on PATH run. Nothing is installed: a scan must not mutate
# the toolchain. Missing tools are reported with their install command instead.
have() { command -v "$1" >/dev/null 2>&1; }
found_any=0
declare -a MISSING=()

section() { printf '\n=== native: %s ===\n' "$1"; }

# Repo inventory. Crates and package roots are usually nested (configs keeps its
# only Rust crate under apps/idp/wrapper), so probe the tree, not just the root.
list_repo() {
  git -C "$ROOT" ls-files 2>/dev/null \
    || (cd "$ROOT" && find . -type f -not -path '*/.git/*' -printf '%P\n' 2>/dev/null)
}
INVENTORY="$(list_repo)"
# Herestring, not a pipe: `grep -q` exits on the first match, which SIGPIPEs the
# writer, and under `pipefail` that made every probe report "not found".
matches() { grep -qE "$1" <<<"$INVENTORY"; }
roots_of() { grep -E "$1" <<<"$INVENTORY" | sed 's|[^/]*$||;s|^$|./|' | sort -u; }

if matches '(^|/)Cargo\.toml$'; then
  if have cargo-machete; then
    found_any=1; section "cargo machete (unused dependencies)"
    (cd "$ROOT" && cargo machete 2>&1 | tail -40)
  else
    MISSING+=("cargo-machete    unused Cargo deps    cargo install cargo-machete")
  fi
  if have cargo; then
    found_any=1; section "cargo check (dead_code / unused warnings)"
    while IFS= read -r crate; do
      [ -n "$crate" ] || continue
      echo "-- $crate"
      (cd "$ROOT/$crate" && cargo check --all-targets --message-format short 2>&1 \
        | grep -E 'never used|never read|never constructed|unused' | sort -u | head -20)
    done <<<"$(roots_of '(^|/)Cargo\.toml$')"
    echo "(no lines under a crate = the compiler sees no unused items there)"
  fi
fi

if matches '(^|/)package\.json$'; then
  if have knip; then
    found_any=1; section "knip (unused files / exports / deps)"
    (cd "$ROOT" && knip --no-progress 2>&1 | head -60)
  else
    MISSING+=("knip             unused TS exports    npx -y knip")
  fi
fi

if matches '\.py$'; then
  if python3 -c 'import vulture' 2>/dev/null; then
    found_any=1; section "vulture (unused Python code)"
    (cd "$ROOT" && python3 -m vulture . --min-confidence 80 2>&1 | head -40)
  else
    MISSING+=("vulture          unused Python code   pipx install vulture")
  fi
fi

if have shellcheck; then
  found_any=1; section "shellcheck SC2034 (unused shell variables)"
  # shellcheck disable=SC2016
  (cd "$ROOT" && git ls-files '*.sh' 2>/dev/null | head -200 | xargs -r \
    shellcheck -f gcc -i SC2034 2>/dev/null | head -40)
else
  MISSING+=("shellcheck       unused shell vars    mise use -g shellcheck")
fi

if [ "$found_any" -eq 0 ]; then
  printf '\n=== native: none available ===\n'
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  printf '\nnot installed (generic layer covered these languages anyway):\n'
  printf '  %s\n' "${MISSING[@]}"
fi

exit $rc
