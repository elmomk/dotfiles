#!/bin/bash -xe

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
  echo "This script requires 'gum'. Install it via: brew install gum / go install github.com/charmbracelet/gum@latest"
  exit 1
fi

# 1. Identify current user
CURRENT_USER=$(gcloud auth list --filter="status:ACTIVE" --format="value(account)")

gum style \
  --foreground 212 --border-foreground 212 --border double \
  --align center --width 50 --margin "1 2" --padding "1 2" \
  "Gateway IAM Checker" "Current User: $CURRENT_USER"

# 2. Select Project
gum spin --spinner dot --title "Fetching projects..." -- sleep 1
PROJECT_ID=$(gcloud projects list --format="value(projectId)" | gum filter --placeholder "Select project to check...")

if [ -z "$PROJECT_ID" ]; then
  echo "No project selected. Exiting."
  exit 1
fi

# 3. Define the Gateway roles we are looking for
GATEWAY_ROLES=(
  "roles/gkehub.gatewayAdmin"
  "roles/gkehub.gatewayEditor"
  "roles/gkehub.gatewayReader"
)

echo "Checking IAM roles for $CURRENT_USER in $PROJECT_ID..."

# 4. Fetch IAM Policy and filter
USER_ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:$CURRENT_USER" \
  --format="value(bindings.role)")

# 5. Result Visualization
FOUND_ANY=false
echo ""
gum style --bold "Results:"

for role in "${GATEWAY_ROLES[@]}"; do
  if echo "$USER_ROLES" | grep -q "$role"; then
    gum style --foreground 10 "  [✔] $role"
    FOUND_ANY=true
  else
    gum style --foreground 9 "  [✘] $role"
  fi
done

echo ""

if [ "$FOUND_ANY" = false ]; then
  gum style --background 1 --foreground 15 --padding "0 1" " ERROR " "User lacks Connect Gateway roles."
  echo "This explains the 400 error. You likely need 'roles/gkehub.gatewayAdmin'."

  if gum confirm "Would you like to see the command to grant this role?"; then
    echo "gcloud projects add-iam-policy-binding $PROJECT_ID --member='user:$CURRENT_USER' --role='roles/gkehub.gatewayAdmin'"
  fi
else
  gum style --background 2 --foreground 15 --padding "0 1" " SUCCESS " "IAM roles found."
  echo "If you still get a 400, check if the Fleet Membership is active:"
  echo "gcloud container fleet memberships list --project=$PROJECT_ID"
fi
