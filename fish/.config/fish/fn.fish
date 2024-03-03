function aws-login
  aws-vault login $(grep -w profile ~/.aws/config | tr -d "[]" | awk '{print $2}' | fzf --prompt="<U+E62B>  AWS_PROFILE <U+F63D> " --height=~50% --layout=reverse --border --exit-0)
end

function aws-profile
  export AWS_PROFILE=$(grep -w profile ~/.aws/config | tr -d "[]" | awk '{print $2}' | fzf --prompt="<U+E62B>  AWS_PROFILE <U+F63D> " --height=~50% --layout=reverse --border --exit-0)
end

function kubeconfig-eks
  if env | grep AWS_PROFILE
    set PROFILE (env | grep AWS_PROFILE | cut -d'=' -f2 | tr -d '[:space:]')
  else
    aws-profile
    set PROFILE (env | grep AWS_PROFILE | cut -d'=' -f2 | tr -d '[:space:]')
  end
  set REGION (aws configure get region)
  set CLUSTER_NAME (aws eks list-clusters --output json | jq -r '.clusters[]' | fzf --prompt="< EKS Cluster > " --height=~50% --layout=reverse --border --exit-0)
  aws eks update-kubeconfig --name $CLUSTER_NAME --alias $CLUSTER_NAME-aws --region $REGION --profile $PROFILE --kubeconfig ~/.kube/aws-configs/$CLUSTER_NAME.yml
end

function scandir
  set RECURSIVE ""
  if not test $argv[1]
    set location (pwd)
  else
    set location (pwd)/$argv[1]
  end
  if test $argv[2]
    echo "recursive"
    set RECURSIVE "-r"
  end
  echo "start scanning $location"
  docker run -it --rm \
  --mount type=bind,source=$location,target=/scandir \
  clamav/clamav:unstable \
  clamscan /scandir $RECURSIVE
end

function nvims
    # local nvim_config
    # nvim_config=$(find ~/.config/nvim -maxdepth 1 -type d -exec basename {} \; | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)
    # nvim_config=(printf "%s\n" "${items[@]}" | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)
    # set items "default" "latestmovim" "kickstart" "LazyVim" "NvChad" "AstroNvim" "sevim"
    # set nvim_config "(printf "%s\n" "${items[@]}" | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)"
    set nvim_config "mo-vim"
    # if [[ -z $nvim_config ]]; then
    #     echo "Nothing selected"
    #     return 0
      # end
    NVIM_APPNAME=$nvim_config nvim $argv
end

function test_hello
  if test $argv[1]
    echo $argv[1]
  else
    echo "Hello World"
  end
end
