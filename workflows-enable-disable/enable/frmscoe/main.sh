#!/bin/bash

# Usage: ./enable_workflow.sh <github_token>

GH_TOKEN="$1"
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GitHub token required as first argument."
  exit 1
fi

export GITHUB_TOKEN="$GH_TOKEN"

ORG="frmscoe"  # Set to frmscoe initially; change to tazama-lf manually later
REPOS_FILE="repos.txt"
WORKFLOW_NAMES=("package-rule-rc.yml")

if [ ! -f "$REPOS_FILE" ]; then
  echo "Error: $REPOS_FILE not found."
  exit 1
fi

for REPO_NAME in $(cat "$REPOS_FILE"); do
  REPO="$ORG/$REPO_NAME"
  echo "Processing repository: $REPO"

  for WF_NAME in "${WORKFLOW_NAMES[@]}"; do
    echo "Checking workflow: $WF_NAME"

    # Get workflow details
    WF_DETAILS=$(gh api repos/$REPO/actions/workflows --jq ".workflows[] | select(.name == \"$WF_NAME\" or .path == \".github/workflows/$WF_NAME\") | {id: .id, state: .state, triggers: .triggers}")

    if [ -z "$WF_DETAILS" ]; then
      echo "Workflow $WF_NAME does not exist in $REPO. Skipping."
      continue
    fi

    WF_ID=$(echo "$WF_DETAILS" | jq -r '.id')
    WF_STATE=$(echo "$WF_DETAILS" | jq -r '.state')

    if [ "$WF_STATE" == "active" ]; then
      echo "Workflow $WF_NAME is already enabled in $REPO. Skipping."
    else
      gh workflow enable "$WF_ID" --repo $REPO
      echo "Enabled workflow $WF_NAME in $REPO."
    fi

    # Manually trigger workflow if workflow_dispatch is supported (commented out for first run)
    # Uncomment the following block for the second run to trigger manually
    # HAS_DISPATCH=$(echo "$WF_DETAILS" | jq -r '.triggers[] | select(.type == "workflow_dispatch")')
    # if [ -n "$HAS_DISPATCH" ]; then
    #   gh workflow run "$WF_NAME" --repo "$REPO" || echo "Failed to trigger $WF_NAME in $REPO"
    #   echo "Manually triggered workflow $WF_NAME in $REPO."
    # else
    #   echo "Workflow $WF_NAME in $REPO does not support workflow_dispatch. Skipping trigger."
    # fi
  done

  echo "Finished processing $REPO."
done
