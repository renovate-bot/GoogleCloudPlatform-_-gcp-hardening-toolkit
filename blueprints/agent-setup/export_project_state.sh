#!/usr/bin/env bash
# Script Name: export_project_state.sh
# Purpose: Zero-touch CAI and SCC state export with deterministic execution validation.

AGENT_PROJECT_ID=${1:-}
DATASET_NAME=${2:-}
BUCKET_NAME=${3:-}
TARGET_PROJECT_ID=${4:-}

if [[ -z "$AGENT_PROJECT_ID" ]] || [[ -z "$DATASET_NAME" ]] || [[ -z "$BUCKET_NAME" ]] || [[ -z "$TARGET_PROJECT_ID" ]]; then
  echo "Execution aborted: Agent Project ID, Dataset Name, Bucket Name, and Target Project ID are required."
  echo "Usage: $0 <AGENT_PROJECT_ID> <DATASET_NAME> <BUCKET_NAME> <TARGET_PROJECT_ID>"
  exit 1
fi

# --- CAI Export ---

echo "Ensuring Cloud Asset API is enabled for ${TARGET_PROJECT_ID}..."
gcloud services enable cloudasset.googleapis.com --project="${TARGET_PROJECT_ID}" --quiet

echo "Ensuring BigQuery dataset '${DATASET_NAME}' exists in ${AGENT_PROJECT_ID}..."
bq mk --force --dataset "${AGENT_PROJECT_ID}:${DATASET_NAME}" 2>/dev/null || true

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# Sanitize Target Project ID for BigQuery table naming (replace hyphens with underscores)
SANITIZED_TARGET_ID=$(echo "${TARGET_PROJECT_ID}" | tr '-' '_')

TABLE_NAME="cai_state_${SANITIZED_TARGET_ID}_${TIMESTAMP}"
FULLY_QUALIFIED_TABLE="projects/${AGENT_PROJECT_ID}/datasets/${DATASET_NAME}/tables/${TABLE_NAME}"

IAM_TABLE_NAME="iam_policy_${SANITIZED_TARGET_ID}_${TIMESTAMP}"
FULLY_QUALIFIED_IAM_TABLE="projects/${AGENT_PROJECT_ID}/datasets/${DATASET_NAME}/tables/${IAM_TABLE_NAME}"

echo "Initiating CAI batch export to BigQuery table: ${AGENT_PROJECT_ID}.${DATASET_NAME}.${TABLE_NAME}..."

EXPORT_OUT=$(gcloud asset export \
  --project="${TARGET_PROJECT_ID}" \
  --billing-project="${AGENT_PROJECT_ID}" \
  --asset-types="compute.googleapis.com/Instance,compute.googleapis.com/Firewall,iam.googleapis.com/ServiceAccount" \
  --content-type=resource \
  --bigquery-table="${FULLY_QUALIFIED_TABLE}" \
  --output-bigquery-force 2>&1)

# Echo the output so you have visibility
echo "$EXPORT_OUT"

# Extract the operation path using Regex
OP_PATH=$(echo "$EXPORT_OUT" | grep -oE "projects/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

echo "Initiating IAM policy export to BigQuery table: ${AGENT_PROJECT_ID}.${DATASET_NAME}.${IAM_TABLE_NAME}..."

EXPORT_IAM_OUT=$(gcloud asset export \
  --project="${TARGET_PROJECT_ID}" \
  --billing-project="${AGENT_PROJECT_ID}" \
  --content-type=iam-policy \
  --bigquery-table="${FULLY_QUALIFIED_IAM_TABLE}" \
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
echo "To check resource export status: gcloud asset operations describe \"${OP_PATH}\" --project=\"${TARGET_PROJECT_ID}\""
echo "To check IAM policy export status: gcloud asset operations describe \"${OP_PATH_IAM}\" --project=\"${TARGET_PROJECT_ID}\""
echo "Once operations are complete, tables ${AGENT_PROJECT_ID}.${DATASET_NAME}.${TABLE_NAME} and ${AGENT_PROJECT_ID}.${DATASET_NAME}.${IAM_TABLE_NAME} will be populated."

# --- SCC Export ---

echo "Ensuring Security Command Center API is enabled for ${TARGET_PROJECT_ID}..."
gcloud services enable securitycenter.googleapis.com --project="${TARGET_PROJECT_ID}" --quiet

echo "Ensuring Cloud Storage bucket '${BUCKET_NAME}' exists in ${AGENT_PROJECT_ID}..."
gcloud storage buckets create "gs://${BUCKET_NAME}" --project="${AGENT_PROJECT_ID}" 2>/dev/null || true

TIMESTAMP_SCC=$(date +%Y%m%d_%H%M%S)
FILE_NAME="scc_findings_${TARGET_PROJECT_ID}_${TIMESTAMP_SCC}.json"
GCS_PATH="gs://${BUCKET_NAME}/${FILE_NAME}"

echo "Exporting SCC findings for project ${TARGET_PROJECT_ID} to ${GCS_PATH} using SCC V2 API..."

gcloud scc findings list "projects/${TARGET_PROJECT_ID}" \
  --location="global" \
  --billing-project="${AGENT_PROJECT_ID}" \
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

rm -f "/tmp/${FILE_NAME}"
