#!/usr/bin/env bash
# Script Name: export_project_state.sh
# Purpose: Zero-touch CAI and SCC state export with deterministic execution validation.

PROJECT_ID=${1:-}
DATASET_NAME=${2:-}
BUCKET_NAME=${3:-}

if [[ -z "$PROJECT_ID" ]] || [[ -z "$DATASET_NAME" ]] || [[ -z "$BUCKET_NAME" ]]; then
  echo "Execution aborted: Project ID, Dataset Name, and Bucket Name are required."
  echo "Usage: $0 <PROJECT_ID> <DATASET_NAME> <BUCKET_NAME>"
  exit 1
fi

# --- CAI Export ---

echo "Ensuring Cloud Asset API is enabled for ${PROJECT_ID}..."
gcloud services enable cloudasset.googleapis.com --project="${PROJECT_ID}" --quiet

echo "Ensuring standardized BigQuery dataset '${DATASET_NAME}' exists..."
bq mk --force --dataset "${PROJECT_ID}:${DATASET_NAME}" 2>/dev/null || true

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TABLE_NAME="cai_state_${TIMESTAMP}"
FULLY_QUALIFIED_TABLE="projects/${PROJECT_ID}/datasets/${DATASET_NAME}/tables/${TABLE_NAME}"

IAM_TABLE_NAME="iam_policy_${TIMESTAMP}"
FULLY_QUALIFIED_IAM_TABLE="projects/${PROJECT_ID}/datasets/${DATASET_NAME}/tables/${IAM_TABLE_NAME}"

echo "Initiating CAI batch export to BigQuery table: ${DATASET_NAME}.${TABLE_NAME}..."

# Execute the resource export and capture the asynchronous output
EXPORT_OUT=$(gcloud asset export
  --project="${PROJECT_ID}"
  --asset-types="compute.googleapis.com/Instance,compute.googleapis.com/Firewall,iam.googleapis.com/ServiceAccount"
  --content-type=resource
  --bigquery-table="${FULLY_QUALIFIED_TABLE}"
  --output-bigquery-force 2>&1)

# Echo the output so you have visibility
echo "$EXPORT_OUT"

# Extract the operation path using Regex
OP_PATH=$(echo "$EXPORT_OUT" | grep -oE "projects/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

echo "Initiating IAM policy export to BigQuery table: ${DATASET_NAME}.${IAM_TABLE_NAME}..."

# Execute the IAM export and capture the asynchronous output
EXPORT_IAM_OUT=$(gcloud asset export
  --project="${PROJECT_ID}"
  --content-type=iam-policy
  --bigquery-table="${FULLY_QUALIFIED_IAM_TABLE}"
  --output-bigquery-force 2>&1)

# Echo the output so you have visibility
echo "$EXPORT_IAM_OUT"

# Extract the operation path using Regex
OP_PATH_IAM=$(echo "$EXPORT_IAM_OUT" | grep -oE "projects/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

if [[ -z "$OP_PATH" ]] || [[ -z "$OP_PATH_IAM" ]]; then
  echo "Execution aborted: Failed to extract operation path for one or both exports. Review the logs above."
  exit 1
fi

echo "CAI Exports triggered."
echo "To check resource export status: gcloud asset operations describe "${OP_PATH}""
echo "To check IAM policy export status: gcloud asset operations describe "${OP_PATH_IAM}""
echo "Once operations are complete, tables ${DATASET_NAME}.${TABLE_NAME} and ${DATASET_NAME}.${IAM_TABLE_NAME} will be populated."

# --- SCC Export ---

echo "Ensuring Security Command Center API is enabled for ${PROJECT_ID}..."
gcloud services enable securitycenter.googleapis.com --project="${PROJECT_ID}" --quiet

echo "Ensuring Cloud Storage bucket '${BUCKET_NAME}' exists..."
gcloud storage buckets create "gs://${BUCKET_NAME}" --project="${PROJECT_ID}" 2>/dev/null || true

TIMESTAMP_SCC=$(date +%Y%m%d_%H%M%S)
FILE_NAME="scc_findings_${PROJECT_ID}_${TIMESTAMP_SCC}.json"
GCS_PATH="gs://${BUCKET_NAME}/${FILE_NAME}"

echo "Exporting SCC findings for project ${PROJECT_ID} to ${GCS_PATH} using SCC V2 API..."

# List findings in JSON format and stream to GCS
# Correct syntax: gcloud scc findings list "projects/${PROJECT_ID}"
# Added --location=global to force usage of SCC V2 API, as V1 is being deprecated.
gcloud scc findings list "projects/${PROJECT_ID}"
  --location="global"
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
