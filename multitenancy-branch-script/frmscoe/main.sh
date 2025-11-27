#!/bin/bash

# Check if repos.txt exists
if [ ! -f repos.txt ]; then
  echo "❌ Error: repos.txt not found"
  exit 1
fi

# Check if GH_TOKEN is set
if [ -z "${GH_TOKEN}" ]; then
  echo "❌ Error: GH_TOKEN environment variable not set"
  exit 1
fi

# Read each repository from repos.txt
while IFS= read -r repo; do
  # Skip empty lines
  [ -z "$repo" ] && continue

  echo "Processing repository: frmscoe/$repo..."

  # Check if the dev branch exists
  dev_branch_check=$(curl -s -H "Authorization: Bearer $GH_TOKEN" \
    https://api.github.com/repos/frmscoe/$repo/branches/dev | jq -r '.name')

  if [ "$dev_branch_check" != "dev" ]; then
    echo "❌ Error: 'dev' branch not found in frmscoe/$repo"
    continue
  fi

  # Create the multitenancy branch using GitHub API
  # Get the latest SHA of the dev branch
  dev_sha=$(curl -s -H "Authorization: Bearer $GH_TOKEN" \
    https://api.github.com/repos/frmscoe/$repo/branches/dev | jq -r '.commit.sha')

  # Create the new branch
  response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Content-Type: application/json" \
    https://api.github.com/repos/frmscoe/$repo/git/refs \
    -d "{\"ref\": \"refs/heads/multitenancy\", \"sha\": \"$dev_sha\"}")

  if [ "$response" -eq 201 ]; then
    echo "✅ Successfully created 'multitenancy' branch in frmscoe/$repo"
  else
    echo "❌ Error: Failed to create 'multitenancy' branch in frmscoe/$repo (HTTP $response)"
  fi

done < repos.txt

echo "🎉 Completed processing all repositories."
