#!/usr/bin/env bash
# Script Name: export_project_state.sh
# Purpose: Exports both CAI and SCC state for a project.

PROJECT_ID=${1:-}
BUCKET_NAME=${2:-"hardening-agent-scc-state-${PROJECT_ID}"}

if [[ -z "$PROJECT_ID" ]]; then
  echo "Execution aborted: Project ID is required."
  echo "Usage: $0 <PROJECT_ID> [BUCKET_NAME]"
  exit 1
fi

echo "--- Enabling required APIs for project ${PROJECT_ID} ---"
gcloud services enable cloudasset.googleapis.com --project="${PROJECT_ID}" --quiet
gcloud services enable securitycenter.googleapis.com --project="${PROJECT_ID}" --quiet
echo "APIs enabled."

echo ""
echo "--- Exporting Cloud Asset Inventory (CAI) state ---"
CAI_DATASET_NAME="hardening_agent_cai_state"
echo "Ensuring standardized BigQuery dataset '${CAI_DATASET_NAME}' exists..."
bq mk --force --dataset "${PROJECT_ID}:${CAI_DATASET_NAME}" 2>/dev/null || true

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CAI_TABLE_NAME="cai_state_${TIMESTAMP}"
FULLY_QUALIFIED_CAI_TABLE="projects/${PROJECT_ID}/datasets/${CAI_DATASET_NAME}/tables/${CAI_TABLE_NAME}"

IAM_TABLE_NAME="iam_policy_${TIMESTAMP}"
FULLY_QUALIFIED_IAM_TABLE="projects/${PROJECT_ID}/datasets/${CAI_DATASET_NAME}/tables/${IAM_TABLE_NAME}"

echo "Initiating CAI batch export to BigQuery table: ${CAI_DATASET_NAME}.${CAI_TABLE_NAME}..."
EXPORT_OUT=$(gcloud asset export
  --project="${PROJECT_ID}"
  --asset-types="compute.googleapis.com/Instance,compute.googleapis.com/Firewall,iam.googleapis.com/ServiceAccount"
  --content-type=resource
  --bigquery-table="${FULLY_QUALIFIED_CAI_TABLE}"
  --output-bigquery-force 2>&1)
echo "$EXPORT_OUT"
OP_PATH=$(echo "$EXPORT_OUT" | grep -oE "projects/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

echo "Initiating IAM policy export to BigQuery table: ${CAI_DATASET_NAME}.${IAM_TABLE_NAME}..."
EXPORT_IAM_OUT=$(gcloud asset export
  --project="${PROJECT_ID}"
  --content-type=iam-policy
  --bigquery-table="${FULLY_QUALIFIED_IAM_TABLE}"
  --output-bigquery-force 2>&1)
echo "$EXPORT_IAM_OUT"
OP_PATH_IAM=$(echo "$EXPORT_IAM_OUT" | grep -oE "projects/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

if [[ -z "$OP_PATH" ]] || [[ -z "$OP_PATH_IAM" ]]; then
  echo "Execution aborted: Failed to extract operation path for one or both CAI exports."
fi
echo "CAI exports triggered."

echo ""
echo "--- Exporting Security Command Center (SCC) findings ---"
echo "Ensuring Cloud Storage bucket '${BUCKET_NAME}' exists..."
gcloud storage buckets create "gs://${BUCKET_NAME}" --project="${PROJECT_ID}" 2>/dev/null || true

SCC_FILE_NAME="scc_findings_${PROJECT_ID}_${TIMESTAMP}.json"
GCS_PATH="gs://${BUCKET_NAME}/${SCC_FILE_NAME}"

echo "Exporting SCC findings for project ${PROJECT_ID} to ${GCS_PATH}..."
gcloud scc findings list "projects/${PROJECT_ID}"
  --location="global"
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
echo "To check CAI resource export status: gcloud asset operations describe "${OP_PATH}""
echo "To check CAI IAM policy export status: gcloud asset operations describe "${OP_PATH_IAM}""
echo "SCC findings exported to ${GCS_PATH}"
