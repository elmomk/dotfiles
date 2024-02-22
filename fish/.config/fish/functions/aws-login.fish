function aws-login
  aws-vault login $(grep -w profile ~/.aws/config | tr -d "[]" | awk '{print $2}' | fzf --prompt="<U+E62B>  AWS_PROFILE <U+F63D> " --height=~50% --layout=reverse --border --exit-0)
end
