#!/usr/bin/env bash
# Script Name: export_org_state.sh
# Purpose: Exports both CAI and SCC state for an organization.

ORG_ID=${1:-}
BILLING_PROJECT=${2:-}
CAI_DATASET_NAME=${3:-"hardening_agent_org_cai"}
BUCKET_NAME=${4:-"hardening-agent-org-scc-state-${BILLING_PROJECT}"}

if [[ -z "$ORG_ID" || -z "$BILLING_PROJECT" ]]; then
  echo "Execution aborted: Organization ID and Billing Project ID are required."
  echo "Usage: $0 <ORG_ID> <BILLING_PROJECT_ID> [CAI_DATASET_NAME] [BUCKET_NAME]"
  exit 1
fi

echo "--- Enabling required APIs in billing project: ${BILLING_PROJECT} ---"
gcloud services enable cloudasset.googleapis.com --project="${BILLING_PROJECT}" --quiet
gcloud services enable securitycenter.googleapis.com --project="${BILLING_PROJECT}" --quiet
echo "APIs enabled."

echo ""
echo "--- Exporting Organization-wide Cloud Asset Inventory (CAI) state ---"
echo "Ensuring BigQuery dataset '${CAI_DATASET_NAME}' exists in ${BILLING_PROJECT}..."
bq mk --force --dataset "${BILLING_PROJECT}:${CAI_DATASET_NAME}" 2>/dev/null || true

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CAI_TABLE_NAME="org_cai_state_${TIMESTAMP}"
FULLY_QUALIFIED_CAI_TABLE="projects/${BILLING_PROJECT}/datasets/${CAI_DATASET_NAME}/tables/${CAI_TABLE_NAME}"

IAM_TABLE_NAME="org_iam_policy_${TIMESTAMP}"
FULLY_QUALIFIED_IAM_TABLE="projects/${BILLING_PROJECT}/datasets/${CAI_DATASET_NAME}/tables/${IAM_TABLE_NAME}"

echo "Initiating Organization-wide CAI resource export for Org: ${ORG_ID}..."
EXPORT_OUT=$(gcloud asset export
  --organization="${ORG_ID}"
  --billing-project="${BILLING_PROJECT}"
  --asset-types="compute.googleapis.com/Instance,compute.googleapis.com/Firewall,compute.googleapis.com/Address,iam.googleapis.com/ServiceAccount,iam.googleapis.com/ServiceAccountKey,accesscontextmanager.googleapis.com/ServicePerimeter,accesscontextmanager.googleapis.com/AccessLevel,storage.googleapis.com/Bucket"
  --content-type=resource
  --bigquery-table="${FULLY_QUALIFIED_CAI_TABLE}"
  --output-bigquery-force 2>&1)
echo "$EXPORT_OUT"
OP_PATH=$(echo "$EXPORT_OUT" | grep -oE "organizations/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

echo "Initiating Organization-wide CAI IAM policy export for Org: ${ORG_ID}..."
EXPORT_IAM_OUT=$(gcloud asset export
  --organization="${ORG_ID}"
  --billing-project="${BILLING_PROJECT}"
  --content-type=iam-policy
  --bigquery-table="${FULLY_QUALIFIED_IAM_TABLE}"
  --output-bigquery-force 2>&1)
echo "$EXPORT_IAM_OUT"
OP_PATH_IAM=$(echo "$EXPORT_IAM_OUT" | grep -oE "organizations/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

if [[ -z "$OP_PATH" ]] || [[ -z "$OP_PATH_IAM" ]]; then
  echo "Execution aborted: Failed to extract operation path for one or both CAI exports."
fi
echo "CAI exports triggered."

echo ""
echo "--- Exporting Organization-wide Security Command Center (SCC) findings ---"
echo "Ensuring Cloud Storage bucket '${BUCKET_NAME}' exists in ${BILLING_PROJECT}..."
gcloud storage buckets create "gs://${BUCKET_NAME}" --project="${BILLING_PROJECT}" 2>/dev/null || true

SCC_FILE_NAME="scc_findings_org_${ORG_ID}_${TIMESTAMP}.json"
GCS_PATH="gs://${BUCKET_NAME}/${SCC_FILE_NAME}"

echo "Initiating Organization-wide SCC findings export for Org: ${ORG_ID} to ${GCS_PATH}..."
gcloud scc findings list "organizations/${ORG_ID}"
  --location="global"
  --billing-project="${BILLING_PROJECT}"
  --format="json" > "/tmp/${SCC_FILE_NAME}"

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to list SCC findings."
  rm -f "/tmp/${SCC_FILE_NAME}"
else
  gcloud storage cp "/tmp/${SCC_FILE_NAME}" "${GCS_PATH}"
  if [[ $? -eq 0 ]]; then
    echo "SCC Export complete: ${GCS_PATH}"
  else
    echo "Error: Failed to upload SCC findings to Cloud Storage."
  fi
  rm "/tmp/${SCC_FILE_NAME}"
fi

echo ""
echo "--- All exports triggered ---"
echo "To check CAI resource export status: gcloud asset operations describe "${OP_PATH}" --billing-project="${BILLING_PROJECT}""
echo "To check CAI IAM policy export status: gcloud asset operations describe "${OP_PATH_IAM}" --billing-project="${BILLING_PROJECT}""
echo "SCC findings exported to ${GCS_PATH}"
