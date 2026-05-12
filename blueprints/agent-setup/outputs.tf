/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "agent_sa_email" {
  description = "The email of the Hardening Agent Service Account."
  value       = google_service_account.agent_sa.email
}

output "dataset_id" {
  description = "The ID of the BigQuery dataset created for the agent telemetry."
  value       = var.create_dataset ? google_bigquery_dataset.agent_telemetry[0].dataset_id : null
}

output "agent_state_bucket_name" {
  description = "The name of the GCS bucket for the agent's state."
  value       = google_storage_bucket.agent_state.name
}

output "setup_instructions" {
  description = "Next steps for setting up the agent."
  value       = <<EOF
1. Export your environment state using the appropriate script:

   For a single project:
   cd blueprints/agent-setup/state-exporter
   ./export_project_state.sh ${var.project_id} ${google_storage_bucket.agent_state.name} ${google_bigquery_dataset.agent_telemetry[0].dataset_id}

   For an entire organization (replace YOUR_ORG_ID):
   cd blueprints/agent-setup/state-exporter
   ./export_org_state.sh YOUR_ORG_ID ${google_storage_bucket.agent_state.name} ${google_bigquery_dataset.agent_telemetry[0].dataset_id}

2. Run the agent using Service Account Impersonation (No keys needed!):
   gcloud auth application-default login --impersonate-service-account=${google_service_account.agent_sa.email}
   export GOOGLE_CLOUD_PROJECT="${var.project_id}"
   gemini
EOF
}
