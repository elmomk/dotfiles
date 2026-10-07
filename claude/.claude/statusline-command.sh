#!/bin/sh
input=$(cat)
user=$(whoami)
host=$(hostname -s)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

short_dir=$(echo "$dir" | sed "s|^$HOME|~|")

# Say something when the figure is missing rather than nothing. An empty
# ctx_info renders as a statusline that looks entirely normal apart from one
# absent field, so "the harness sent no context_window" is indistinguishable
# from "the statusline is fine" — which is how this went unnoticed in tmux
# teammate panes. `ctx: ?` is also the diagnostic: seeing it means the field is
# absent from the payload, whereas no statusline at all means the statusline
# itself is not running in that pane.
if [ -n "$used" ]; then
    ctx_info=" | ctx: ${used}%"
else
    ctx_info=" | ctx: ?"
fi

if [ -n "$model" ]; then
    model_info=" | ${model}"
else
    model_info=""
fi

# --- Cloud context (fast: env vars and local config files only, no API calls) ---

# AWS: prefer AWS_PROFILE env var, fall back to AWS_DEFAULT_PROFILE, then "default"
aws_profile="${AWS_PROFILE:-${AWS_DEFAULT_PROFILE:-}}"
if [ -n "$aws_profile" ]; then
    aws_info="aws:${aws_profile}"
else
    aws_info=""
fi

# GCP: read active config file directly (~/.config/gcloud/configurations/config_<active>)
gcloud_config_dir="${HOME}/.config/gcloud"
active_config_file="${gcloud_config_dir}/active_config"
gcp_project=""
gcp_account=""
if [ -f "$active_config_file" ]; then
    active_config=$(cat "$active_config_file" 2>/dev/null)
    config_file="${gcloud_config_dir}/configurations/config_${active_config}"
    if [ -f "$config_file" ]; then
        gcp_project=$(grep -m1 '^\s*project\s*=' "$config_file" 2>/dev/null | sed 's/.*=\s*//' | tr -d '[:space:]')
        gcp_account=$(grep -m1 '^\s*account\s*=' "$config_file" 2>/dev/null | sed 's/.*=\s*//' | tr -d '[:space:]')
    fi
fi
# Allow env vars to override
gcp_project="${GOOGLE_CLOUD_PROJECT:-${GCLOUD_PROJECT:-$gcp_project}}"

# Build cloud context string
cloud_parts=""
if [ -n "$aws_info" ]; then
    cloud_parts="${aws_info}"
fi
if [ -n "$gcp_project" ]; then
    if [ -n "$cloud_parts" ]; then
        cloud_parts="${cloud_parts} | gcp:${gcp_project}"
    else
        cloud_parts="gcp:${gcp_project}"
    fi
fi
if [ -n "$gcp_account" ]; then
    if [ -n "$cloud_parts" ]; then
        cloud_parts="${cloud_parts} (${gcp_account})"
    else
        cloud_parts="(${gcp_account})"
    fi
fi

if [ -n "$cloud_parts" ]; then
    cloud_info=" | ${cloud_parts}"
else
    cloud_info=""
fi

printf "\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m%s%s%s" \
    "$user" "$host" "$short_dir" "$model_info" "$ctx_info" "$cloud_info"

# --- Plan limits, kept for the claude-usage popup (nothing printed) ---
# Claude Code sends subscribers rate_limits once a session has had an API
# response. Only the five-hour and seven-day windows' used_percentage and
# resets_at are taken, into statusline-limits.json in claude-usage's state dir,
# shaped like Claude Code's own /usage cache so the popup reads it the same way.
# The file changes only when a figure does: within a window the percentage
# never goes down, so an idle session re-rendering older figures leaves newer
# ones alone, and a later reset time starts the window afresh. Beside the
# figures it keeps the last ones from before the local day they were replaced
# on. CLAUDE_USAGE_NOW (ISO 8601 with an offset) pins the time, for tests.
# One jq run, only when the payload names rate_limits; every error is silent.
case "$input" in
*'"rate_limits"'*)
    limits_dir="${CLAUDE_USAGE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/claude-usage}"
    limits_file="$limits_dir/statusline-limits.json"
    if [ -f "$limits_file" ]; then
        set -- --rawfile old "$limits_file"
    else
        set -- --arg old ''
    fi
    limits=$(printf '%s' "$input" | jq -c --arg pin "${CLAUDE_USAGE_NOW:-}" "$@" '
        def secs: try fromdateiso8601 catch null;
        def day: floor | strflocaltime("%Y-%m-%d");
        def figure: if type == "object" and (.used_percentage | type) == "number" and (.resets_at | type) == "number"
            then {utilization: .used_percentage, resets_at: (.resets_at | floor | todate)} else null end;
        def kept: if type == "object" and (.utilization | type) == "number" and (.resets_at | type) == "string"
            and (.resets_at | secs) != null then {utilization, resets_at} else null end;
        def windows: if type == "object"
            then {five_hour: (.five_hour | kept), seven_day: (.seven_day | kept)} | with_entries(select(.value != null))
            else {} end;
        def merged($new; $cur; $now):
            if $new == null then (if $cur != null and ($cur.resets_at | secs) > $now then $cur else null end)
            elif $cur == null then $new
            else (($new.resets_at | secs) - ($cur.resets_at | secs)) as $d
                | if $d > 3600 then $new elif $d < -3600 then $cur
                  elif $new.utilization > $cur.utilization then $new else $cur end
            end;
        ($pin | if . == "" then now else
            capture("^(?<d>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(\\.[0-9]+)?(?<z>Z|[+-][0-9]{2}:?[0-9]{2})$")
            | (.d + "Z" | fromdateiso8601) - (if .z == "Z" then 0 else (if .z[0:1] == "-" then -1 else 1 end)
                * ((.z[1:3] | tonumber) * 3600 + (.z[-2:] | tonumber) * 60) end)
        end) as $now
        | (try ($old | fromjson) catch null | if type == "object" then . else {} end) as $o
        | ($o.utilization | windows) as $u
        | (.rate_limits | if type == "object" then . else {} end) as $rl
        | ({five_hour: merged($rl.five_hour | figure; $u.five_hour; $now),
            seven_day: merged($rl.seven_day | figure; $u.seven_day; $now)} | with_entries(select(.value != null))) as $n
        | select($n != {} and $n != $u)
        | ($o.fetchedAtMs | if type == "number" then . else null end) as $at
        | ($o.previous | if type == "object" and (.fetchedAtMs | type) == "number" then . else {} end) as $p
        | {fetchedAtMs: ($now * 1000 | floor), utilization: $n}
          + if $at != null and $u != {} and ($at / 1000 | day) < ($now | day)
            then {previous: {fetchedAtMs: $at, utilization: $u}}
            elif ($p.utilization | windows) != {} then {previous: {fetchedAtMs: $p.fetchedAtMs, utilization: ($p.utilization | windows)}}
            else {} end' 2>/dev/null)
    if [ -n "$limits" ]; then
        (
            umask 077
            mkdir -p "$limits_dir" && chmod 700 "$limits_dir" &&
                printf '%s\n' "$limits" >"$limits_file.$$.tmp" &&
                mv -f "$limits_file.$$.tmp" "$limits_file" || rm -f "$limits_file.$$.tmp"
        ) >/dev/null 2>&1
    fi
    ;;
esac
