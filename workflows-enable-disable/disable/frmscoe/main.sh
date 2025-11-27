#!/bin/bash

# Usage: ./disable_workflows.sh <github_token>

GH_TOKEN="$1"
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GitHub token required as first argument."
  exit 1
fi

export GITHUB_TOKEN="$GH_TOKEN"

ORG="frmscoe"
REPOS_FILE="repos.txt"
WORKFLOWS=("node.js.yml")

if [ ! -f "$REPOS_FILE" ]; then
  echo "Error: $REPOS_FILE not found."
  exit 1
fi

for REPO_NAME in $(cat "$REPOS_FILE"); do
  REPO="$ORG/$REPO_NAME"
  echo "Processing repository: $REPO"

  for WF in "${WORKFLOWS[@]}"; do
    echo "Checking workflow: $WF"

    # Get workflow details
    WF_DETAILS=$(gh api repos/$REPO/actions/workflows --jq ".workflows[] | select(.path == \".github/workflows/$WF\") | {id: .id, state: .state}")

    if [ -z "$WF_DETAILS" ]; then
      echo "Workflow $WF does not exist in $REPO. Skipping."
      continue
    fi

    WF_ID=$(echo "$WF_DETAILS" | jq -r '.id')
    WF_STATE=$(echo "$WF_DETAILS" | jq -r '.state')

    if [ "$WF_STATE" == "disabled_manually" ] || [ "$WF_STATE" == "disabled_inactivity" ]; then
      echo "Workflow $WF is already disabled in $REPO. Skipping."
    else
      gh workflow disable "$WF_ID" --repo $REPO
      echo "Disabled workflow $WF in $REPO."
    fi
  done

  echo "Finished processing $REPO."
done
