#!/bin/bash
# ==========================================
# WSL STORAGE SCAN (read-only)
# Reports drive usage + sizes of every category wsl-reclaim can clean.
# Safe: touches nothing. Drives the wsl-storage skill's "where is the space" step.
# ==========================================
set -uo pipefail

WORK_DIR="$HOME/work"
CONTAINERS_DIR="$HOME/.local/share/containers"
MISE_DIR="$HOME/.local/share/mise"
NVIM_BAK="$HOME/.local/share/nvim.bak"
TRASH_DIR="$HOME/.local/share/Trash"
TERRAFORM_D="$HOME/.terraform.d"
CACHE_DIRS=("$HOME/.cache/ms-playwright" "$HOME/.cache/puppeteer" "$HOME/.cache/trivy" "$HOME/.cache/uv")

# Reuse the canonical monitor for the headline numbers if present.
MONITOR="$HOME/bin/wsl-monitor"
[ -x "$MONITOR" ] || MONITOR="$HOME/dotfiles/wsl/bin/wsl-monitor"

echo "=== DRIVES ==="
if [ -x "$MONITOR" ]; then
  "$MONITOR" 2>/dev/null | grep -E 'Usage:|Status:' || true
else
  df -h / /mnt/c /mnt/d 2>/dev/null
fi

dir_size() {
  [ -d "$1" ] || { echo "-"; return; }
  local s
  s=$(du -sh "$1" 2>/dev/null | tail -1 | awk '{print $1}')
  echo "${s:--}"
}

echo
echo "=== RECLAIM CANDIDATES (size on disk) ==="
printf '%-14s %-8s %s\n' "CATEGORY" "SIZE" "PATH/NOTE"
printf '%-14s %-8s %s\n' "podman"  "$(dir_size "$CONTAINERS_DIR")" "$CONTAINERS_DIR"
printf '%-14s %-8s %s\n' "mise"    "$(dir_size "$MISE_DIR")"       "$MISE_DIR"
printf '%-14s %-8s %s\n' "nvim-bak" "$(dir_size "$NVIM_BAK")"      "$NVIM_BAK"
printf '%-14s %-8s %s\n' "trash"   "$(dir_size "$TRASH_DIR")"      "$TRASH_DIR"
printf '%-14s %-8s %s\n' "terraform-d" "$(dir_size "$TERRAFORM_D")" "$TERRAFORM_D"

# Browser + tool caches
echo
echo "--- caches (~/.cache) ---"
for d in "${CACHE_DIRS[@]}"; do
  [ -d "$d" ] && printf '  %-8s %s\n' "$(dir_size "$d")" "$d"
done

# find-based total for a named dir under ~/work; prints e.g. "12.2G across 21 dirs"
find_total() {
  find "$WORK_DIR" -name "$1" -type d -prune -exec du -sb {} + 2>/dev/null \
    | awk '{s+=$1; n++} END{printf "%.1fG across %d dirs", s/1073741824, n}'
}

# Rust target dirs under ~/work
if [ -d "$WORK_DIR" ]; then
  echo
  echo "--- rust 'target' dirs under $WORK_DIR ---"
  find "$WORK_DIR" -maxdepth 4 -name target -type d -prune 2>/dev/null \
    | while read -r d; do printf '  %-8s %s\n' "$(du -sh "$d" 2>/dev/null | awk '{print $1}')" "$d"; done
  TARGET_TOTAL=$(find "$WORK_DIR" -maxdepth 4 -name target -type d -prune -exec du -sb {} + 2>/dev/null | awk '{s+=$1} END{printf "%.1fG", s/1073741824}')
  echo "  rust target total: ${TARGET_TOTAL:-0}"

  echo
  echo "--- terragrunt cache + node_modules under $WORK_DIR ---"
  echo "  terragrunt:    $(find_total .terragrunt-cache)"
  echo "  node_modules:  $(find_total node_modules)"
fi

# Go module cache
if command -v go &>/dev/null; then
  GOCACHE_DIR=$(go env GOMODCACHE 2>/dev/null)
  echo
  printf '%-14s %-8s %s\n' "go-modcache" "$(dir_size "$GOCACHE_DIR")" "${GOCACHE_DIR:-unknown}"
fi

# Live podman reclaimable estimate
if command -v podman &>/dev/null; then
  echo
  echo "--- podman system df ---"
  podman system df 2>/dev/null || true
fi

echo
echo "=== END SCAN ==="
