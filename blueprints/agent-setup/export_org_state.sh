#!/usr/bin/env bash
# Script Name: export_org_state.sh
# Purpose: Org-wide CAI and SCC state export with billing project delegation.

BILLING_PROJECT=${1:-}
DATASET_NAME=${2:-}
BUCKET_NAME=${3:-}
ORG_ID=${4:-}

if [[ -z "$BILLING_PROJECT" || -z "$DATASET_NAME" || -z "$BUCKET_NAME" || -z "$ORG_ID" ]]; then
  echo "Execution aborted: Billing Project ID, Dataset Name, Bucket Name and Organization ID are required."
  echo "Usage: $0 <BILLING_PROJECT_ID> <DATASET_NAME> <BUCKET_NAME> <ORG_ID>"
  exit 1
fi

# --- CAI Export ---

echo "Ensuring Cloud Asset API is enabled in billing project: ${BILLING_PROJECT}..."
gcloud services enable cloudasset.googleapis.com --project="${BILLING_PROJECT}" --quiet

echo "Ensuring BigQuery dataset '${DATASET_NAME}' exists in ${BILLING_PROJECT}..."
bq mk --force --dataset "${BILLING_PROJECT}:${DATASET_NAME}" 2>/dev/null || true

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TABLE_NAME="org_cai_state_${TIMESTAMP}"
# Note: The table path for Org exports uses the 'projects/...' syntax for the destination
FULLY_QUALIFIED_TABLE="projects/${BILLING_PROJECT}/datasets/${DATASET_NAME}/tables/${TABLE_NAME}"

IAM_TABLE_NAME="org_iam_policy_${TIMESTAMP}"
FULLY_QUALIFIED_IAM_TABLE="projects/${BILLING_PROJECT}/datasets/${DATASET_NAME}/tables/${IAM_TABLE_NAME}"

echo "Initiating Organization-wide CAI resource export for Org: ${ORG_ID}..."

# We use --organization and --billing-project to cross the project boundary
EXPORT_OUT=$(gcloud asset export
  --organization="${ORG_ID}"
  --billing-project="${BILLING_PROJECT}"
  --asset-types="compute.googleapis.com/Instance,compute.googleapis.com/Firewall,compute.googleapis.com/Address,iam.googleapis.com/ServiceAccount,iam.googleapis.com/ServiceAccountKey,accesscontextmanager.googleapis.com/ServicePerimeter,accesscontextmanager.googleapis.com/AccessLevel,storage.googleapis.com/Bucket"
  --content-type=resource
  --bigquery-table="${FULLY_QUALIFIED_TABLE}"
  --output-bigquery-force 2>&1)

echo "$EXPORT_OUT"

# Extract Operation Path with support for underscores
OP_PATH=$(echo "$EXPORT_OUT" | grep -oE "organizations/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

echo "Initiating Organization-wide CAI IAM policy export for Org: ${ORG_ID}..."

EXPORT_IAM_OUT=$(gcloud asset export
  --organization="${ORG_ID}"
  --billing-project="${BILLING_PROJECT}"
  --content-type=iam-policy
  --bigquery-table="${FULLY_QUALIFIED_IAM_TABLE}"
  --output-bigquery-force 2>&1)

echo "$EXPORT_IAM_OUT"

# Extract Operation Path for IAM export
OP_PATH_IAM=$(echo "$EXPORT_IAM_OUT" | grep -oE "organizations/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

if [[ -z "$OP_PATH" ]] || [[ -z "$OP_PATH_IAM" ]]; then
  echo "Execution aborted: Failed to extract operation path for one or both exports. Check permissions."
  exit 1
fi

echo "----------------------------------------------------------------"
echo "Org CAI Exports Triggered successfully."
echo "To check resource export status: gcloud asset operations describe "${OP_PATH}" --billing-project="${BILLING_PROJECT}""
echo "To check IAM policy export status: gcloud asset operations describe "${OP_PATH_IAM}" --billing-project="${BILLING_PROJECT}""
echo "Data destinations:"
echo "  Resource Table: ${BILLING_PROJECT}.${DATASET_NAME}.${TABLE_NAME}"
echo "  IAM Policy Table: ${BILLING_PROJECT}.${DATASET_NAME}.${IAM_TABLE_NAME}"

# --- SCC Export ---

echo "Ensuring Security Command Center API is enabled in billing project: ${BILLING_PROJECT}..."
gcloud services enable securitycenter.googleapis.com --project="${BILLING_PROJECT}" --quiet

echo "Ensuring Cloud Storage bucket '${BUCKET_NAME}' exists in ${BILLING_PROJECT}..."
gcloud storage buckets create "gs://${BUCKET_NAME}" --project="${BILLING_PROJECT}" 2>/dev/null || true

TIMESTAMP_SCC=$(date +%Y%m%d_%H%M%S)
FILE_NAME="scc_findings_org_${ORG_ID}_${TIMESTAMP_SCC}.json"
GCS_PATH="gs://${BUCKET_NAME}/${FILE_NAME}"

echo "Initiating Organization-wide SCC findings export for Org: ${ORG_ID} to ${GCS_PATH} using SCC V2 API..."

# List findings in JSON format and stream to GCS
# Added --location=global to force usage of SCC V2 API.
gcloud scc findings list "organizations/${ORG_ID}"
  --location="global"
  --billing-project="${BILLING_PROJECT}"
  --format="json" > "/tmp/${FILE_NAME}"

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to list SCC findings. Ensure you have the required permissions and that the SCC V2 API is available."
  rm -f "/tmp/${FILE_NAME}"
  exit 1
fi

gcloud storage cp "/tmp/${FILE_NAME}" "${GCS_PATH}"

if [[ $? -eq 0 ]]; then
  echo "SCC Export complete: ${GCS_PATH}"
else
  echo "Error: Failed to upload to Cloud Storage."
  rm -f "/tmp/${FILE_NAME}"
  exit 1
fi

rm "/tmp/${FILE_NAME}"
