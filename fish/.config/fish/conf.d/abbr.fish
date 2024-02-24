# ls
abbr ll 'exa -lgh --icons'
abbr la 'exa -lgha '
abbr ls 'exa --icons'

# Defaults
abbr grep 'grep --color=auto'
abbr fgrep 'fgrep --color=auto'
abbr egrep 'egrep --color=auto'
abbr mv 'mv -iv'
abbr rm 'rm -iv'
abbr cp 'cp -iav'
abbr df 'df -h'
abbr free 'free -m'
abbr fuser 'fuser -v'
abbr ping 'ping -c 5'

if type nvim >/dev/null 2>&1
    abbr vim nvim
    abbr vi nvim
end

abbr lg lazygit

# terraform

abbr tf terraform
abbr tg terragrunt
abbr ta 'terragrunt apply'
abbr tp 'terragrunt plan'
abbr tau 'TERRAGRUNT_SOURCE_UPDATE=true terragrunt apply'
abbr tpu 'TERRAGRUNT_SOURCE_UPDATE=true terragrunt plan'

abbr h helm
# Shortcuts
abbr kctx 'kubie ctx'
abbr kns 'kubie ns'
# abbr k kubectl
abbr kube-dashboard 'kubectl auth-proxy -n kubernetes-dashboard https://kubernetes-dashboard.svc'
abbr avl 'aws-vault login'
abbr fly-clean 'fly prune-worker --all-stalled'
abbr tfdocs terraform-docs

# IP address
abbr myip 'dig +short myip.opendns.com @resolver1.opendns.com'

## Expand .. to cd ../, ... to cd ../../ and .... to cd ../../../ and so on.
# https://github.com/fish-shell/fish-shell/releases/tag/3.6.0

function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end

abbr --add dotdot --regex '^\.\.+$' --function multicd

## Expand !! to the last history item
# https://github.com/fish-shell/fish-shell/releases/tag/3.6.0

function last_history_item
    echo $history[1]
end

abbr --add !! --position anywhere --function last_history_item
