#!/usr/bin/env bash
# creds-doctor — show WHERE your bwu-loaded credentials are visible, and why.
#
# Two stores with very different scope:
#   • kernel user keyring @u  — per-UID, shared LIVE by every process of this
#     UID, wiped on reboot; populated once per boot by `bwu`. The source of truth.
#   • a process's env         — per-process, FROZEN at spawn; bwu's `export`s only
#     reach the shell it ran in (+ children spawned after). Can't reach a sibling.
#
# Prints presence/absence and lengths only — NEVER the secret values.
set -u

KEYS=(gl:host gl:token mr:group mr:users mr:group_saas mr:users_saas
      jira:token infracost:token atlassian:cloud_id atlassian:site secrets:json)

# --repair: re-perm every bwu key to 0x3f3f0000 from the systemd --user manager,
# the one context that always possesses @u. Needed when bwu ran from a shell on
# a REVOKED session keyring (tmux/claude outliving their login — pam_keyinit
# `force revoke`): its per-key setperm was silently denied, keys landed at the
# kernel default user=VIEW-only, and every reader's `keyctl print` fails while
# `keyctl search` still succeeds. Key NAMES only on the command line.
if [[ ${1:-} == --repair ]]; then
  command -v keyctl >/dev/null 2>&1 || { echo "no keyctl"; exit 1; }
  command -v systemd-run >/dev/null 2>&1 || { echo "no systemd-run — cannot reach a possessing context"; exit 1; }
  systemd-run --user --quiet --wait --collect /bin/sh -c '
    for n in '"${KEYS[*]}"'; do
      id=$(keyctl search @u user "$n" 2>/dev/null) && keyctl setperm "$id" 0x3f3f0000
    done'
  echo "repair sweep done — re-run creds-doctor to verify"
  exit 0
fi

if [[ -t 1 ]]; then
  GREEN=$'\e[32m'; RED=$'\e[31m'; YEL=$'\e[33m'; DIM=$'\e[2m'; BOLD=$'\e[1m'; RST=$'\e[0m'
else
  GREEN=''; RED=''; YEL=''; DIM=''; BOLD=''; RST=''
fi
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RST" "$*"; }
bad()  { printf '  %s✗%s %s\n' "$RED" "$RST" "$*"; }
warn() { printf '  %s•%s %s\n' "$YEL" "$RST" "$*"; }
hdr()  { printf '\n%s%s%s\n' "$BOLD" "$1" "$RST"; }

# --- identity ---
hdr "Identity"
printf '  uid=%s (%s)\n' "$(id -u)" "$(whoami)"
if command -v keyctl >/dev/null 2>&1; then ok "keyctl present"; HAVE_KC=1
else bad "keyctl MISSING — keyring path unavailable on this host"; HAVE_KC=0; fi

# --- keyring @u: the shared source of truth ---
# Presence is checked with `keyctl search @u` and READABILITY with the key's
# user permission byte (`keyctl describe`, VIEW always allowed). The two can
# disagree: a key written by a possession-less bwu sits at user=VIEW-only —
# search finds it, every reader's `keyctl print` is denied. That was invisible
# here before and produced a green verdict over a dead credential path.
hdr "Kernel user keyring @u  ${DIM}(shared per-UID, live; populated by bwu)${RST}"
KR_TOKEN=0
PERM_BAD=0
if (( HAVE_KC )); then
  for k in "${KEYS[@]}"; do
    if kid=$(keyctl search @u user "$k" 2>/dev/null); then
      desc=$(keyctl describe "$kid" 2>/dev/null || true)
      if [[ $desc == *alswrvalswrv* ]]; then
        ok "$k"
      else
        bad "$k ${DIM}present but user=VIEW-only — readers get nothing${RST}"
        PERM_BAD=1
      fi
      [[ $k == gl:token ]] && KR_TOKEN=1
    else
      warn "$k ${DIM}absent${RST}"
    fi
  done
  (( KR_TOKEN )) || bad "gl:token absent → run ${BOLD}bwu${RST} (once per boot)"
else
  warn "skipped (no keyctl)"
fi

# --- session keyring: possession, i.e. whether THIS process could read a
# view-only key anyway. Revoked = this shell outlived its login session
# (pam_keyinit `force revoke`; typical for tmux panes and claude). Harmless
# when the perm bytes above are right; fatal when combined with VIEW-only. ---
hdr "Session keyring  ${DIM}(possession — revoked on shells that outlive their login)${RST}"
if (( HAVE_KC )); then
  if keyctl describe @s >/dev/null 2>&1; then
    ok "alive — this process can also read via possession"
  else
    warn "REVOKED — no possession; reads rely entirely on each key's user perm byte"
  fi
fi

# --- this process's env: the frozen snapshot ---
hdr "This process env  ${DIM}(frozen at \`claude\`/shell launch)${RST}"
envstate() { local v=${!1:-}; if [[ -n $v ]]; then ok "$1 set ${DIM}(${#v} chars)${RST}"; else warn "$1 ${DIM}empty${RST}"; fi; }
for v in GITLAB_HOST GITLAB_TOKEN JIRA_API_TOKEN INFRACOST_API_KEY; do envstate "$v"; done

# --- on-disk caches (opt-in fallback) ---
hdr "On-disk caches  ${DIM}(opt-in fallback; absent = env/keyring-only host)${RST}"
for f in "$HOME/.secrets.json" "$HOME/.work.json"; do
  [[ -f $f ]] && ok "$f ${DIM}($(stat -c %a "$f" 2>/dev/null) perms)${RST}" || warn "$f ${DIM}absent${RST}"
done

# --- MCP auth: a SEPARATE store. Each MCP server holds its own OAuth (in Claude
# Code's config), NOT the keyring's jira:token. A healthy keyring says nothing
# about MCP health and vice-versa — so probe it live. Claude-Code-specific;
# degrades gracefully where the `claude` CLI is absent. ---
hdr "MCP auth  ${DIM}(separate store — own OAuth per server, NOT the keyring jira:token)${RST}"
if command -v claude >/dev/null 2>&1; then
  mcp=$(timeout 25 claude mcp list 2>/dev/null)
  if [[ -z $mcp ]]; then
    warn "claude mcp list returned nothing (timeout, or no MCP servers configured)"
  else
    # Atlassian (Jira/Confluence) is the one the jira/mr-board workflows depend on.
    atl=$(printf '%s\n' "$mcp" | grep -i atlassian)
    if [[ -z $atl ]]; then
      warn "no Atlassian MCP configured"
    elif printf '%s' "$atl" | grep -qi 'Connected'; then
      ok "Atlassian (Jira/Confluence): connected"
    elif printf '%s' "$atl" | grep -qiE 'Needs authentication|auth'; then
      bad "Atlassian: NEEDS AUTH → run /mcp (in Claude Code) to re-authenticate"
    else
      warn "Atlassian: $(printf '%s' "$atl" | sed 's/  */ /g')"
    fi
    nauth=$(printf '%s\n' "$mcp" | grep -ciE 'Needs authentication')
    (( nauth > 0 )) && warn "$nauth other MCP server(s) need auth ${DIM}(run /mcp to see which)${RST}"
  fi
else
  warn "claude CLI not on PATH — can't probe MCP health from here"
fi

# --- end-to-end: does a FRESH shell resolve a token from the keyring/files? ---
hdr "End-to-end  ${DIM}(fresh shell via gl-load-creds: env→keyring→files)${RST}"
LOADER="$HOME/.local/bin/gl-load-creds"
E2E=0
if [[ -r $LOADER ]]; then
  # Force-unset env so this proves the keyring/file path, not an inherited var.
  if env -u GITLAB_TOKEN -u GITLAB_HOST bash -c "source '$LOADER' 2>/dev/null; [[ -n \${GITLAB_TOKEN:-} ]]"; then
    ok "a fresh shell resolves GITLAB_TOKEN without inherited env (keyring/file path works)"; E2E=1
  else
    bad "a fresh shell CANNOT resolve GITLAB_TOKEN — run bwu"
  fi
else
  warn "gl-load-creds not found at $LOADER"
fi

# --- verdict ---
# The end-to-end probe is authoritative: presence in @u proves nothing about
# readability (see the perm-byte check above), so it must never OR into a green
# verdict on its own — that exact OR previously reported "Creds are loaded"
# while every shell hydrated empty.
hdr "Verdict"
if (( E2E )); then
  ok "Creds are loaded. Any same-UID process (Claude's Bash tool, the tmux bar,"
  printf '    a new shell) can hydrate by sourcing %sgl-load-creds%s.\n' "$BOLD" "$RST"
  (( PERM_BAD )) && warn "…but some key(s) above are user=VIEW-only and unreadable — ${BOLD}creds-doctor --repair${RST}"
  printf '    %sIf a specific process shows an empty env above, that is a frozen-snapshot%s\n' "$DIM" "$RST"
  printf '    %sissue, not a missing credential:%s\n' "$DIM" "$RST"
  printf '      • this shell now:        %ssource ~/.local/bin/gl-load-creds%s\n' "$BOLD" "$RST"
  printf '      • a stale Claude session: relaunch it from a bwu'"'"'d pane, or just let its\n'
  printf '        Bash calls source gl-load-creds (the gl-*/glab tools already do)\n'
  printf '      • a sibling tmux pane:    %sbw_keyring_hydrate%s (zsh) or source gl-load-creds\n' "$BOLD" "$RST"
elif (( HAVE_KC && KR_TOKEN && PERM_BAD )); then
  bad "Keys are IN the keyring but UNREADABLE (user=VIEW-only): bwu ran from a"
  printf '    shell with a revoked session keyring, so its setperm was denied.\n'
  printf '    Fix: %screds-doctor --repair%s (re-perms via the systemd --user manager),\n' "$BOLD" "$RST"
  printf '    or re-run %sbwu%s — it now verifies and self-heals the same way.\n' "$BOLD" "$RST"
elif (( HAVE_KC && KR_TOKEN )); then
  bad "Keys present and perms look right, yet the end-to-end read failed —"
  printf '    unexpected. Check %sgl-load-creds%s itself and \`keyctl describe @s\`.\n' "$BOLD" "$RST"
else
  bad "Creds NOT available to same-UID processes."
  printf '    Run %sbwu%s once this boot to populate the @u keyring (and re-sync caches).\n' "$BOLD" "$RST"
fi
printf '\n  %sNote:%s subagents inherit this session'"'"'s env (verified); if it was launched before\n' "$DIM" "$RST"
printf '         bwu, they — like the main loop — source gl-load-creds to read the live keyring.\n'
printf '  %sNote:%s MCP auth is a SEPARATE store (checked above), not the keyring jira:token.\n' "$DIM" "$RST"
