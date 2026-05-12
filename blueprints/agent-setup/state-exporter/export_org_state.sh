#!/bin/bash
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <org_id> <bucket_name> <dataset_id>"
    exit 1
fi

ORG_ID=$1
BUCKET_NAME=$2
DATASET_ID=$3
CAI_TABLE_ID="cai_org_resource_inventory"
SCC_TABLE_ID="scc_org_findings"
PROJECT_ID=$(gcloud config get-value project)

echo "Exporting resource inventory for organization ${ORG_ID} to gs://${BUCKET_NAME}/org_resource_inventory.json..."

gcloud asset export
  --content-type resource
  --organization "${ORG_ID}"
  --output-path "gs://${BUCKET_NAME}/org_resource_inventory.json"

echo "Export complete."

echo "Loading resource inventory from gs://${BUCKET_NAME}/org_resource_inventory.json into BigQuery table ${PROJECT_ID}:${DATASET_ID}.${CAI_TABLE_ID}..."

bq load
  --source_format=NEWLINE_DELIMITED_JSON
  "${PROJECT_ID}:${DATASET_ID}.${CAI_TABLE_ID}"
  "gs://${BUCKET_NAME}/org_resource_inventory.json"

echo "CAI BigQuery load complete."

echo "Exporting SCC findings for organization ${ORG_ID} to BigQuery table ${PROJECT_ID}:${DATASET_ID}.${SCC_TABLE_ID}..."

bq query
  --project_id="${PROJECT_ID}"
  --use_legacy_sql=false
  "
  CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.${SCC_TABLE_ID}` AS
  SELECT * FROM `organizations/${ORG_ID}/sources/-/findings`
  "

echo "SCC BigQuery export complete."
