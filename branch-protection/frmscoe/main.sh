#!/bin/bash

# Usage: ./main.sh

# Define arrays
REPOS=(
  rule-001
  rule-002
  rule-003
  rule-004
  rule-006
  rule-007
  rule-008
  rule-010
  rule-011
  rule-016
  rule-017
  rule-018
  rule-020
  rule-021
  rule-024
  rule-025
  rule-026
  rule-027
  rule-028
  rule-030
  rule-044
  rule-045
  rule-048
  rule-054
  rule-063
  rule-074
  rule-075
  rule-076
  rule-078
  rule-083
  rule-084
  rule-090
  rule-091
  rule-cli
  payment-platform-adapter
  workflows
  tms-configuration
  rule-tests
  performance-benchmark
  config-service
)

BRANCHES=("main" "dev" "multitenancy")
ORG="frmscoe"

# Ensure gh is authenticated
if ! gh auth status > /dev/null 2>&1; then
  echo "Error: GitHub CLI not authenticated. Please run 'gh auth login'."
  exit 1
fi

for repo in "${REPOS[@]}"; do
  for branch in "${BRANCHES[@]}"; do
    echo "🔐 Processing $ORG/$repo/$branch"
    # Attempt to set branch protection with no pager and timeout
    gh api --method PUT --paginate=false \
      -H "Accept: application/vnd.github.v3+json" \
      "/repos/$ORG/$repo/branches/$branch/protection" \
      --input protection.json > /tmp/output.log 2>> /tmp/error.log || {
      ERROR_MSG=$(cat /tmp/error.log)
      if echo "$ERROR_MSG" | grep -q "404"; then
        echo "❌ $ORG/$repo/$branch not found or not protected"
      elif echo "$ERROR_MSG" | grep -q "403"; then
        echo "❌ Permission denied for $ORG/$repo/$branch. Check token scopes."
      else
        echo "❌ Failed to protect $ORG/$repo/$branch: $ERROR_MSG"
      fi
      continue
    }
    echo "✅ Successfully protected $ORG/$repo/$branch"
    sleep 1  # Add delay to avoid rate limiting
  done
done

echo "Finished processing all repositories."
