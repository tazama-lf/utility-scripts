#!/bin/bash

# Usage: ./merge_prs.sh
# Ensure GitHub CLI is authenticated before running (gh auth login if needed)

# Array of PRs with repo and PR number
PR_LIST=(
  # list the prs in the format listed below "GITHUB-ORG/GITHUB-REPO PR-NUMBER" e.g
  "tazama-lf/relay-service 71"
  "frmscoe/rule-001 155"
  "frmscoe/rule-002 119"
  "frmscoe/rule-003 127"
  "tazama-lf/relay-service-integration-rest 5"
  "tazama-lf/rule-901 150"
  "tazama-lf/rule-executer 282"
)

# Check if gh is authenticated
if ! gh auth status > /dev/null 2>&1; then
  echo "Error: GitHub CLI not authenticated. Please run 'gh auth login'."
  exit 1
fi

# Loop through PRs and approve
for pr in "${PR_LIST[@]}"; do
  # Split repo and PR number
  IFS=' ' read -r REPO PR_NUMBER <<< "$pr"
  echo "Approving PR #$PR_NUMBER in $REPO"

  # Approve the PR
  if gh pr review "$PR_NUMBER" --repo "$REPO" --approve > /dev/null 2>&1; then
    echo "✅ Successfully approved PR #$PR_NUMBER in $REPO"
  else
    ERROR_MSG=$(gh pr review "$PR_NUMBER" --repo "$REPO" --approve 2>&1)
    echo "❌ Failed to approve PR #$PR_NUMBER in $REPO: $ERROR_MSG"
  fi

  # Optional: Merge the PR (uncomment if you want to merge immediately)
  if gh pr merge "$PR_NUMBER" --repo "$REPO" --merge > /dev/null 2>&1; then
    echo "✅ Merged PR #$PR_NUMBER in $REPO"
  else
    echo "❌ Failed to merge PR #$PR_NUMBER in $REPO"
  fi

  sleep 1  # Add delay to avoid rate limiting
done

echo "Finished processing all PRs."
