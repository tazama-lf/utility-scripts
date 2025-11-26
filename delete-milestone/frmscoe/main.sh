#!/bin/bash

# Usage: ./close_milestones.sh <github_token>

GH_TOKEN="$1"
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GitHub token required as first argument."
  exit 1
fi

ORG="frmscoe"
REPOS_FILE="repos.txt"

if [ ! -f "$REPOS_FILE" ]; then
  echo "Error: $REPOS_FILE not found."
  exit 1
fi

TITLE="Release v2.2.0"

for REPO_NAME in $(cat "$REPOS_FILE"); do
  REPO="${ORG}/${REPO_NAME}"
  echo "Processing repository: $REPO"

  # Fetch existing milestones
  RESPONSE=$(curl -s -X GET \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${REPO}/milestones?state=open")

  # Find matching open milestone
  MILESTONE_NUMBER=$(echo "$RESPONSE" | jq -r ".[] | select(.title == \"$TITLE\" and .state == \"open\") | .number")

  if [ -z "$MILESTONE_NUMBER" ]; then
    echo "No open milestone with title '$TITLE' found in $REPO. Skipping."
    continue
  fi

  # Close the milestone
  UPDATE_RESPONSE=$(curl -s -X PATCH \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "{\"state\":\"closed\"}" \
    "https://api.github.com/repos/${REPO}/milestones/$MILESTONE_NUMBER")

  if echo "$UPDATE_RESPONSE" | grep -q '"state": "closed"'; then
    echo "✅ Successfully closed milestone '$TITLE' in $REPO"
    echo "$UPDATE_RESPONSE" | jq -r '.html_url'
  else
    ERROR_MSG=$(echo "$UPDATE_RESPONSE" | jq -r '.message // "Unknown error"')
    echo "❌ Failed to close milestone in $REPO: $ERROR_MSG"
  fi
done

echo "Finished processing all repositories."