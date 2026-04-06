#!/bin/sh
input=$(cat)

# Log raw JSON for inspection
echo "$input" > /tmp/claude-statusline-debug.json

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir=$(basename "$cwd")
branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null || true)

# Colors (ANSI)
green='\033[1;32m'
cyan='\033[0;36m'
blue='\033[1;34m'
branch_red='\033[0;31m'
yellow='\033[0;33m'
dim='\033[2m'
reset='\033[0m'

# --- Extract all available session fields ---

# Model
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Session name / id
session_name=$(echo "$input" | jq -r '.session_name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
# Use first 8 chars of session_id as short id
short_id=$(echo "$session_id" | cut -c1-8)

# Version
version=$(echo "$input" | jq -r '.version // empty')

# Output style
output_style=$(echo "$input" | jq -r '.output_style.name // empty')

# Vim mode
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# Agent
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
agent_type=$(echo "$input" | jq -r '.agent.type // empty')

# Worktree
worktree_name=$(echo "$input" | jq -r '.worktree.name // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')

# Context window fields
ctx_used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
ctx_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
ctx_total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

# Current usage (last API call)
cur_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
cur_output=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
cur_cache_write=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // empty')
cur_cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // empty')

# --- Build git info ---
if [ -n "$branch" ]; then
  if git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null && \
     git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
    git_info="${blue}git:(${branch_red}${branch}${blue})${reset}"
  else
    git_info="${blue}git:(${branch_red}${branch}${blue}) ${yellow}✗${reset}"
  fi
else
  git_info=""
fi

# --- Build context usage line ---
ctx_parts=""
if [ -n "$ctx_used_pct" ]; then
  used_int=$(printf "%.0f" "$ctx_used_pct")
  ctx_parts="${ctx_parts}ctx:${used_int}%"
fi
if [ -n "$ctx_window_size" ]; then
  win_k=$(( ctx_window_size / 1000 ))
  ctx_parts="${ctx_parts} win:${win_k}k"
fi
if [ -n "$ctx_total_input" ] && [ -n "$ctx_total_output" ]; then
  total_k=$(( (ctx_total_input + ctx_total_output) / 1000 ))
  ctx_parts="${ctx_parts} total:${total_k}k"
fi
if [ -n "$cur_input" ]; then
  cur_k=$(( cur_input / 1000 ))
  ctx_parts="${ctx_parts} in:${cur_k}k"
fi
if [ -n "$cur_output" ]; then
  ctx_parts="${ctx_parts} out:${cur_output}"
fi
if [ -n "$cur_cache_read" ] && [ "$cur_cache_read" != "0" ]; then
  cache_r_k=$(( cur_cache_read / 1000 ))
  ctx_parts="${ctx_parts} cr:${cache_r_k}k"
fi
if [ -n "$cur_cache_write" ] && [ "$cur_cache_write" != "0" ]; then
  cache_w_k=$(( cur_cache_write / 1000 ))
  ctx_parts="${ctx_parts} cw:${cache_w_k}k"
fi

# --- Build session meta line ---
meta_parts=""
if [ -n "$model" ]; then
  meta_parts="${meta_parts}${model}"
fi
if [ -n "$session_name" ]; then
  meta_parts="${meta_parts} \"${session_name}\""
elif [ -n "$short_id" ]; then
  meta_parts="${meta_parts} [${short_id}]"
fi
if [ -n "$version" ]; then
  meta_parts="${meta_parts} v${version}"
fi
if [ -n "$output_style" ] && [ "$output_style" != "default" ]; then
  meta_parts="${meta_parts} style:${output_style}"
fi
if [ -n "$vim_mode" ]; then
  meta_parts="${meta_parts} vim:${vim_mode}"
fi
if [ -n "$agent_name" ]; then
  meta_parts="${meta_parts} agent:${agent_name}"
  [ -n "$agent_type" ] && meta_parts="${meta_parts}(${agent_type})"
fi
if [ -n "$worktree_name" ]; then
  meta_parts="${meta_parts} worktree:${worktree_name}"
  [ -n "$worktree_branch" ] && meta_parts="${meta_parts}@${worktree_branch}"
fi

# --- Assemble added dirs ---
added_dirs=$(echo "$input" | jq -r '.workspace.added_dirs[]? // empty' 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
if [ -n "$added_dirs" ]; then
  meta_parts="${meta_parts} dirs:${added_dirs}"
fi

# --- Print prompt line ---
if [ -n "$git_info" ]; then
  printf "${green}➜${reset}  ${cyan}%s${reset} %b" "$dir" "$git_info"
else
  printf "${green}➜${reset}  ${cyan}%s${reset}" "$dir"
fi

# Append session meta if available
if [ -n "$meta_parts" ]; then
  printf " ${dim}|  %s${reset}" "$meta_parts"
fi
printf "\n"

# --- Print context line (only if we have context data) ---
if [ -n "$ctx_parts" ]; then
  printf "${dim}   %s${reset}\n" "$ctx_parts"
fi
