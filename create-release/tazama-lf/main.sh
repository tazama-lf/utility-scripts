#!/bin/bash

# Usage: ./create_releases.sh <github_token> <slack_webhook_url>

set -euo pipefail

GH_TOKEN="$1"
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GitHub token required as first argument."
  exit 1
fi

SLACK_WEBHOOK_URL="$2"
if [ -z "$SLACK_WEBHOOK_URL" ]; then
  echo "Error: Slack webhook URL required as second argument."
  exit 1
fi

ORG="tazama-lf"
REPOS_FILE="repos.txt"
RELEASE_TAG="v3.0.0"

if [ ! -f "$REPOS_FILE" ]; then
  echo "Error: $REPOS_FILE not found."
  exit 1
fi

for REPO_NAME in $(cat "$REPOS_FILE"); do
  REPO="${ORG}/${REPO_NAME}"
  echo "Processing repository: $REPO"

  TMP_DIR=$(mktemp -d)
  trap "rm -rf $TMP_DIR" EXIT

  git clone --quiet "https://$GH_TOKEN@github.com/$REPO.git" "$TMP_DIR" || { echo "Failed to clone $REPO"; continue; }
  cd "$TMP_DIR"

  git fetch --tags
  git checkout main

  LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  echo "Last tag for $REPO: ${LAST_TAG:-none}"

  if [ -n "$LAST_TAG" ]; then
    CHANGELOG=$(git log "$LAST_TAG"..HEAD --merges --pretty=format:"- %s (#%h)" | grep "Merge pull request" || true)
  else
    CHANGELOG=$(git log --merges --pretty=format:"- %s (#%h)" | grep "Merge pull request" || true)
  fi

  if [ -z "$CHANGELOG" ]; then
    echo "⚠️ No new merged PRs since last release in $REPO — skipping."
    cd - >/dev/null
    continue
  fi

  RELEASE_NOTES="Changes in $RELEASE_TAG

$CHANGELOG"

  echo "Creating release for $REPO..."
  gh release create "$RELEASE_TAG" --repo "$REPO" --title "$RELEASE_TAG" --notes "$RELEASE_NOTES" --target main

  if [ $? -eq 0 ]; then
    echo "✅ Successfully created release '$RELEASE_TAG' in $REPO"

    curl -s -X POST -H 'Content-type: application/json' --data "{
      \"blocks\": [
        {
          \"type\": \"header\",
          \"text\": {
            \"type\": \"plain_text\",
            \"text\": \"New V3.0.0 Release Alert :tazama:\",
            \"emoji\": true
          }
        },
        {
          \"type\": \"section\",
          \"fields\": [
            {
              \"type\": \"mrkdwn\",
              \"text\": \"*GitHub Repository:*\nhttps://github.com/$REPO\"
            },
            {
              \"type\": \"mrkdwn\",
              \"text\": \"*Release:*\n<https://github.com/$REPO/releases/tag/$RELEASE_TAG|Release notes>\"
            }
          ]
        }
      ]
    }" "$SLACK_WEBHOOK_URL" >/dev/null 2>&1

    echo "✅ Slack notification sent for $REPO"
  else
    echo "❌ Failed to create release in $REPO"
  fi

  cd - >/dev/null
done

echo "🎉 Finished processing all repositories."
