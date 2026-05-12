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

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.45.2"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  dataset_id              = var.dataset_id != "" ? var.dataset_id : "ght_agent_bq_${var.project_id}"
  agent_state_bucket_name = var.agent_state_bucket_name != "" ? var.agent_state_bucket_name : "ght-agent-cs-${var.project_id}"
}

resource "google_storage_bucket" "agent_state" {
  name                        = local.agent_state_bucket_name
  location                    = "US"
  force_destroy               = false
  uniform_bucket_level_access = true
}

resource "google_bigquery_dataset" "agent_telemetry" {
  count       = var.create_dataset ? 1 : 0
  dataset_id  = local.dataset_id
  description = "Central hub for security telemetry, logs, and asset inventory for the GCP Hardening Agent."
  location    = "US" # Standard for analytics
}
