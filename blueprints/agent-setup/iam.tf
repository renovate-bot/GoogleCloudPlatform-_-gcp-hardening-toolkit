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

# Service Account for the Hardening Agent
resource "google_service_account" "agent_sa" {
  account_id   = var.agent_sa_name
  display_name = "GCP Hardening Agent Service Account"
  project      = var.project_id
}

# Bind the scoped Roles to the Service Account
resource "google_bigquery_dataset_iam_binding" "agent_bigquery_viewer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.agent_telemetry.dataset_id
  role       = "roles/bigquery.dataViewer"
  members = [
    "serviceAccount:${google_service_account.agent_sa.email}"
  ]
}

resource "google_project_iam_binding" "agent_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  members = [
    "serviceAccount:${google_service_account.agent_sa.email}"
  ]
}

resource "google_storage_bucket_iam_member" "agent_storage_object_viewer" {
  bucket = google_storage_bucket.agent_state.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.agent_sa.email}"
}

# Required for the agent to use MCP tools (BigQuery, Storage)
resource "google_project_iam_binding" "mcp_tool_user" {
  project = var.project_id
  role    = "roles/mcp.toolUser"
  members = [
    "serviceAccount:${google_service_account.agent_sa.email}"
  ]
}

# Optional: Add Service Usage Consumer if needed to use APIs
resource "google_project_iam_binding" "service_usage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  members = [
    "serviceAccount:${google_service_account.agent_sa.email}"
  ]
}

# Allow the user to impersonate the Service Account (avoids the need for JSON keys)
resource "google_service_account_iam_binding" "admin_impersonation" {
  service_account_id = google_service_account.agent_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "user:${var.admin_email}"
  ]
}
