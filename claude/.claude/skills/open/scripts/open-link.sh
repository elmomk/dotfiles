#!/usr/bin/env bash
# open-link.sh — resolve a URL or GitLab MR reference and open it in the browser
# using the SAME launcher as the daily/teach-me skills: open-url (which on a
# headless dev-server hands the URL to a laptop-side browser-bridge over the SSH
# reverse tunnel), then explorer.exe / open / xdg-open as fallbacks.
#
# Usage: open-link.sh <arg>
#   <arg> = https://… | http://…              → opened as-is
#         | <project>!<iid> | <project>:<iid>  → MR link (project shorthand ok)
#         | <iid>                               → MR in the current repo's project
#         | (blank)                             → MR for the current git branch
set -uo pipefail

# Project shorthand — shared vocabulary with the mr-summary skill.
expand_proj() {
  case "$1" in
    sv) echo "platform-engineering/idp/selfservice" ;;
    dp) echo "platform-engineering/idp/devportal" ;;
    cf) echo "platform-engineering/configs" ;;
    *)  echo "$1" ;;
  esac
}

repo_project() {
  git remote get-url origin 2>/dev/null | sed -E 's|.*://[^/]+/||; s|.*:||; s|\.git$||'
}

open_it() {  # the daily/teach-me launcher chain
  local url="$1"
  if   command -v open-url >/dev/null 2>&1;            then open-url "$url" || true
  elif grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then explorer.exe "$url" || true
  elif command -v open >/dev/null 2>&1;                then open "$url" || true
  elif command -v xdg-open >/dev/null 2>&1;            then xdg-open "$url" || true
  else echo "open this in your browser: $url"; fi
  echo "→ $url"
}

arg="${1:-}"

# 1) raw URL → open as-is
if [[ "$arg" =~ ^https?:// ]]; then open_it "$arg"; exit 0; fi

# 2) MR reference → construct the GitLab MR URL (offline; no API call)
: "${GITLAB_HOST:?GITLAB_HOST not set — run bwu}"
proj=""; iid=""
if   [[ "$arg" == *"!"* ]]; then proj="${arg%%!*}"; iid="${arg##*!}"
elif [[ "$arg" == *":"* ]]; then proj="${arg%%:*}"; iid="${arg##*:}"
elif [[ "$arg" =~ ^[0-9]+$ ]]; then iid="$arg"
elif [[ -z "$arg" ]]; then
  # current branch's open MR (gl-mr prints "  !<iid>  …")
  iid="$(gl-mr find 2>/dev/null | grep -oE '!\s*[0-9]+' | grep -oE '[0-9]+' | head -1)"
fi

[[ -z "$proj" ]] && proj="$(repo_project)"
proj="$(expand_proj "$proj")"

if [[ -z "$proj" || -z "$iid" ]]; then
  echo "open-link: could not resolve an MR (project='$proj' iid='$iid')." >&2
  echo "  pass a URL, <project>!<iid> (e.g. cf:806 or platform-engineering/configs!806)," >&2
  echo "  a bare <iid> inside the repo, or run with no arg on a branch that has an MR." >&2
  exit 1
fi
open_it "http://${GITLAB_HOST}/${proj}/-/merge_requests/${iid}"
