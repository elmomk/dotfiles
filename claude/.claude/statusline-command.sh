#!/bin/sh
input=$(cat)
user=$(whoami)
host=$(hostname -s)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

short_dir=$(echo "$dir" | sed "s|^$HOME|~|")

if [ -n "$used" ]; then
    ctx_info=" | ctx: ${used}%"
else
    ctx_info=""
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
