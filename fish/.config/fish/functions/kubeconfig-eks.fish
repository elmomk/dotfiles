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
