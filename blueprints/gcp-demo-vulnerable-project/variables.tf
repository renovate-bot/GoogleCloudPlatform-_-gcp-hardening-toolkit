variable "project_id" {
  type        = string
  description = "The GCP project ID to deploy the vulnerable resources into."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region to deploy resources."
}
