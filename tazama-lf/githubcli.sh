#!/bin/bash

REPOS=(
  "relay-service"
  "auth-service"
  "typology-processor"
  "event-director"
  "event-sidecar"
  "lumberjack"
  "nats-utilities"
  "batch-ppa"
  "admin-service"
  "tms-service"
  "transaction-aggregation-decisioning-processor"
  "Full-Stack-Docker-Tazama"
  "rule-executer"
  "event-flow"
  "frms-coe-lib"
  "frms-coe-startup-lib"
  "auth-lib"
  "rule-901"
)

BRANCHES=(
  "main"
  "dev"
)
ORG="tazama-lf"

for repo in "${REPOS[@]}"; do
  for branch in "${BRANCHES[@]}"; do
    echo "🔐 Protecting $repo/$branch"
    gh api --method PUT \
      -H "Accept: application/vnd.github.v3+json" \
      /repos/$ORG/$repo/branches/$branch/protection \
      --input protection.json
  done
done

