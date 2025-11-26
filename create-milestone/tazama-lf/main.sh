#!/bin/bash

# Usage: ./create_milestones.sh <github_token>

GH_TOKEN="$1"
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GitHub token required as first argument."
  exit 1
fi

ORG="tazama-lf"
REPOS_FILE="repos.txt"

if [ ! -f "$REPOS_FILE" ]; then
  echo "Error: $REPOS_FILE not found."
  exit 1
fi

# Milestone details
TITLE="Release v2.2.0"
DUE_ON="2025-08-02T00:00:00Z"
DESCRIPTION="Create Release v2.2.0 release using Github Actions release workflow."

for REPO_NAME in $(cat "$REPOS_FILE"); do
  REPO="${ORG}/${REPO_NAME}"
  echo "Processing repository: $REPO"

  # Fetch existing milestones
  RESPONSE=$(curl -s -X GET \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${REPO}/milestones?state=all")

  # Check if response contains milestones
  MATCHING_MILESTONE=$(echo "$RESPONSE" | jq -r ".[] | select(.title == \"$TITLE\" and .due_on == \"$DUE_ON\" and .description == \"$DESCRIPTION\") | {number, title, due_on, description}")

  if [ -n "$MATCHING_MILESTONE" ]; then
    MILESTONE_NUMBER=$(echo "$MATCHING_MILESTONE" | jq -r '.number')
    echo "✅ Milestone '$TITLE' already exists in $REPO with matching details. No action needed."
    echo "Milestone URL: $(echo "$RESPONSE" | jq -r ".[] | select(.number == $MILESTONE_NUMBER) | .html_url")"
  else
    # Check if a milestone with the same title exists but with different details
    EXISTING_MILESTONE=$(echo "$RESPONSE" | jq -r ".[] | select(.title == \"$TITLE\") | {number, title, due_on, description}")
    if [ -n "$EXISTING_MILESTONE" ]; then
      MILESTONE_NUMBER=$(echo "$EXISTING_MILESTONE" | jq -r '.number')
      # Update existing milestone with new details
      UPDATE_RESPONSE=$(curl -s -X PATCH \
        -H "Authorization: token $GH_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{\"due_on\":\"$DUE_ON\",\"description\":\"$DESCRIPTION\"}" \
        "https://api.github.com/repos/${REPO}/milestones/$MILESTONE_NUMBER")
      if echo "$UPDATE_RESPONSE" | grep -q '"state": "open"'; then
        echo "✅ Updated existing milestone '$TITLE' in $REPO with new details."
        echo "$UPDATE_RESPONSE" | jq -r '.html_url'
      else
        ERROR_MSG=$(echo "$UPDATE_RESPONSE" | jq -r '.message // "Unknown error"')
        echo "❌ Failed to update milestone in $REPO: $ERROR_MSG"
      fi
    else
      # Create new milestone
      CREATE_RESPONSE=$(curl -s -X POST \
        -H "Authorization: token $GH_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{\"title\":\"$TITLE\",\"due_on\":\"$DUE_ON\",\"description\":\"$DESCRIPTION\"}" \
        "https://api.github.com/repos/${REPO}/milestones")
      if echo "$CREATE_RESPONSE" | grep -q '"state": "open"'; then
        echo "✅ Successfully created milestone '$TITLE' in $REPO"
        echo "$CREATE_RESPONSE" | jq -r '.html_url'
      else
        ERROR_MSG=$(echo "$CREATE_RESPONSE" | jq -r '.message // "Unknown error"')
        echo "❌ Failed to create milestone in $REPO: $ERROR_MSG"
      fi
    fi
  fi
done

echo "Finished processing all repositories."
