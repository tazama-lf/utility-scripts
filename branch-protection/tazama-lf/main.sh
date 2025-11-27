#!/bin/bash

# Usage: ./main.sh

# Define arrays
REPOS=(
  event-flow
  event-sidecar
  admin-service
  typology-processor
  relay-service
  auth-service
  nats-utilities
  event-director
  transaction-aggregation-decisioning-processor
  tms-service
  lumberjack
  relay-service-integration-kafka
  relay-service-integration-rabbitmq
  relay-service-integration-rest
  relay-service-integration-nats
  frms-coe-lib
  case-management-system
  docs
  rule-executer
  batch-ppa
  tazama-demo
  auth-lib-provider-keycloak
  auth-lib
  frms-coe-startup-lib
  rule-901
  rule-902
  cms-service
  Full-Stack-Docker-Tazama
  EKS-helm
  GKE-helm
  AKS-helm
  On-Prem-helm
  workflows
  postman
  data-enrichment-service
  event-monitoring-service
  tcs-lib
  connection-studio
)

BRANCHES=("main" "dev" "multitenancy")
ORG="tazama-lf"

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
