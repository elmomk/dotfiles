#!/bin/bash
# ==========================================
# WSL RECLAIM (non-interactive, flag-driven)
# Non-interactive adaptation of wsl-cleanup: cleans ONLY the categories named
# as flags, so the wsl-storage skill can run exactly what the user approved.
# No blind prompts, no "clean everything" default.
#
# Usage: wsl-reclaim.sh [--dry-run] <category...>
#   categories: podman mise rust go apt journal trash nvim-bak
#               terragrunt node-modules terraform-d caches all
# ==========================================
set -uo pipefail

WORK_DIR="$HOME/work"
CONTAINERS_DIR="$HOME/.local/share/containers"
NVIM_BAK="$HOME/.local/share/nvim.bak"
TRASH_DIR="$HOME/.local/share/Trash"
TERRAFORM_D="$HOME/.terraform.d"
CACHE_DIRS=("$HOME/.cache/ms-playwright" "$HOME/.cache/puppeteer" "$HOME/.cache/trivy" "$HOME/.cache/uv")

DRY_RUN=0
declare -A DO

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    all) for c in podman mise rust go apt journal trash nvim-bak terragrunt node-modules terraform-d caches; do DO[$c]=1; done ;;
    podman|mise|rust|go|apt|journal|trash|nvim-bak|terragrunt|node-modules|terraform-d|caches) DO[$arg]=1 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [ "${#DO[@]}" -eq 0 ]; then
  echo "Nothing to do. Pass one or more categories: podman mise rust go apt journal trash nvim-bak terragrunt node-modules terraform-d caches all" >&2
  echo "(add --dry-run to preview)" >&2
  exit 2
fi

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] $*"
  else
    echo "  + $*"
    eval "$@"
  fi
}

want() { [ -n "${DO[$1]:-}" ]; }

USED_BEFORE=$(df -BG / | awk 'NR==2 {gsub("G","",$3); print $3}')
echo "WSL disk used before: ${USED_BEFORE}G  (dry-run=$DRY_RUN)"
echo

if want podman; then
  echo "[podman] prune images/containers/volumes"
  if command -v podman &>/dev/null; then
    run "podman system prune -a -f --volumes"
  elif [ -d "$CONTAINERS_DIR" ]; then
    echo "  podman not installed; orphaned $CONTAINERS_DIR present."
    run "rm -rf \"$CONTAINERS_DIR\""
  fi
fi

if want mise; then
  echo "[mise] clean cache + prune unused versions"
  if command -v mise &>/dev/null; then
    run "mise cache clean"
    run "mise prune -y"
  fi
fi

if want rust; then
  echo "[rust] remove 'target' dirs under $WORK_DIR"
  if [ -d "$WORK_DIR" ]; then
    run "find \"$WORK_DIR\" -name target -type d -prune -exec rm -rf {} + 2>/dev/null"
  fi
fi

if want go; then
  echo "[go] clean module cache"
  command -v go &>/dev/null && run "go clean -modcache"
fi

if want trash; then
  echo "[trash] empty $TRASH_DIR"
  [ -d "$TRASH_DIR" ] && run "rm -rf \"$TRASH_DIR\"/*"
fi

if want nvim-bak; then
  echo "[nvim-bak] remove $NVIM_BAK"
  [ -d "$NVIM_BAK" ] && run "rm -rf \"$NVIM_BAK\""
fi

if want terragrunt; then
  echo "[terragrunt] remove '.terragrunt-cache' dirs under $WORK_DIR"
  [ -d "$WORK_DIR" ] && run "find \"$WORK_DIR\" -name .terragrunt-cache -type d -prune -exec rm -rf {} + 2>/dev/null"
fi

if want node-modules; then
  echo "[node-modules] remove 'node_modules' dirs under $WORK_DIR"
  [ -d "$WORK_DIR" ] && run "find \"$WORK_DIR\" -name node_modules -type d -prune -exec rm -rf {} + 2>/dev/null"
fi

if want terraform-d; then
  echo "[terraform-d] remove $TERRAFORM_D (provider plugin cache)"
  [ -d "$TERRAFORM_D" ] && run "rm -rf \"$TERRAFORM_D\""
fi

if want caches; then
  echo "[caches] remove browser + tool caches under ~/.cache"
  for d in "${CACHE_DIRS[@]}"; do
    [ -d "$d" ] && run "rm -rf \"$d\""
  done
fi

if want apt; then
  echo "[apt] autoremove + clean (needs sudo)"
  command -v apt-get &>/dev/null && run "sudo apt-get autoremove -y && sudo apt-get clean"
fi

if want journal; then
  echo "[journal] vacuum to 1 day (needs sudo)"
  run "sudo journalctl --vacuum-time=1d"
fi

echo
USED_AFTER=$(df -BG / | awk 'NR==2 {gsub("G","",$3); print $3}')
echo "WSL disk used after:  ${USED_AFTER}G"
if [ "$DRY_RUN" -eq 0 ]; then
  echo "Reclaimed: $(( USED_BEFORE - USED_AFTER ))G"
fi
df -h / 2>/dev/null
