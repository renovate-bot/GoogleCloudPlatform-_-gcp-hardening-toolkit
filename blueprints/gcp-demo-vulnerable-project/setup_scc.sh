#!/bin/bash

# This script helps enable SCC services required for the demo.
# Note: You need organization-level permissions to run these commands.

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <ORGANIZATION_ID> <QUOTA_PROJECT_ID>"
  exit 1
fi

ORG_ID=$1
PROJECT_ID=$2

SERVICES=(
  "security-health-analytics"
  "event-threat-detection"
)

for service in "${SERVICES[@]}"; do
  echo "Enabling $service for organization $ORG_ID..."
  gcloud alpha scc settings services enable \
    --service="$service" \
    --organization="$ORG_ID" \
    --billing-project="$PROJECT_ID"
done

echo "SCC Services enabled."
