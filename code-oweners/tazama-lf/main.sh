#!/bin/bash

# Usage: ./add_codeowners.sh <github_token>

GH_TOKEN="$1"
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GitHub token required as first argument."
  exit 1
fi

export GITHUB_TOKEN="$GH_TOKEN"

ORG="tazama-lf"  # Focus on frmscoe; change to tazama-lf manually later
REPOS_FILE="repos.txt"

if [ ! -f "$REPOS_FILE" ]; then
  echo "Error: $REPOS_FILE not found."
  exit 1
fi

for REPO_NAME in $(cat "$REPOS_FILE"); do
  REPO="$ORG/$REPO_NAME"
  echo "Processing repository: $REPO"

  TMP_DIR=$(mktemp -d)
  trap "rm -rf $TMP_DIR" EXIT

  git clone "https://$GH_TOKEN@github.com/$REPO.git" "$TMP_DIR" || {
    echo "❌ Failed to clone $REPO"
    continue
  }
  cd "$TMP_DIR" || {
    echo "❌ Failed to cd into $TMP_DIR for $REPO"
    continue
  }

  # Create .github directory if it doesn't exist
  mkdir -p .github

  CODEOWNERS_PATH=".github/CODEOWNERS"
  CODEOWNERS_CONTENT="* @Justus-at-Tazama @Sandy-at-Tazama @scott45"
  UPDATED=false

  if [ -f "$CODEOWNERS_PATH" ]; then
    echo "CODEOWNERS file exists in $REPO. Checking content."
    CURRENT_OWNERS=$(cat "$CODEOWNERS_PATH" | grep -o '@[A-Za-z0-9_-]*' | sort | uniq)
    EXPECTED_OWNERS=("Justus-at-Tazama" "Sandy-at-Tazama" "scott45")
    MISSING_OWNERS=()

    for OWNER in "${EXPECTED_OWNERS[@]}"; do
      if ! echo "$CURRENT_OWNERS" | grep -q "$OWNER"; then
        MISSING_OWNERS+=("$OWNER")
      fi
    done

    if [ ${#MISSING_OWNERS[@]} -eq 0 ]; then
      echo "All required owners already present in $REPO. Skipping."
    else
      echo "Adding missing owners: ${MISSING_OWNERS[*]} to $REPO."
      echo "$CODEOWNERS_CONTENT" > "$CODEOWNERS_PATH"
      UPDATED=true
    fi
  else
    echo "CODEOWNERS file does not exist in $REPO. Creating it."
    echo "$CODEOWNERS_CONTENT" > "$CODEOWNERS_PATH"
    UPDATED=true
  fi

  if $UPDATED; then
    git checkout -b rc1
    git add "$CODEOWNERS_PATH"
    git commit -S --signoff -m "feat: add CODEOWNERS file" || {
      echo "❌ Failed to commit changes in $REPO"
      cd - >/dev/null
      continue
    }
    echo "Committed changes."

    git push origin rc1 || {
      echo "❌ Failed to push changes to rc1 branch in $REPO"
      cd - >/dev/null
      continue
    }
    echo "Pushed to rc1 branch."

    # Check for existing PR
    PR_NUMBER=$(gh pr list --head rc1 --base dev --json number --jq '.[0].number // ""')

    if [ -z "$PR_NUMBER" ]; then
      echo "No existing PR found. Creating new PR."

      # Check and collect labels using gh api
      LABELS=()
      for LABEL in build enhancement CICD; do
        if gh api repos/$REPO/labels --jq '.[].name' | grep -q "^$LABEL$"; then
          LABELS+=("$LABEL")
        fi
      done
      LABEL_ARGS=""
      if [ ${#LABELS[@]} -gt 0 ]; then
        LABEL_ARGS="--label $(IFS=','; echo "${LABELS[*]}")"
      fi

      gh pr create --base dev --head rc1 --title "feat: Add CODEOWNERS file" --body "# SPDX-License-Identifier: Apache-2.0

## What did we change?
Add codeowners file

## Why are we doing this?
Integrate Tazama product team into the code review process

## How was it tested?
- [ ] Locally
- [x] Development Environment
- [x] Not needed, changes very basic
- [ ] Husky successfully run
- [ ] Unit tests passing and Documentation done" --assignee @Justus-at-Tazama --reviewer Justus-at-Tazama,Sandy-at-Tazama $LABEL_ARGS || {
        echo "❌ Failed to create PR for $REPO"
        cd - >/dev/null
        continue
      }
      echo "PR created."
    else
      echo "Existing PR found (#$PR_NUMBER). Updated via push."
    fi
  else
    echo "No updates needed for $REPO."
  fi

  cd - >/dev/null
  echo "Finished processing $REPO."
done
