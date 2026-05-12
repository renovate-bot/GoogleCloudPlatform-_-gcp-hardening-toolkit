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

variable "project_id" {
  description = "The GCP Project ID where the agent infrastructure (SA, BQ) will reside."
  type        = string
}

variable "region" {
  description = "The region for resources."
  type        = string
  default     = "us-central1"
}

variable "agent_sa_name" {
  description = "The name of the Service Account for the Hardening Agent."
  type        = string
  default     = "hardening-agent-sa"
}

variable "create_dataset" {
  description = "Whether to create the BigQuery dataset for the agent."
  type        = bool
  default     = true
}

variable "dataset_id" {
  description = "The ID of the BigQuery dataset for the agent."
  type        = string
  default     = "hardening_agent_telemetry"
}

variable "admin_email" {
  description = "The email of the user who will be running the agent (to allow Service Account impersonation)."
  type        = string
}

variable "agent_state_bucket_name" {
  description = "The name of the GCS bucket for the agent's state."
  type        = string
  default     = ""
}
